import 'package:flutter/material.dart';

import '../frame.dart';

class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key, required this.moreKey});

  final GlobalKey moreKey;

  static const _files = [
    (
      name: 'Holiday.jpg',
      info: '4.2 MB · Yesterday',
      icon: Icons.image_outlined,
      color: Color(0xFF6366F1),
    ),
    (
      name: 'Budget 2026.xlsx',
      info: '0.3 MB · 3 days ago',
      icon: Icons.table_chart_outlined,
      color: Color(0xFF16A34A),
    ),
    (
      name: 'Pitch deck.pdf',
      info: '12.8 MB · Last week',
      icon: Icons.picture_as_pdf_outlined,
      color: Color(0xFFDC2626),
    ),
    (
      name: 'Interview.m4a',
      info: '26.1 MB · Last month',
      icon: Icons.graphic_eq_rounded,
      color: Color(0xFFF59E0B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Header('Files', icon: Icons.sort_rounded),
        for (final (i, file) in _files.indexed)
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: file.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(file.icon, color: file.color, size: 22),
            ),
            title: Text(file.name),
            subtitle: Text(file.info),
            trailing: IconButton(
              key: i == 0 ? moreKey : null,
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ),
      ],
    );
  }
}

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(IconData icon, String label, [Color? color]) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 40, 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color ?? scheme.onSurface)),
          ],
        ),
      );
    }

    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          item(Icons.edit_outlined, 'Rename'),
          item(Icons.share_outlined, 'Share'),
          item(Icons.content_copy_outlined, 'Duplicate'),
          const Divider(height: 9),
          item(Icons.delete_outline, 'Delete', scheme.error),
        ],
      ),
    );
  }
}
