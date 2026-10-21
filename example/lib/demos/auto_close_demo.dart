// Auto close: `autoCloseDuration` closes a popup by itself.
//
// Copying a profile link shows "Link copied", which goes away after the
// chosen time, as if dismissed. The default, `Duration.zero`, never closes
// it by itself, so "Never" waits for a tap outside. The copy button handles
// taps itself, so `ArrowPopup.builder` gives it `show` to open the popup.

import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// A profile link with a copy button that confirms with a brief popup.
class AutoCloseDemo extends StatefulWidget {
  const AutoCloseDemo({super.key});

  @override
  State<AutoCloseDemo> createState() => _AutoCloseDemoState();
}

class _AutoCloseDemoState extends State<AutoCloseDemo> {
  static const _link = 'github.com/mrrhak';
  static const _durations = {
    '1s': Duration(seconds: 1),
    '3s': Duration(seconds: 3),
    'Never': Duration.zero,
  };

  Duration _duration = _durations['1s']!;

  Future<void> _copy(Future<void> Function() show) async {
    await Clipboard.setData(const ClipboardData(text: 'https://$_link'));
    if (mounted) await show();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile link', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _link,
                    style: textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ArrowPopup.builder(
                  placement: ArrowPopupPlacement.above,
                  barrierColor: Colors.transparent,
                  autoCloseDuration: _duration,
                  style: ArrowPopupStyle(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: 999,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shadows: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text('Link copied', style: textTheme.labelLarge),
                    ],
                  ),
                  builder: (context, show) => IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () => _copy(show),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Close after',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SegmentedButton<Duration>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: [
                  for (final MapEntry(key: label, value: duration)
                      in _durations.entries)
                    ButtonSegment(value: duration, label: Text(label)),
                ],
                selected: {_duration},
                onSelectionChanged: (selected) =>
                    setState(() => _duration = selected.single),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
