import 'package:flutter/material.dart';

import 'demos/auto_close_demo.dart';
import 'demos/controller_demo.dart';
import 'demos/dropdown_demo.dart';
import 'demos/menu_demo.dart';
import 'demos/placement_demo.dart';
import 'demos/settings_demo.dart';
import 'demos/style_demo.dart';
import 'demos/tooltip_demo.dart';
import 'demos/trigger_demo.dart';
import 'section.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arrow Popup',
      themeMode: _themeMode,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: HomePage(
        dark: _themeMode == ThemeMode.dark,
        onDarkChanged: (dark) => setState(
          () => _themeMode = dark ? ThemeMode.dark : ThemeMode.light,
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.dark, required this.onDarkChanged});

  final bool dark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrow Popup'),
        actions: [
          IconButton(
            tooltip: dark ? 'Light mode' : 'Dark mode',
            icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => onDarkChanged(!dark),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Section(
            title: 'Tooltip',
            subtitle: 'Tap the info icon, a bar segment or the warning.',
            child: TooltipDemo(),
          ),
          Section(
            title: 'Placement',
            subtitle: 'Each bar opens toward the canvas. The shape uses auto.',
            child: PlacementDemo(),
          ),
          Section(
            title: 'Triggers',
            subtitle:
                'Open on tap, long press, double tap or hover, like real apps '
                'do.',
            child: TriggerDemo(),
          ),
          Section(
            title: 'Menu',
            subtitle: 'ArrowPopup.show returns the value popped from it.',
            child: MenuDemo(),
          ),
          Section(
            title: 'Settings',
            subtitle:
                'ArrowPopup<T> returns the picked option. The theme gives '
                'every picker its outlined look.',
            child: SettingsDemo(),
          ),
          Section(
            title: 'Auto close',
            subtitle:
                'Copy the link. The popup closes by itself after the chosen '
                'time; the default never does.',
            child: AutoCloseDemo(),
          ),
          Section(
            title: 'Controller',
            subtitle: 'Open and close from code, and listen to isOpen.',
            child: ControllerDemo(),
          ),
          Section(
            title: 'Styling',
            subtitle: 'Tap a tile. Each one opens a different ArrowPopupStyle.',
            child: StyleDemo(),
          ),
          Section(
            title: 'Dropdown',
            subtitle: 'Searchable and scrollable, as wide as the field.',
            child: DropdownDemo(),
          ),
        ],
      ),
    );
  }
}
