<div align="center">
  <h1 align="center" style="font-size: 50px;">💬 Arrow Popup 💬</h1>
  <p align="center">
  A popup bubble with an arrow that points at any widget. Use it for tooltips, popovers, menus and dropdowns, with automatic placement and a controller.
 </p>
  <p align="center">
  <b>One widget. Any popup. Zero dependencies.</b>
 </p>
</div>

<div align="center">
   <!--  Donations -->
  <a href="https://ko-fi.com/mrrhak">
    <img width="300" src="https://user-images.githubusercontent.com/26390946/161375567-9e14cd0e-1675-4896-a576-a449b0bcd293.png">
  </a>
  <div align="center">
    <a href="https://www.buymeacoffee.com/mrrhak">
      <img width="150" alt="buymeacoffee" src="https://user-images.githubusercontent.com/26390946/161375563-69c634fd-89d2-45ac-addd-931b03996b34.png">
    </a>
    <a href="https://ko-fi.com/mrrhak">
      <img width="150" alt="Ko-fi" src="https://user-images.githubusercontent.com/26390946/161375565-e7d64410-bbcf-4a28-896b-7514e106478e.png">
    </a>
  </div>
  <!--  Donations -->
</div>

<div align="center">
  <a href="https://pub.dev/packages/arrow_popup">
    <img src="https://img.shields.io/pub/v/arrow_popup?label=Pub&logo=dart"
      alt="Pub Package" />
  </a>
  <a href="https://pub.dev/packages/arrow_popup">
    <img src="https://img.shields.io/pub/likes/arrow_popup?style=flat&logo=dart&label=Likes" alt="Pub Likes"/>
  </a>
  <a href="https://pub.dev/packages/arrow_popup/score">
    <img src="https://img.shields.io/pub/points/arrow_popup?label=Score&logo=dart"
      alt="Pub Score" />
  </a>
  <a href="https://pub.dev/packages/arrow_popup">
    <img alt="Pub Monthly Downloads" src="https://img.shields.io/pub/dm/arrow_popup?style=flat&color=blue&logo=dart&label=Downloads&link=https%3A%2F%2Fpub.dev%2Fpackages%2Farrow_popup">
  </a>
  <a href="https://github.com/mrrhak/arrow_popup"><img src="https://img.shields.io/github/stars/mrrhak/arrow_popup.svg?style=flat&logo=github&colorB=deeppink&label=Stars" alt="Star on Github"></a>
  <a href="https://github.com/mrrhak/arrow_popup"><img src="https://img.shields.io/github/forks/mrrhak/arrow_popup?color=orange&label=Forks&logo=github" alt="Forks on Github"></a>
  <a href="https://github.com/mrrhak/arrow_popup/graphs/contributors">
    <img src="https://img.shields.io/github/contributors/mrrhak/arrow_popup.svg?style=flat&logo=github&colorB=yellow&label=Contributors"
      alt="Contributors" />
  </a>
  <a href="https://github.com/mrrhak/arrow_popup/actions/workflows/format-analyze-test.yml">
    <img src="https://github.com/mrrhak/arrow_popup/actions/workflows/format-analyze-test.yml/badge.svg"
      alt="Build Status" />
  </a>
  <a href="https://codecov.io/gh/mrrhak/arrow_popup">
    <img src="https://codecov.io/gh/mrrhak/arrow_popup/graph/badge.svg?token=V3E9J2828V"
      alt="Coverage" />
  </a>
  <a href="https://github.com/mrrhak/arrow_popup">
    <img src="https://img.shields.io/github/languages/code-size/mrrhak/arrow_popup?logo=github&color=blue&label=Size"
      alt="Code size" />
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/github/license/mrrhak/arrow_popup?label=License&color=red&logo=Leanpub"
      alt="License: MIT" />
  </a>
  <a href="https://pub.dev/packages/arrow_popup">
    <img src="https://img.shields.io/badge/Platform-Android%20|%20iOS%20|%20Web%20|%20macOS%20|%20Windows%20|%20Linux%20-blue.svg?logo=flutter"
      alt="Platform" />
  </a>
</div>

