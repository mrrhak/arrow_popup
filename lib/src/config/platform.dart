import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Where the package reads colors and text styles from, so it works in an app
// without a Material `Theme`, such as a `CupertinoApp` or a `WidgetsApp`.

/// Whether a Material [Theme] is above [context].
///
/// `Theme.of` can't say, since it falls back to a default theme.
bool hasMaterialTheme(BuildContext context) {
  return context.findAncestorWidgetOfExactType<Theme>() != null;
}

/// The bubble's fill color when the style sets none: Material 3's menu color
/// under a [Theme], otherwise a Cupertino background, which follows the
/// platform brightness in an app without a theme.
Color defaultBubbleColor(BuildContext context) {
  if (hasMaterialTheme(context)) {
    return Theme.of(context).colorScheme.surfaceContainer;
  }
  return CupertinoDynamicColor.resolve(
    CupertinoColors.secondarySystemGroupedBackground,
    context,
  );
}

/// The color of the keyboard focus outline: the theme's primary color, or
/// the Cupertino theme's.
Color defaultFocusColor(BuildContext context) {
  if (hasMaterialTheme(context)) return Theme.of(context).colorScheme.primary;
  return CupertinoDynamicColor.resolve(
    CupertinoTheme.of(context).primaryColor,
    context,
  );
}

/// The text style of the popup's content when it is shown outside a [Theme],
/// else null, which leaves it to Material's.
TextStyle? defaultTextStyle(BuildContext context) {
  if (hasMaterialTheme(context)) return null;
  return CupertinoTheme.of(context).textTheme.textStyle;
}
