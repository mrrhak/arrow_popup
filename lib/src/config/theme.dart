import 'package:flutter/widgets.dart';

import 'style.dart';

/// Sets the [ArrowPopupStyle] of the popups below it.
///
/// It works in any app, including ones built on `CupertinoApp` or
/// `WidgetsApp` that have no `ThemeData` to hold a theme extension:
///
/// ```dart
/// ArrowPopupTheme(
///   style: const ArrowPopupStyle(borderRadius: 16),
///   child: child,
/// )
/// ```
///
/// A popup uses, in this order: its own `style`, the nearest
/// [ArrowPopupTheme], the [ArrowPopupStyle] in `ThemeData.extensions`, then
/// the default style. A popup that picks one uses it whole; start from
/// [ArrowPopupStyle.of] to change only some of the settings.
class ArrowPopupTheme extends InheritedTheme {
  /// Creates a theme that gives the popups in [child] [style].
  const ArrowPopupTheme({super.key, required this.style, required super.child});

  /// The style of the popups below this widget.
  final ArrowPopupStyle style;

  /// The style of the nearest [ArrowPopupTheme], or null when there is none.
  static ArrowPopupStyle? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ArrowPopupTheme>()?.style;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return ArrowPopupTheme(style: style, child: child);
  }

  @override
  bool updateShouldNotify(ArrowPopupTheme oldWidget) =>
      style != oldWidget.style;
}