<p align="center">
  <a href="#-installation">Install</a> ·
  <a href="#-usage">Usage</a> ·
  <a href="#-features">Features</a> ·
  <a href="#-notes">Notes</a> ·
  <a href="https://pub.dev/documentation/arrow_popup/latest/">API docs</a> ·
  <a href="https://github.com/mrrhak/arrow_popup/tree/master/example">Example</a>
</p>

---

<table align="center">
  <tr>
    <td><img src="https://raw.githubusercontent.com/mrrhak/arrow_popup/master/screenshots/1_menu.png" width="400" alt="A menu that returns the picked item"/></td>
    <td><img src="https://raw.githubusercontent.com/mrrhak/arrow_popup/master/screenshots/2_placement.png" width="400" alt="Place cards on a map opening on every side"/></td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/mrrhak/arrow_popup/master/screenshots/3_style.png" width="400" alt="A long-press reaction picker and other popup styles"/></td>
    <td><img src="https://raw.githubusercontent.com/mrrhak/arrow_popup/master/screenshots/4_tour.png" width="400" alt="A guided tour step opened from code"/></td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/mrrhak/arrow_popup/master/screenshots/5_tooltip_dark.png" width="400" alt="A hover tooltip in dark mode"/></td>
    <td><img src="https://raw.githubusercontent.com/mrrhak/arrow_popup/master/screenshots/6_dropdown_dark.png" width="400" alt="A searchable dropdown in dark mode"/></td>
  </tr>
</table>

## ✨ Why arrow_popup?

- **One widget for every popup.** Tooltips, popovers, menus, dropdowns and
  guided tours all use the same `ArrowPopup`.
- **Never off screen.** It flips to the side with room, stays inside the
  safe area and moves out of the keyboard's way.
- **Looks right by default.** It follows your theme and dark mode, and one
  `ArrowPopupStyle` in the theme restyles every popup in the app.
- **Tiny to adopt.** Wrap a widget, give it some content, done. It needs
  nothing but Flutter.
- **Built for real apps.** Right-to-left, keyboard and screen reader support
  are included, not left for you to add.

## 🧩 Features

- Bubble and arrow drawn as one shape, with a shared shadow
- Opens above, below, left, right, start or end of the anchor, or `auto`, and
  moves to another side when there isn't room
- Right-to-left aware: `start` and `end` placements and
  `EdgeInsetsDirectional` padding follow the text direction
- Stays inside the safe area and moves out of the keyboard's way
- Follows the anchor when it moves or scrolls, or the screen rotates or
  resizes, and closes once the anchor scrolls out of view
- Works in nested navigators
- Opens on tap, long press, double tap or mouse hover (a tooltip that stays
  open while the mouse is over it), or from code with a controller
- Keyboard (Enter / Space to open, Escape to close) and screen reader
  support
- An open popup updates when its content or style changes
- `ArrowPopup.show` returns a value, so it works as a menu
- `maxWidth` keeps long tooltips from spanning the screen, and `maxHeight`
  limits how tall the content can be
- Works in `MaterialApp`, `CupertinoApp` and `WidgetsApp`

## 📦 Installation

```sh
flutter pub add arrow_popup
```

It requires Flutter 3.32 or newer.

```dart
import 'package:arrow_popup/arrow_popup.dart';
```

## 🚀 Usage

### Basic popup

Tap the child to open the popup:

```dart
ArrowPopup(
  content: const Text('Saved to your library'),
  child: const Icon(Icons.info_outline),
)
```

### Hover tooltip

Opens when the mouse rests on the child, and closes when it leaves. On touch
screens a tap opens it instead:

```dart
ArrowPopup(
  trigger: ArrowPopupTrigger.hover,
  waitDuration: const Duration(milliseconds: 500),
  semanticLabel: 'Bold, Command B',
  content: const Text('Bold  ⌘B'),
  child: const Icon(Icons.format_bold),
)
```

### Styling

```dart
ArrowPopup(
  style: const ArrowPopupStyle(
    color: Colors.indigo,
    borderRadius: 16,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    arrowSize: Size(20, 10),
    maxWidth: 240,
  ),
  barrierColor: Colors.transparent,
  placement: ArrowPopupPlacement.above,
  content: const Text('Hello', style: TextStyle(color: Colors.white)),
  child: const Icon(Icons.waving_hand),
)
```

