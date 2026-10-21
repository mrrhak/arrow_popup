import 'package:material_ui/material_ui.dart';

class TripScreen extends StatelessWidget {
  const TripScreen({super.key, required this.countryKey});

  final GlobalKey countryKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    Widget field(
      String label,
      String value,
      IconData icon, {
      Key? key,
      bool open = false,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: text.labelMedium!.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Container(
            key: key,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: open ? scheme.primary : scheme.outlineVariant,
                width: open ? 1.5 : 1,
              ),
              boxShadow: open
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.3),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(child: Text(value, style: text.bodyLarge)),
                if (key != null)
                  Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New trip',
            style: text.titleLarge!.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          field(
            'Country',
            'Cambodia',
            Icons.public,
            key: countryKey,
            open: true,
          ),
          const SizedBox(height: 14),
          field('Trip name', 'Weekend away', Icons.luggage),
          const SizedBox(height: 14),
          field('Dates', '10 – 12 Oct', Icons.calendar_today),
        ],
      ),
    );
  }
}

class CountryList extends StatelessWidget {
  const CountryList({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search countries',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: scheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 6),
        for (final (country, city) in [
          ('Cambodia', 'Phnom Penh'),
          ('Japan', 'Tokyo'),
          ('Thailand', 'Bangkok'),
          ('Vietnam', 'Hanoi'),
        ])
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: country == 'Cambodia' ? scheme.secondaryContainer : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(child: Text(country)),
                Text(
                  city,
                  style: Theme.of(context).textTheme.labelMedium!
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
                if (country == 'Cambodia') ...[
                  const SizedBox(width: 10),
                  Icon(Icons.check, size: 18, color: scheme.primary),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
