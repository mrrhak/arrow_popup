import 'package:material_ui/material_ui.dart';

import '../frame.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key, required this.addKey});

  final GlobalKey addKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const tasks = [
      ('Review pull requests', true),
      ('Plan the beta launch', false),
      ('Call the design team', false),
    ];
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Header('Today'),
            for (final (task, done) in tasks)
              CheckboxListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                controlAffinity: ListTileControlAffinity.leading,
                value: done,
                onChanged: (_) {},
                title: Text(
                  task,
                  style: TextStyle(
                    fontSize: 15,
                    color: done ? scheme.onSurfaceVariant : scheme.onSurface,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            key: addKey,
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class TourStep extends StatelessWidget {
  const TourStep({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 224,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick add',
            style: text.titleSmall!.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a task from any screen.',
            style: text.bodyMedium!.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '2 of 3',
                style: text.labelMedium!.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onPrimary,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {},
                child: const Text('Back'),
              ),
              const SizedBox(width: 4),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.onPrimary,
                  foregroundColor: scheme.primary,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {},
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
