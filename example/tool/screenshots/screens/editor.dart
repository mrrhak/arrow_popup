import 'package:material_ui/material_ui.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key, required this.boldKey});

  final GlobalKey boldKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    Widget tool(IconData icon) => IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 20),
      onPressed: () {},
    );
    final body = text.bodyMedium!.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.6,
    );
    Widget check(String label, {bool done = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done ? scheme.primary : scheme.outline,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: body.copyWith(
              decoration: done ? TextDecoration.lineThrough : null,
              decorationColor: scheme.outline,
              color: done ? scheme.outline : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A floating toolbar pill.
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  key: boldKey,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.format_bold, size: 20),
                  onPressed: () {},
                ),
                tool(Icons.format_italic),
                tool(Icons.format_underlined),
                tool(Icons.link),
                tool(Icons.format_list_bulleted),
                tool(Icons.more_horiz),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 62, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Draft  ·  This week',
                  style: text.labelSmall!.copyWith(color: scheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Weekly plan',
                style: text.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              check('Finish the onboarding flow', done: true),
              check('Review the new settings screen'),
              check('Ship the beta on Friday'),
            ],
          ),
        ),
      ],
    );
  }
}

class Shortcut extends StatelessWidget {
  const Shortcut({super.key, required this.label, required this.keys});

  final String label;
  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 10),
        for (final key in keys) ...[
          if (key != keys.first) const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outline),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              key,
              style: text.labelSmall!.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}