To style every popup in the app, add a style to the theme. Popups without
their own `style` use it:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      ArrowPopupStyle(
        borderRadius: 14,
        border: BorderSide(color: Colors.grey.shade300),
      ),
    ],
  ),
)
```

In an app without a Material `ThemeData`, such as a `CupertinoApp` or a
`WidgetsApp`, use `ArrowPopupTheme` instead:

```dart
ArrowPopupTheme(
  style: const ArrowPopupStyle(borderRadius: 14),
  child: child,
)
```

A popup uses its own `style`, else the nearest `ArrowPopupTheme`, else the
theme's extension, else the default. Without a Material `Theme`, the default
color, text style and focus outline follow the Cupertino theme and the
platform brightness.

A popup's own `style` replaces the theme's. To change only part of it, start
from the theme's: `ArrowPopupStyle.of(context).copyWith(maxWidth: 240)`.

### Menu that returns a value

```dart
IconButton(
  icon: const Icon(Icons.sort),
  onPressed: () async {
    final order = await ArrowPopup.show<String>(
      context: context,
      content: Builder(
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in ['Newest', 'Oldest', 'Name'])
              TextButton(
                onPressed: () => ArrowPopup.close(context, option),
                child: Text(option),
              ),
          ],
        ),
      ),
    );
    if (order != null) print('Sort by $order');
  },
)
```

`ArrowPopup.show` points at the widget that `context` belongs to. Pass the
context of the widget the arrow should point at.

`ArrowPopup.close(context, value)` closes the popup that `context` is in, so
call it with a context inside the content, such as from a `Builder`.
`Navigator.pop` works too, except in popups opened by mouse hover, which
aren't routes.

`ArrowPopup` returns values the same way. Give it the value's type, and
`onClose` (or `ArrowPopupController.show`) receives the value the content
closes with:

```dart
ArrowPopup<String>(
  onClose: (order) {
    if (order != null) print('Sort by $order');
  },
  content: Builder(
    builder: (context) => TextButton(
      onPressed: () => ArrowPopup.close(context, 'Newest'),
      child: const Text('Newest'),
    ),
  ),
  child: const Icon(Icons.sort),
)
```

### Opening from a button

An enabled button handles taps itself, so `ArrowPopup`'s own tap trigger
never sees them. Use `ArrowPopup.builder` instead, and open the popup from
the button:

```dart
ArrowPopup.builder(
  content: const Text('Saved to your library'),
  builder: (context, show) => IconButton(
    icon: const Icon(Icons.info_outline),
    onPressed: show,
  ),
)
```

`show` completes with the value the popup closes with, so
`final order = await show();` works as with `ArrowPopup.show`. The arrow
points at the built button.

### Opening from code

// In your State, and dispose it with the State.
final controller = ArrowPopupController();

// In build:
ArrowPopup(
  controller: controller,
  trigger: ArrowPopupTrigger.none,
  content: const Text('Try this new feature'),
  child: const Icon(Icons.star),
)

// Later, such as when an onboarding step starts:
controller.show();
controller.hide();
controller.toggle(); // closes it if it is open, otherwise opens it

`ArrowPopupController` is a `ChangeNotifier`, so you can listen to it (for
example with `ListenableBuilder`) to react when `isOpen` changes. Dispose it
when you're done.

### Full-width dropdown without an arrow

```dart
ArrowPopup(
  style: const ArrowPopupStyle(
    showArrow: false,
    borderRadius: 0,
    screenMargin: 0,
    gap: 0,
  ),
  content: const SizedBox(
    width: double.infinity,
    child: Text('Filter options'),
  ),
  child: const Text('Filter'),
)
```

## 📝 Notes

<details>
<summary>Behavior details and tips (click to expand)</summary>

**Setup**

- `ArrowPopup` must be below a `Navigator` (and so an `Overlay`) when it
  opens, which is the case for any screen of a `MaterialApp`, `CupertinoApp`
  or `WidgetsApp`. It is not in the `builder` of those apps, which sits above
  their navigator: tapping there throws Flutter's "Navigator operation
  requested with a context that does not include a Navigator". Put it inside
  a screen instead.
- The content of a popup that opens as a route is built in the navigator's
  overlay, not where `ArrowPopup` is. It gets the theme and text direction
  from there, but not other inherited widgets between the navigator and the
  popup, such as a `Provider`, a `Bloc` or a `Form`. Read them outside and
  pass the values in, or provide them again around the content. Popups
  opened by `ArrowPopupTrigger.hover` see them.

**Placement and size**

- `placement` is the side the popup prefers. If the content doesn't fit
  there, it opens on the opposite side, then on one of the other two. Content
  is measured at its natural width, so for long text beside the anchor, set
  `ArrowPopupStyle.maxWidth` to make it wrap.
- A `Column` in `content` fills the available height unless it has
  `mainAxisSize: MainAxisSize.min`.
- If the content can be taller than the screen, wrap it in a
  `SingleChildScrollView`. The content is limited to the space on the side
  where the popup opens. When that space is under a quarter of the screen,
  as beside an anchor that fills it, the bubble is centered over the anchor
  instead, without an arrow.
- `ArrowPopupStyle.shadows` uses each shadow's color, offset and blur;
  `spreadRadius` is ignored.
- With `padding: EdgeInsets.zero`, set `clipBehavior: Clip.antiAlias` in
  `ArrowPopupStyle` so the content doesn't spill past the rounded corners.

**Opening and closing**

- The popup closes once no part of its anchor is visible, for example when
  it scrolls out of its list. As with any dismissal, `ArrowPopup.show`
  returns null and `onClose` is called with null. While the keyboard is
  open it stays, since the keyboard is usually what hides the anchor, such
  as when typing in a search field inside the popup.
- Set `autoCloseDuration` for brief confirmations such as "Copied": the
  popup closes by itself that long after it opens, as if dismissed. The
  default, `Duration.zero`, keeps it open.
- Set `waitDuration` so a hover popup opens only once the mouse has rested
  on the anchor that long, as toolbar tooltips do. Moving the mouse past
  sooner opens nothing. The default, `Duration.zero`, opens it right away.
- Set `closeDelay` to change how long a hover popup stays after the mouse
  leaves the anchor and the bubble. The default is 100 milliseconds.
- Popups are routes on the navigator, so navigator observers such as
  analytics see them. Pass `routeSettings` (such as
  `RouteSettings(name: 'menu')`) to tell them apart from screens. Popups
  opened by `ArrowPopupTrigger.hover` are tooltips shown in the overlay
  instead, so observers don't see each hover.

**Focus and accessibility**

- If `child` can already take keyboard focus, set `focusable: false` so it
  isn't focused twice. For buttons, use `ArrowPopup.builder` as shown above.
  Otherwise the anchor gets an outline in the theme's primary color while
  it has keyboard focus. Change it with `focusDecoration`, such as
  `ShapeDecoration(shape: CircleBorder(side: ...))` for a round anchor, or
  pass `BoxDecoration()` to hide it.
- Pass `semanticLabel` (such as `'Options'`) so screen readers announce what
  opened. A popup opened by mouse hover isn't announced, so with
  `ArrowPopupTrigger.hover` screen readers read the label as the anchor's
  tooltip instead, as with Flutter's `Tooltip`. Set it to the popup's text,
  such as `'Bold, Command B'`.

</details>

## 🐞 Bugs or Requests

If you encounter any problems, feel free to open an [issue](https://github.com/mrrhak/arrow_popup/issues/new?template=bug_report.md). If you feel the library is missing a feature, please raise a [ticket](https://github.com/mrrhak/arrow_popup/issues/new?template=feature_request.md) on GitHub and I'll look into it. Pull requests are also welcome.

See [Contributing.md](https://github.com/mrrhak/arrow_popup/blob/master/CONTRIBUTING.md).

## 💖 Support

Don't forget to give it a like 👍 or a star ⭐

## 📈 Activities

![Alt](https://repobeats.axiom.co/api/embed/81d79400a15c47b3d44b35c8eac655bb9b321916.svg "Repobeats analytics image")

## 📄 License

MIT. See [LICENSE](LICENSE).
