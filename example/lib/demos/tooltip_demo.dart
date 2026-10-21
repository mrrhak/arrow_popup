// Tooltip: the simplest use of the package.
//
// Wrap any widget in `ArrowPopup` and give it `content`. Tapping the widget
// opens a bubble that points at it. Here a storage card has three: the info
// icon, each segment of the usage bar, and the warning chip.

import 'package:arrow_popup/arrow_popup.dart';
import 'package:material_ui/material_ui.dart';

typedef _Usage = ({String name, IconData icon, double gb, Color color});

/// A storage card with tooltips on the info icon, each bar segment and the
/// warning.
class TooltipDemo extends StatelessWidget {
  const TooltipDemo({super.key});

  static const _total = 15.0;
  static const List<_Usage> _usage = [
    (
      name: 'Photos',
      icon: Icons.photo_outlined,
      gb: 6.1,
      color: Color(0xFF6366F1),
    ),
    (
      name: 'Videos',
      icon: Icons.videocam_outlined,
      gb: 4.3,
      color: Color(0xFFEC4899),
    ),
    (
      name: 'Documents',
      icon: Icons.description_outlined,
      gb: 2.2,
      color: Color(0xFFF59E0B),
    ),
    (
      name: 'Other',
      icon: Icons.folder_outlined,
      gb: 1.6,
      color: Color(0xFF14B8A6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final used = _usage.fold(0.0, (sum, usage) => sum + usage.gb);
    final free = (
      name: 'Free',
      icon: Icons.cloud_queue_rounded,
      gb: _total - used,
      color: colorScheme.surfaceContainerHighest,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.cloud_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cloud storage', style: textTheme.titleSmall),
                    Text(
                      '${used.toStringAsFixed(1)} GB of '
                      '${_total.toStringAsFixed(0)} GB used',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ArrowPopup(
                // Raised above the card, so it stands out in both themes.
                style: ArrowPopupStyle(
                  color: colorScheme.surfaceContainerHighest,
                  maxWidth: 240,
                  padding: const EdgeInsets.all(12),
                  shadows: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                content: Text(
                  'You have used ${used.toStringAsFixed(1)} GB of '
                  '${_total.toStringAsFixed(0)} GB. Delete files or upgrade '
                  'your plan to keep syncing.',
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.info_outline,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Each segment is its own small anchor.
          Row(
            children: [
              for (final usage in [..._usage, free])
                Expanded(
                  flex: (usage.gb * 10).round(),
                  child: _UsageSegment(usage: usage, total: _total),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final usage in _usage)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: usage.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(usage.name, style: textTheme.labelSmall),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ArrowPopup(
                // Stronger than the chip, so the two don't merge.
                style: ArrowPopupStyle(
                  color: colorScheme.error,
                  maxWidth: 220,
                  padding: const EdgeInsets.all(10),
                ),
                content: Text(
                  'Sync pauses when storage is full. New photos will stay '
                  'on this device only.',
                  style: TextStyle(color: colorScheme.onError),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Almost full',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Tap the bar',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageSegment extends StatelessWidget {
  const _UsageSegment({required this.usage, required this.total});

  final _Usage usage;
  final double total;

  @override
  Widget build(BuildContext context) {
    // Dark text on light segments, light text on dark ones.
    final onColor =
        ThemeData.estimateBrightnessForColor(usage.color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final percent = (usage.gb / total * 100).round();
    return ArrowPopup(
      key: ValueKey(usage.name),
      placement: ArrowPopupPlacement.above,
      barrierColor: Colors.transparent,
      style: ArrowPopupStyle(
        color: usage.color,
        borderRadius: 10,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        arrowSize: const Size(12, 6),
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(usage.icon, size: 18, color: onColor),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usage.name,
                style: TextStyle(color: onColor, fontWeight: FontWeight.w600),
              ),
              Text(
                '${usage.gb.toStringAsFixed(1)} GB · $percent%',
                style: TextStyle(
                  color: onColor.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      // Taller than it looks, so the thin bar is easy to tap.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
        child: Container(
          height: 12,
          decoration: BoxDecoration(
            color: usage.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
