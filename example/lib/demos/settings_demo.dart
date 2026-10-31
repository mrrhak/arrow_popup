// Settings: `ArrowPopup<T>` closes with a value, and the theme styles it.
//
// Each row opens a small picker. An option pops itself, so `onClose`
// receives it, or null when the picker is dismissed. None of the pickers
// pass a `style`: the `Theme` around the card holds an `ArrowPopupStyle`,
// with an outline `border`, and every popup inside uses it.

import 'package:arrow_popup/arrow_popup.dart';
import 'package:material_ui/material_ui.dart';

typedef _Setting = ({String title, IconData icon, List<String> options});

/// A settings card whose rows each pick one option.
class SettingsDemo extends StatefulWidget {
  const SettingsDemo({super.key});

  @override
  State<SettingsDemo> createState() => _SettingsDemoState();
}

class _SettingsDemoState extends State<SettingsDemo> {
  static const List<_Setting> _settings = [
    (
      title: 'Notifications',
      icon: Icons.notifications_none_rounded,
      options: ['All', 'Mentions', 'Off'],
    ),
    (
      title: 'Auto-download',
      icon: Icons.download_rounded,
      options: ['Wi-Fi only', 'Always', 'Never'],
    ),
    (
      title: 'Text size',
      icon: Icons.text_fields_rounded,
      options: ['Small', 'Default', 'Large'],
    ),
  ];

  final _values = {
    for (final setting in _settings) setting.title: setting.options.first,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Every ArrowPopup below without a style of its own uses this one.
    return Theme(
      data: theme.copyWith(
        extensions: [
          ArrowPopupStyle(
            color: colorScheme.surfaceContainerHighest,
            border: BorderSide(color: colorScheme.outlineVariant),
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(vertical: 4),
            clipBehavior: Clip.antiAlias,
            shadows: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ],
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            for (final (i, setting) in _settings.indexed) ...[
              if (i > 0) Divider(height: 1, color: colorScheme.outlineVariant),
              ListTile(
                leading: Icon(setting.icon),
                title: Text(setting.title),
                trailing: ArrowPopup<String>(
                  key: ValueKey('setting-${setting.title}'),
                  semanticLabel: '${setting.title} options',
                  onClose: (value) {
                    if (value != null) {
                      setState(() => _values[setting.title] = value);
                    }
                  },
                  content: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final option in setting.options)
                          _Option(
                            label: option,
                            selected: option == _values[setting.title],
                          ),
                      ],
                    ),
                  ),
                  // A plain chip, so ArrowPopup gets the tap.
                  child: _ValueChip(value: _values[setting.title]!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The current value, with a hint that it opens a picker.
class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: colorScheme.onSecondaryContainer),
          ),
          Icon(
            Icons.arrow_drop_down_rounded,
            color: colorScheme.onSecondaryContainer,
          ),
        ],
      ),
    );
  }
}

/// One option in a picker. Tapping it closes the picker with [label].
class _Option extends StatelessWidget {
  const _Option({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // This context is inside the popup, so close closes it and hands the
    // value to onClose.
    return InkWell(
      onTap: () => ArrowPopup.close(context, label),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.check_rounded,
              size: 18,
              color: selected ? colorScheme.primary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
