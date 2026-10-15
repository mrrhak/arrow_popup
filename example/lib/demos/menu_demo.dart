// Menu: `ArrowPopup.show<T>` opens a popup from code and returns a value.
//
// Pass the context of the widget the arrow should point at. Whatever
// the content passes to `ArrowPopup.close` comes back from the call, or null
// when the popup is dismissed. Here a file list has a sort menu and a menu
// on each file.

import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter/material.dart';

typedef _File = ({
  String name,
  IconData icon,
  Color color,
  double mb,
  int daysAgo,
});

enum _FileAction { rename, share, duplicate, delete }

/// A file list with a sort menu and a menu on each file.
class MenuDemo extends StatefulWidget {
  const MenuDemo({super.key});

  @override
  State<MenuDemo> createState() => _MenuDemoState();
}

class _MenuDemoState extends State<MenuDemo> {
  static const _orders = {
    'Newest': Icons.schedule_rounded,
    'Oldest': Icons.history_rounded,
    'Name': Icons.sort_by_alpha_rounded,
    'Size': Icons.data_usage_rounded,
  };

  static const List<_File> _initialFiles = [
    (
      name: 'Holiday.jpg',
      icon: Icons.image_outlined,
      color: Color(0xFF6366F1),
      mb: 4.2,
      daysAgo: 1,
    ),
    (
      name: 'Budget 2026.xlsx',
      icon: Icons.table_chart_outlined,
      color: Color(0xFF16A34A),
      mb: 0.3,
      daysAgo: 3,
    ),
    (
      name: 'Pitch deck.pdf',
      icon: Icons.picture_as_pdf_outlined,
      color: Color(0xFFDC2626),
      mb: 12.8,
      daysAgo: 7,
    ),
    (
      name: 'Interview.m4a',
      icon: Icons.graphic_eq_rounded,
      color: Color(0xFFF59E0B),
      mb: 26.1,
      daysAgo: 14,
    ),
  ];

  final _files = [..._initialFiles];
  String _order = _orders.keys.first;

  List<_File> get _sorted => [..._files]
    ..sort(
      (a, b) => switch (_order) {
        'Oldest' => b.daysAgo.compareTo(a.daysAgo),
        'Name' => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        'Size' => b.mb.compareTo(a.mb),
        _ => a.daysAgo.compareTo(b.daysAgo),
      },
    );

  ArrowPopupStyle _menuStyle(ColorScheme colorScheme) => ArrowPopupStyle(
    color: colorScheme.surfaceContainerHighest,
    borderRadius: 14,
    padding: const EdgeInsets.symmetric(vertical: 6),
    clipBehavior: Clip.antiAlias,
    shadows: [
      BoxShadow(
        color: colorScheme.shadow.withValues(alpha: 0.3),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Future<void> _pickOrder(BuildContext anchorContext) async {
    final colorScheme = Theme.of(context).colorScheme;
    final order = await ArrowPopup.show<String>(
      context: anchorContext,
      style: _menuStyle(colorScheme),
      content: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _MenuHeader('Sort by'),
            for (final MapEntry(key: order, value: icon) in _orders.entries)
              _MenuItem(
                value: order,
                icon: icon,
                label: order,
                checked: order == _order,
              ),
          ],
        ),
      ),
    );
    if (order != null && mounted) setState(() => _order = order);
  }

  Future<void> _openFileMenu(BuildContext anchorContext, _File file) async {
    final colorScheme = Theme.of(context).colorScheme;
    final action = await ArrowPopup.show<_FileAction>(
      context: anchorContext,
      style: _menuStyle(colorScheme),
      content: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MenuHeader(file.name),
            const _MenuItem(
              value: _FileAction.rename,
              icon: Icons.drive_file_rename_outline_rounded,
              label: 'Rename',
            ),
            const _MenuItem(
              value: _FileAction.share,
              icon: Icons.ios_share_rounded,
              label: 'Share',
            ),
            const _MenuItem(
              value: _FileAction.duplicate,
              icon: Icons.copy_rounded,
              label: 'Duplicate',
            ),
            const Divider(height: 9, indent: 12, endIndent: 12),
            const _MenuItem(
              value: _FileAction.delete,
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              destructive: true,
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    switch (action) {
      case _FileAction.rename:
      case _FileAction.share:
        messenger.showSnackBar(
          SnackBar(content: Text('${action.name.capitalized} ${file.name}')),
        );
      case _FileAction.duplicate:
        final dot = file.name.lastIndexOf('.');
        setState(() {
          _files.add((
            name:
                '${file.name.substring(0, dot)} copy'
                '${file.name.substring(dot)}',
            icon: file.icon,
            color: file.color,
            mb: file.mb,
            daysAgo: 0,
          ));
        });
      case _FileAction.delete:
        final index = _files.indexOf(file);
        setState(() => _files.removeAt(index));
        messenger.showSnackBar(
          SnackBar(
            content: Text('Deleted ${file.name}'),
            action: SnackBarAction(
              label: 'Undo',
              // The SnackBar belongs to the app, so it outlives this demo
              // once the list scrolls it away. A rebuilt demo starts with
              // every file again, so there is nothing to undo then.
              onPressed: () {
                if (mounted) setState(() => _files.insert(index, file));
              },
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final files = _sorted;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My files', style: textTheme.titleSmall),
                      Text(
                        'Sorted by $_order',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // The Builder's context is the button, so the arrow points
                // at it.
                Builder(
                  builder: (context) => FilledButton.tonalIcon(
                    onPressed: () => _pickOrder(context),
                    icon: Icon(_orders[_order]),
                    label: const Text('Sort'),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          if (files.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text('No files left', style: textTheme.bodyMedium),
                  ),
                  TextButton(
                    onPressed: () => setState(
                      () => _files
                        ..clear()
                        ..addAll(_initialFiles),
                    ),
                    child: const Text('Restore'),
                  ),
                ],
              ),
            ),
          for (final file in files)
            ListTile(
              contentPadding: const EdgeInsets.only(left: 16, right: 4),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: file.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(file.icon, color: file.color),
              ),
              title: Text(file.name, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${file.mb} MB · ${switch (file.daysAgo) {
                  0 => 'just now',
                  1 => 'yesterday',
                  final days => '$days days ago',
                }}',
              ),
              trailing: Builder(
                builder: (context) => IconButton(
                  tooltip: 'More',
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: () => _openFileMenu(context, file),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension on String {
  String get capitalized => '${this[0].toUpperCase()}${substring(1)}';
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _MenuItem<T> extends StatelessWidget {
  const _MenuItem({
    required this.value,
    required this.icon,
    required this.label,
    this.checked = false,
    this.destructive = false,
  });

  final T value;
  final IconData icon;
  final String label;
  final bool checked;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = destructive
        ? colorScheme.error
        : checked
        ? colorScheme.primary
        : colorScheme.onSurface;
    // This context is inside the popup, so close closes it and returns the
    // value.
    return InkWell(
      onTap: () => ArrowPopup.close(context, value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: checked ? FontWeight.w600 : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.check_rounded,
              size: 18,
              color: checked ? colorScheme.primary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
