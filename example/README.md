# arrow_popup example

A demo app for [arrow_popup](../README.md). Toggle dark mode from the app bar
to see every popup follow the theme.

```sh
flutter run
```

Each section of the home page lives in its own file, so you can read the one
you need:

| File | Shows |
| --- | --- |
| [`tooltip_demo.dart`](lib/demos/tooltip_demo.dart) | `ArrowPopup` as a tooltip on an icon, bar segments and a chip |
| [`placement_demo.dart`](lib/demos/placement_demo.dart) | `placement`: above, below, left, right and auto |
| [`trigger_demo.dart`](lib/demos/trigger_demo.dart) | `trigger`: tap, long press, double tap and hover |
| [`menu_demo.dart`](lib/demos/menu_demo.dart) | `ArrowPopup.show<T>` menus that return a value |
| [`settings_demo.dart`](lib/demos/settings_demo.dart) | Pickers that close with a value, styled by the theme |
| [`auto_close_demo.dart`](lib/demos/auto_close_demo.dart) | `autoCloseDuration` for a brief "Link copied" |
| [`controller_demo.dart`](lib/demos/controller_demo.dart) | `ArrowPopupController` driving a feature tour |
| [`style_demo.dart`](lib/demos/style_demo.dart) | `ArrowPopupStyle` options |
| [`dropdown_demo.dart`](lib/demos/dropdown_demo.dart) | A searchable dropdown without an arrow |

[`main.dart`](lib/main.dart) only sets up the app and lists the sections.
