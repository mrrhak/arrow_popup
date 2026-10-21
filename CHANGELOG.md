# Changelog

## 1.0.0

First stable release. The API is now covered by semantic versioning.

- **Breaking:** `ArrowPopupStyle.copyWith` takes `color` as a plain `Color?`,
  not a function, and null keeps the current color like the other fields. To
  go back to the theme's default color, create a new `ArrowPopupStyle`.
- `closeDelay` sets how long a hover popup stays after the mouse leaves the
  anchor and the bubble. The default is the same 100 milliseconds as before.

## 1.0.0-beta.1

First beta. The API is meant to be final; it is published as a beta to gather
feedback before 1.0.0.

### Popups

- `ArrowPopup` widget: a bubble with an arrow that points at any widget, for
  tooltips, popovers, menus and dropdowns.
- `ArrowPopup.builder` opens the popup from a button it points at, without a
  controller.
- `ArrowPopup.show` opens a popup from code, pointing at the widget of a
  `BuildContext`.
- `ArrowPopup.close(context, value)` closes a popup from its content with a
  value, which `onClose`, `ArrowPopupController.show` and `ArrowPopup.show`
  receive.
- `ArrowPopupController` opens and closes a popup from code, with `show`,
  `hide`, `toggle` and `isOpen`.

### Triggers

- Opens on tap, long press, double tap or mouse hover, or from code.
- `waitDuration` makes hover wait before opening.
- `autoCloseDuration` closes brief confirmations by itself.

### Placement

- Above, below, left, right, start or end of the anchor, or `auto`. The popup
  moves to another side when there isn't room, so it never overflows.
- Follows the anchor as it moves, scrolls or resizes, and closes once the
  anchor scrolls out of view or is removed.

### Style

- `ArrowPopupStyle` for color, border, corner radius, padding, shadows, arrow
  size, gap, screen margin, max width, max height and clipping.
- It can be set for the whole app as a `ThemeData` extension, or with
  `ArrowPopupTheme` in any app.

### Accessibility and platforms

- Right-to-left, keyboard and screen reader support, and reduced motion.
  Hover popups give screen readers their `semanticLabel` as the anchor's
  tooltip.
- Works in apps without a Material theme, such as `CupertinoApp` and
  `WidgetsApp`: the default colors, focus outline, text style and barrier
  label follow the Cupertino theme and the platform brightness.
