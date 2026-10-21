// Renders the screenshots shown on pub.dev into ../screenshots.
//
// Run from the example folder:
//
//   flutter test tool/screenshots_test.dart
//
// It is outside test/, so a plain `flutter test` doesn't run it.

import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screenshots/frame.dart';
import 'screenshots/harness.dart';
import 'screenshots/screens/editor.dart';
import 'screenshots/screens/files.dart';
import 'screenshots/screens/map.dart';
import 'screenshots/screens/post.dart';
import 'screenshots/screens/tasks.dart';
import 'screenshots/screens/trip.dart';

void main() {
  setUpAll(loadFonts);

  testWidgets('cover', (tester) async {
    final like = GlobalKey();
    // 440 logical pixels fit the phone with a small margin, drawn at
    // 800 x 800.
    await pump(
      tester,
      size: const Size(800, 800),
      pixelRatio: 800 / 440,
      home: Cover(
        screen: PostScreen(
          likeKey: like,
          commentKey: GlobalKey(),
          shareKey: GlobalKey(),
          bottomSpace: 20,
        ),
      ),
    );
    await tester.longPress(find.byKey(like));
    await tester.pumpAndSettle();
    await capture(tester, '0_cover');
  });

  testWidgets('menu', (tester) async {
    final more = GlobalKey();
    await pumpPoster(
      tester,
      glow: true,
      title: 'Menus that return a value',
      subtitle:
          'Open a menu right at the button and get the picked item back '
          'from ArrowPopup.show.',
      screen: FilesScreen(moreKey: more),
    );
    await openPopup(
      tester,
      more,
      const Menu(),
      style: (base) =>
          base.copyWith(padding: const EdgeInsets.symmetric(vertical: 6)),
    );
    await capture(tester, '1_menu');
  });

  testWidgets('placement', (tester) async {
    final pins = [for (final _ in places) GlobalKey()];
    await pumpPoster(
      tester,
      glow: true,
      title: 'Placed where it fits',
      subtitle:
          'Ask for above, below, start or end. Near an edge it flips to the '
          'side with room, so it never overflows.',
      screen: MapScreen(pinKeys: pins),
    );
    final scheme = Theme.of(tester.element(find.byKey(pins.first))).colorScheme;
    for (final (i, place) in places.indexed) {
      await openPopup(
        tester,
        pins[i],
        PlaceCard(place),
        placement: place.placement,
        style: (base) => base.copyWith(
          color: scheme.surfaceContainerLowest,
          borderRadius: 12,
          padding: const EdgeInsets.fromLTRB(12, 8, 14, 9),
        ),
      );
    }
    await capture(tester, '2_placement');
  });

  testWidgets('style', (tester) async {
    final like = GlobalKey();
    final comment = GlobalKey();
    final share = GlobalKey();
    await pumpPoster(
      tester,
      glow: true,
      title: 'Style it your way',
      subtitle:
          'Reactions on long press, an outlined label, a toast without an '
          'arrow. Style one popup, or the whole app with a theme extension.',
      screen: PostScreen(likeKey: like, commentKey: comment, shareKey: share),
    );
    // The like button is an ArrowPopup that opens on long press.
    await tester.longPress(find.byKey(like));
    await tester.pumpAndSettle();
    final scheme = Theme.of(tester.element(find.byKey(comment))).colorScheme;
    await openPopup(
      tester,
      comment,
      const Text('3 comments'),
      placement: ArrowPopupPlacement.below,
      style: (base) => base.copyWith(
        color: scheme.surface,
        border: BorderSide(color: scheme.outline),
        shadows: const [],
        borderRadius: 8,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
    await openPopup(
      tester,
      share,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: scheme.primary, size: 18),
          const SizedBox(width: 6),
          const Text('Copied'),
        ],
      ),
      placement: ArrowPopupPlacement.below,
      style: (base) => base.copyWith(
        showArrow: false,
        gap: 8,
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
    await capture(tester, '3_style');
  });

  testWidgets('tour', (tester) async {
    final add = GlobalKey();
    await pumpPoster(
      tester,
      glow: true,
      title: 'Guided tours',
      subtitle:
          'Open and close popups from code with ArrowPopupController to walk '
          'people through your app.',
      screen: TasksScreen(addKey: add),
    );
    final scheme = Theme.of(tester.element(find.byKey(add))).colorScheme;
    await openPopup(
      tester,
      add,
      const TourStep(),
      placement: ArrowPopupPlacement.above,
      style: (base) => base.copyWith(
        color: scheme.primary,
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
      ),
    );
    await capture(tester, '4_tour');
  });

  testWidgets('tooltip', (tester) async {
    final bold = GlobalKey();
    await pumpPoster(
      tester,
      dark: true,
      glow: true,
      title: 'Tooltips on hover',
      subtitle:
          'Opens while the mouse rests on the anchor and stays open as it '
          'moves into the bubble. Follows dark mode.',
      screen: EditorScreen(boldKey: bold),
    );
    await openPopup(
      tester,
      bold,
      const Shortcut(label: 'Bold', keys: ['Ctrl', 'B']),
      style: (base) => base.copyWith(
        borderRadius: 10,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
    await capture(tester, '5_tooltip_dark');
  });

  testWidgets('dropdown', (tester) async {
    final field = GlobalKey();
    await pumpPoster(
      tester,
      dark: true,
      glow: true,
      title: 'Dropdowns, too',
      subtitle:
          'Turn the arrow off and match the field\'s width for a searchable '
          'dropdown.',
      screen: TripScreen(countryKey: field),
    );
    const padding = 6.0;
    await openPopup(
      tester,
      field,
      SizedBox(
        width: tester.getSize(find.byKey(field)).width - padding * 2,
        child: const CountryList(),
      ),
      placement: ArrowPopupPlacement.below,
      style: (base) => base.copyWith(
        showArrow: false,
        gap: 6,
        borderRadius: 14,
        padding: const EdgeInsets.all(padding),
      ),
    );
    await capture(tester, '6_dropdown_dark');
  });
}
