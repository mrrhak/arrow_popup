# Screenshot tool

Renders the images shown on pub.dev and in the package README. They are drawn
by a widget test, so they are reproducible and need no device or emulator.

## Generate

Run from the `example` folder:

```sh
cd example
flutter test tool/screenshots_test.dart
```

The PNGs are written to `screenshots/` at the package root.

Then compress them, so the published package stays small (about 600 KB
instead of 3.8 MB):

```sh
sh tool/compress_screenshots.sh
```

It needs `pngquant` and `oxipng` (`brew install pngquant oxipng`), and
compresses in place. Do this after every regeneration: the test always writes
full-size images. The dark images are kept at a higher quality, because their
soft glow bands otherwise.

To render a single image, filter by test name:

```sh
flutter test tool/screenshots_test.dart --plain-name tooltip
```

| Test        | Image                   |
| ----------- | ----------------------- |
| `cover`     | `0_cover.png`           |
| `menu`      | `1_menu.png`            |
| `placement` | `2_placement.png`       |
| `style`     | `3_style.png`           |
| `tour`      | `4_tour.png`            |
| `tooltip`   | `5_tooltip_dark.png`    |
| `dropdown`  | `6_dropdown_dark.png`   |

`0_cover.png` is the square thumbnail in pub.dev search results. The others are
1200 x 720 posters: a caption on the left and a phone on the right.

## Notes

- Run it from `example/`. The output path is relative (`../screenshots`).
- Use `flutter test`, not `dart`. It sets `FLUTTER_ROOT`, which the tool needs
  to load the Roboto and Material icon fonts (the test font draws boxes).
- The file is outside `test/`, so a plain `flutter test` does not run it.
- Emojis and non-Material icons do not render in the test font.

## Layout

```
tool/
  screenshots_test.dart   the tests, one per image
  compress_screenshots.sh shrinks the generated PNGs in place
  screenshots/
    harness.dart          fonts, theme, pump, open popup, capture to PNG
    frame.dart            poster, cover and phone frame
    screens/              the fake app screen and popup content for each image
```

## Adding or changing an image

1. Add a screen and its popup content in `screenshots/screens/`.
2. Add a `testWidgets` in `screenshots_test.dart` that pumps it with
   `pumpPoster`, opens the popup with `openPopup` and calls `capture` with the
   file name. Pass `dark: true` for a dark poster, plus `glow: true` for the
   soft light behind the phone.
3. Keep the numbering in order, then update the image lists in the root
   `README.md` and in `pubspec.yaml` (`screenshots:`).
