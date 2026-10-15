// Dropdown: a popup without an arrow, as wide as the field it opens from.
//
// The bubble is centered on its anchor, so content as wide as the anchor
// lines up with it. The list scrolls inside whatever height the popup has,
// and the popup stays above the keyboard while searching.

import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter/material.dart';

typedef _Country = ({String flag, String name, String dial});

/// A country picker: a searchable, scrollable panel as wide as the field.
class DropdownDemo extends StatefulWidget {
  const DropdownDemo({super.key});

  @override
  State<DropdownDemo> createState() => _DropdownDemoState();
}

class _DropdownDemoState extends State<DropdownDemo> {
  static const List<_Country> _countries = [
    (flag: '🇰🇭', name: 'Cambodia', dial: '+855'),
    (flag: '🇻🇳', name: 'Vietnam', dial: '+84'),
    (flag: '🇸🇬', name: 'Singapore', dial: '+65'),
    (flag: '🇯🇵', name: 'Japan', dial: '+81'),
    (flag: '🇰🇷', name: 'South Korea', dial: '+82'),
    (flag: '🇮🇳', name: 'India', dial: '+91'),
    (flag: '🇦🇺', name: 'Australia', dial: '+61'),
    (flag: '🇫🇷', name: 'France', dial: '+33'),
    (flag: '🇩🇪', name: 'Germany', dial: '+49'),
    (flag: '🇬🇧', name: 'United Kingdom', dial: '+44'),
    (flag: '🇺🇸', name: 'United States', dial: '+1'),
    (flag: '🇨🇦', name: 'Canada', dial: '+1'),
    (flag: '🇧🇷', name: 'Brazil', dial: '+55'),
  ];

  final _controller = ArrowPopupController();
  _Country _country = _countries.first;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(_Country country) {
    setState(() => _country = country);
    _controller.hide();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Country / region',
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        // The bubble is centered on the field, so content as wide as the
        // field lines the panel up with it.
        LayoutBuilder(
          builder: (context, constraints) => ArrowPopup(
            controller: _controller,
            barrierColor: Colors.transparent,
            style: ArrowPopupStyle(
              color: colorScheme.surfaceContainerHighest,
              showArrow: false,
              borderRadius: 12,
              gap: 6,
              padding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              shadows: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            content: SizedBox(
              width: constraints.maxWidth,
              child: _CountryPicker(
                countries: _countries,
                selected: _country,
                onSelected: _select,
              ),
            ),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final open = _controller.isOpen;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: open ? colorScheme.primary : colorScheme.outline,
                      width: open ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(_country.flag, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _country.name,
                          style: textTheme.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _country.dial,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: open ? colorScheme.primary : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// The panel's content. It keeps its own search text while open.
class _CountryPicker extends StatefulWidget {
  const _CountryPicker({
    required this.countries,
    required this.selected,
    required this.onSelected,
  });

  final List<_Country> countries;
  final _Country selected;
  final ValueChanged<_Country> onSelected;

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final query = _query.trim().toLowerCase();
    final matches = [
      for (final country in widget.countries)
        if (country.name.toLowerCase().contains(query) ||
            country.dial.contains(query))
          country,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search country or code',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // The list scrolls inside whatever height the popup has room for.
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: matches.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No countries match "$_query"',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 6),
                    children: [
                      for (final country in matches)
                        ListTile(
                          dense: true,
                          selected: country == widget.selected,
                          selectedTileColor: colorScheme.primary.withValues(
                            alpha: 0.08,
                          ),
                          leading: Text(
                            country.flag,
                            style: const TextStyle(fontSize: 22),
                          ),
                          title: Text(country.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                country.dial,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: country == widget.selected
                                    ? colorScheme.primary
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                          onTap: () => widget.onSelected(country),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
