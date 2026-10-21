import 'dart:async';

import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart' as s;

void main() {
  group('routeSettings reach navigator observers', () {
    for (final useFunction in [false, true]) {
      testWidgets(useFunction ? 'ArrowPopup.show' : 'ArrowPopup', (
        tester,
      ) async {
        final observer = s.RecordingObserver();
        const settings = RouteSettings(name: 'help', arguments: 1);
        await tester.pumpWidget(
          MaterialApp(
            navigatorObservers: [observer],
            home: Scaffold(
              body: Center(
                child: useFunction
                    ? Builder(
                        builder: (context) => GestureDetector(
                          onTap: () => ArrowPopup.show<void>(
                            context: context,
                            routeSettings: settings,
                            content: const SizedBox(),
                          ),
                          child: const s.Anchor(),
                        ),
                      )
                    : const ArrowPopup(
                        routeSettings: settings,
                        content: SizedBox(),
                        child: s.Anchor(),
                      ),
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(s.anchorKey));
        await tester.pumpAndSettle();
        expect(observer.pushed.last.settings, same(settings));
      });
    }
  });

  testWidgets('ArrowPopup.show closes when its anchor is removed', (
    tester,
  ) async {
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    late Future<String?> result;
    await tester.pumpWidget(
      s.app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('page'),
            ValueListenableBuilder(
              valueListenable: visible,
              builder: (context, show, _) => show
                  ? Builder(
                      builder: (context) => TextButton(
                        onPressed: () => result = ArrowPopup.show<String>(
                          context: context,
                          content: const SizedBox(
                            key: s.contentKey,
                            height: 50,
                          ),
                        ),
                        child: const Text('open'),
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsOneWidget);

    visible.value = false;
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsNothing);
    expect(await result, isNull);
    // Only the popup closed, not the page under it.
    expect(find.text('page'), findsOneWidget);
  });

  testWidgets('ArrowPopup.show explains a context that is not a box', (
    tester,
  ) async {
    late BuildContext sliverContext;
    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          slivers: [
            Builder(
              builder: (context) {
                sliverContext = context;
                return const SliverToBoxAdapter(child: SizedBox(height: 40));
              },
            ),
          ],
        ),
      ),
    );

    expect(
      () => ArrowPopup.show<void>(
        context: sliverContext,
        content: const SizedBox(),
      ),
      throwsA(
        isAssertionError.having(
          (e) => e.message,
          'message',
          contains('box widget'),
        ),
      ),
    );
  });

  testWidgets('opens below the anchor when there is room', (tester) async {
    await tester.pumpWidget(s.app(s.popup()));
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    final anchor = tester.getRect(find.byKey(s.anchorKey));
    final content = tester.getRect(find.byKey(s.contentKey));
    expect(content.top, greaterThan(anchor.bottom));
    expect(content.center.dx, moreOrLessEquals(anchor.center.dx));
    expect(s.layoutOf(tester).geometry!.side, AxisDirection.down);
  });

  testWidgets('opens above when there is no room below', (tester) async {
    await tester.pumpWidget(
      s.app(s.popup(), alignment: Alignment.bottomCenter),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    final anchor = tester.getRect(find.byKey(s.anchorKey));
    final content = tester.getRect(find.byKey(s.contentKey));
    expect(content.bottom, lessThan(anchor.top));
  });

  testWidgets('placement above is respected', (tester) async {
    await tester.pumpWidget(
      s.app(s.popup(placement: ArrowPopupPlacement.above)),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    final anchor = tester.getRect(find.byKey(s.anchorKey));
    final content = tester.getRect(find.byKey(s.contentKey));
    expect(content.bottom, lessThan(anchor.top));
  });

  testWidgets('placement above flips below when there is no room above', (
    tester,
  ) async {
    await tester.pumpWidget(
      s.app(
        s.popup(placement: ArrowPopupPlacement.above),
        alignment: Alignment.topCenter,
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    final anchor = tester.getRect(find.byKey(s.anchorKey));
    final content = tester.getRect(find.byKey(s.contentKey));
    expect(content.top, greaterThan(anchor.bottom));
  });

  testWidgets('content that fits nowhere shrinks to the roomier side', (
    tester,
  ) async {
    // Taller than the room above or below a centered anchor, and too wide to
    // go beside it.
    await tester.pumpWidget(
      s.app(
        ArrowPopup(
          content: const SizedBox(key: s.contentKey, width: 2000, height: 2000),
          child: const s.Anchor(),
        ),
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    final anchor = tester.getRect(find.byKey(s.anchorKey));
    final content = tester.getRect(find.byKey(s.contentKey));
    expect(content.top, greaterThan(anchor.bottom));
    expect(content.bottom, lessThanOrEqualTo(600));
  });

  testWidgets('an anchor that fills the screen gets an overlapping bubble', (
    tester,
  ) async {
    final popup = ArrowPopupController();
    addTearDown(popup.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ArrowPopup(
          controller: popup,
          trigger: ArrowPopupTrigger.none,
          content: const SizedBox(key: s.contentKey, width: 100, height: 200),
          child: const SizedBox.expand(),
        ),
      ),
    );
    unawaited(popup.show());
    await tester.pumpAndSettle();

    // Natural size, not squeezed into the room around the anchor.
    final content = tester.getRect(find.byKey(s.contentKey));
    expect(content.size, const Size(100, 200));
    expect(content.center, const Offset(400, 300));
    expect(s.layoutOf(tester).geometry!.arrowSize, Size.zero);
  });

  testWidgets('arrow points at the anchor and touches the bubble', (
    tester,
  ) async {
    await tester.pumpWidget(s.app(s.popup()));
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    final anchor = tester.getRect(find.byKey(s.anchorKey));
    final geometry = s.layoutOf(tester).geometry!;
    expect(geometry.tip.dx, moreOrLessEquals(anchor.center.dx));
    expect(geometry.tip.dy, moreOrLessEquals(anchor.bottom + 2));
    expect(geometry.box.top, moreOrLessEquals(geometry.tip.dy + 8));
  });

  testWidgets('arrow stays off the corners at the screen edge', (tester) async {
    await tester.pumpWidget(
      s.app(
        ArrowPopup(
          content: const SizedBox(key: s.contentKey, width: 100, height: 50),
          child: const s.Anchor(width: 4),
        ),
        alignment: Alignment.centerRight,
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    final geometry = s.layoutOf(tester).geometry!;
    expect(geometry.box.right, lessThanOrEqualTo(800 - 10));
    expect(
      geometry.arrowCenter + 8,
      lessThanOrEqualTo(geometry.box.right - geometry.radius),
    );
  });

  testWidgets('uses the style color, or surfaceContainer by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      s.app(
        s.popup(
          style: const ArrowPopupStyle(color: Colors.black, shadows: []),
        ),
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    expect(s.layoutOf(tester), paints..path(color: Colors.black));

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      s.app(s.popup(style: const ArrowPopupStyle(shadows: []))),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    final colors = Theme.of(
      tester.element(find.byKey(s.anchorKey)),
    ).colorScheme;
    // Otherwise this test couldn't tell the two apart.
    expect(colors.surfaceContainer, isNot(colors.surface));
    expect(s.layoutOf(tester), paints..path(color: colors.surfaceContainer));
  });

  group('theme style', () {
    Widget themedApp(ArrowPopupStyle themeStyle, {ArrowPopupStyle? style}) {
      return MaterialApp(
        theme: ThemeData(extensions: [themeStyle]),
        home: Scaffold(
          body: Center(
            child: ArrowPopup(
              style: style,
              content: const SizedBox(
                key: s.contentKey,
                width: 100,
                height: 50,
              ),
              child: const s.Anchor(),
            ),
          ),
        ),
      );
    }

    const teal = ArrowPopupStyle(
      color: Colors.teal,
      borderRadius: 3,
      shadows: [],
    );

    testWidgets('is used by popups without their own style', (tester) async {
      await tester.pumpWidget(themedApp(teal));
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();
      expect(s.layoutOf(tester), paints..path(color: Colors.teal));
      expect(s.layoutOf(tester).geometry!.radius, 3);
    });

    testWidgets('is replaced by a popup\'s own style', (tester) async {
      await tester.pumpWidget(
        themedApp(
          teal,
          style: const ArrowPopupStyle(color: Colors.black, shadows: []),
        ),
      );
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();
      expect(s.layoutOf(tester), paints..path(color: Colors.black));
      expect(s.layoutOf(tester).geometry!.radius, 10);
    });

    testWidgets('changes an open popup when the theme changes', (tester) async {
      await tester.pumpWidget(themedApp(teal));
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();

      await tester.pumpWidget(themedApp(teal.copyWith(color: Colors.red)));
      // The theme animates, which blends the two styles.
      await tester.pumpAndSettle();
      expect(s.layoutOf(tester), paints..path(color: Colors.red));
    });

    testWidgets('of returns the theme\'s style, or the default', (
      tester,
    ) async {
      late BuildContext context;
      Widget app(ThemeData theme) => MaterialApp(
        theme: theme,
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );

      await tester.pumpWidget(app(ThemeData()));
      expect(ArrowPopupStyle.of(context), const ArrowPopupStyle());

      await tester.pumpWidget(app(ThemeData(extensions: const [teal])));
      await tester.pumpAndSettle();
      expect(ArrowPopupStyle.of(context), teal);
    });
  });

  testWidgets('draws the border over the bubble', (tester) async {
    await tester.pumpWidget(
      s.app(
        s.popup(
          style: const ArrowPopupStyle(
            color: Colors.black,
            shadows: [],
            border: BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    expect(
      s.layoutOf(tester),
      paints
        ..path(color: Colors.black)
        ..path(color: Colors.red, style: PaintingStyle.stroke, strokeWidth: 2),
    );
  });

  testWidgets('draws no border by default', (tester) async {
    await tester.pumpWidget(s.app(s.popup()));
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    expect(
      s.layoutOf(tester),
      isNot(paints..path(style: PaintingStyle.stroke)),
    );
  });

  testWidgets('draws a hairline border for width 0', (tester) async {
    await tester.pumpWidget(
      s.app(
        s.popup(
          style: const ArrowPopupStyle(
            shadows: [],
            border: BorderSide(color: Colors.red, width: 0),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    expect(
      s.layoutOf(tester),
      paints
        ..path()
        ..path(color: Colors.red, style: PaintingStyle.stroke, strokeWidth: 0),
    );
  });

  group('ArrowPopupStyle.lerp', () {
    const a = ArrowPopupStyle(
      borderRadius: 0,
      showArrow: true,
      clipBehavior: Clip.none,
    );
    const b = ArrowPopupStyle(
      borderRadius: 20,
      showArrow: false,
      maxWidth: 200,
      clipBehavior: Clip.antiAlias,
      border: BorderSide(width: 4),
    );

    test('blends numbers', () {
      final mid = a.lerp(b, 0.5);
      expect(mid.borderRadius, 10);
      expect(mid.border.width, 2);
    });

    test('switches the rest halfway', () {
      expect(a.lerp(b, 0.25).showArrow, isTrue);
      expect(a.lerp(b, 0.25).clipBehavior, Clip.none);
      expect(a.lerp(b, 0.25).maxWidth, double.infinity);
      expect(a.lerp(b, 0.75).showArrow, isFalse);
      expect(a.lerp(b, 0.75).clipBehavior, Clip.antiAlias);
      expect(a.lerp(b, 0.75).maxWidth, 200);
    });

    test('with null keeps the style', () {
      expect(a.lerp(null, 0.5), same(a));
    });

    test('switches a color halfway when the other is the default', () {
      const red = ArrowPopupStyle(color: Color(0xFFFF0000));
      expect(a.lerp(red, 0.25).color, isNull);
      expect(a.lerp(red, 0.75).color, red.color);
      expect(red.lerp(a, 0.25).color, red.color);
      expect(red.lerp(a, 0.75).color, isNull);
    });
  });

  test('copyWith and == include the border', () {
    const style = ArrowPopupStyle();
    final bordered = style.copyWith(border: const BorderSide(width: 1));
    expect(bordered, isNot(style));
    expect(bordered.border.width, 1);
    expect(bordered.copyWith(), bordered);
  });

  group('copyWith color', () {
    const red = ArrowPopupStyle(color: Color(0xFFFF0000));

    test('keeps the color when omitted', () {
      expect(red.copyWith(borderRadius: 3).color, red.color);
    });

    test('sets the color', () {
      final blue = red.copyWith(color: const Color(0xFF0000FF));
      expect(blue.color, const Color(0xFF0000FF));
    });

    test('keeps the color with null', () {
      expect(red.copyWith().color, red.color);
    });
  });

  group('maxHeight', () {
    test('is part of ==, copyWith and lerp', () {
      const style = ArrowPopupStyle();
      final capped = style.copyWith(maxHeight: 200);
      expect(capped.maxHeight, 200);
      expect(capped, isNot(style));
      expect(capped.hashCode, isNot(style.hashCode));
      expect(style.lerp(capped, 0.25).maxHeight, double.infinity);
      expect(style.lerp(capped, 0.75).maxHeight, 200);
      expect(capped.lerp(capped.copyWith(maxHeight: 100), 0.5).maxHeight, 150);
    });

    test('must not be negative', () {
      expect(() => ArrowPopupStyle(maxHeight: -1), throwsAssertionError);
    });

    testWidgets('limits the height of the content', (tester) async {
      await tester.pumpWidget(
        s.app(
          ArrowPopup(
            style: const ArrowPopupStyle(
              maxHeight: 100,
              padding: EdgeInsets.all(10),
            ),
            content: const SizedBox(key: s.contentKey, width: 50, height: 500),
            child: const s.Anchor(),
          ),
        ),
      );
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();
      // The bubble is at most 100 tall, 20 of it padding.
      expect(tester.getSize(find.byKey(s.contentKey)).height, 80);
    });
  });

  testWidgets('clips the content to the bubble when asked', (tester) async {
    await tester.pumpWidget(
      s.app(
        s.popup(
          style: const ArrowPopupStyle(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    final geometry = s.layoutOf(tester).geometry!;
    expect(
      s.layoutOf(tester),
      paints..clipRRect(
        rrect: RRect.fromRectAndRadius(
          geometry.box,
          Radius.circular(geometry.radius),
        ),
      ),
    );
  });

  test('equal styles have equal hash codes', () {
    ArrowPopupStyle style() => ArrowPopupStyle(
      color: Colors.red,
      shadows: [const BoxShadow(blurRadius: 4)],
    );
    expect(style(), style());
    expect(style().hashCode, style().hashCode);
    expect(style().hashCode, isNot(style().copyWith(borderRadius: 3).hashCode));
    expect(style(), isNot(style().copyWith(maxWidth: 200)));
  });

  test('style rejects negative sizes', () {
    expect(() => ArrowPopupStyle(borderRadius: -1), throwsAssertionError);
    expect(() => ArrowPopupStyle(gap: -1), throwsAssertionError);
    expect(() => ArrowPopupStyle(screenMargin: -1), throwsAssertionError);
    expect(() => ArrowPopupStyle(maxWidth: -1), throwsAssertionError);
  });

  testWidgets('style rejects a negative arrow size or padding', (tester) async {
    for (final style in [
      const ArrowPopupStyle(arrowSize: Size(-1, 8)),
      const ArrowPopupStyle(padding: EdgeInsets.only(top: -1)),
    ]) {
      await tester.pumpWidget(s.app(s.popup(style: style)));
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pump();
      expect(tester.takeException(), isAssertionError);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('does not clip by default', (tester) async {
    await tester.pumpWidget(s.app(s.popup()));
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    expect(s.layoutOf(tester), isNot(paints..clipRRect()));
  });

  testWidgets('stays on screen after the screen size changes', (tester) async {
    addTearDown(tester.view.reset);
    Widget app() =>
        s.app(s.popup(contentWidth: 200), alignment: Alignment.centerRight);

    await tester.pumpWidget(app());
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(app());
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    final rect = tester.getRect(find.byKey(s.contentKey));
    expect(rect.right, lessThanOrEqualTo(400 - 10));
    expect(rect.left, greaterThanOrEqualTo(10));
  });

  testWidgets('follows the anchor when the screen resizes while open', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await tester.pumpWidget(s.app(s.popup()));
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpAndSettle();

    final anchor = tester.getRect(find.byKey(s.anchorKey));
    final content = tester.getRect(find.byKey(s.contentKey));
    expect(anchor.center.dx, moreOrLessEquals(200));
    expect(content.center.dx, moreOrLessEquals(anchor.center.dx));
    expect(content.top, greaterThan(anchor.bottom));
  });

  testWidgets('follows the anchor when the keyboard opens', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(s.app(s.popup()));
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    // The Scaffold shrinks its body, which moves the centered anchor up.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    final anchor = tester.getRect(find.byKey(s.anchorKey));
    final content = tester.getRect(find.byKey(s.contentKey));
    expect(anchor.center.dy, moreOrLessEquals(150));
    expect(content.top, greaterThan(anchor.bottom));
    expect(content.top, lessThan(anchor.bottom + 40));
    expect(content.bottom, lessThanOrEqualTo(600 - 300 - 10));
  });

  testWidgets('stays open when the keyboard hides an anchor in a list', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    var closed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              // Low enough for the keyboard to hide it, but within the list's
              // cache area, so the list keeps it built.
              const SizedBox(height: 500),
              ArrowPopup(
                onClose: (_) => closed++,
                content: const SizedBox(
                  width: 200,
                  child: TextField(key: s.contentKey),
                ),
                child: const s.Anchor(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(s.contentKey));
    await tester.pump();

    // The keyboard shrinks the Scaffold's body, so the list now clips the
    // anchor away. The popup is in use, so it stays, above the keyboard.
    tester.view.viewInsets = const FakeViewPadding(bottom: 400);
    await tester.pumpAndSettle();
    expect(closed, 0);
    expect(find.byKey(s.contentKey), findsOneWidget);
    expect(
      tester.getRect(find.byKey(s.contentKey)).bottom,
      lessThanOrEqualTo(800 - 400),
    );

    // Once the keyboard is gone, the anchor shows again and nothing closes.
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(closed, 0);
  });

  testWidgets('follows the anchor when it moves while open', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: scroll,
            children: [
              const SizedBox(height: 200),
              Center(child: s.popup()),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    scroll.jumpTo(100);
    await tester.pumpAndSettle();

    final anchor = tester.getRect(find.byKey(s.anchorKey));
    final geometry = s.layoutOf(tester).geometry!;
    expect(geometry.tip.dx, moreOrLessEquals(anchor.center.dx));
    expect(geometry.tip.dy, moreOrLessEquals(anchor.bottom + 2));
  });

  testWidgets('follows the anchor in the same frame it moves', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: scroll,
            children: [
              const SizedBox(height: 200),
              Center(child: s.popup()),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    final before = tester.getRect(find.byKey(s.contentKey));

    // A single frame, as while dragging a list.
    scroll.jumpTo(100);
    await tester.pump();

    final anchor = tester.getRect(find.byKey(s.anchorKey));
    final geometry = s.layoutOf(tester).geometry!;
    expect(geometry.tip.dx, moreOrLessEquals(anchor.center.dx));
    expect(geometry.tip.dy, moreOrLessEquals(anchor.bottom + 2));
    // The content is painted, and hit, where the bubble is now.
    final content = tester.getRect(find.byKey(s.contentKey));
    expect(content, before.shift(const Offset(0, -100)));
    bool hitsBubble(Offset position) => tester
        .hitTestOnBinding(position)
        .path
        .any((entry) => entry.target == s.layoutOf(tester));
    expect(hitsBubble(content.center), isTrue);
    expect(hitsBubble(before.center), isFalse);
  });

  testWidgets('a hover popup follows the anchor in the same frame', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: scroll,
            children: [
              const SizedBox(height: 200),
              Center(child: s.popup(trigger: ArrowPopupTrigger.hover)),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(find.byKey(s.anchorKey)));
    await tester.pumpAndSettle();
    final before = tester.getRect(find.byKey(s.contentKey));

    // Little enough that the mouse stays over the anchor.
    scroll.jumpTo(10);
    await tester.pump();

    final anchor = tester.getRect(find.byKey(s.anchorKey));
    expect(
      s.layoutOf(tester).geometry!.tip.dy,
      moreOrLessEquals(anchor.bottom + 2),
    );
    expect(
      tester.getRect(find.byKey(s.contentKey)),
      before.shift(const Offset(0, -10)),
    );
  });
}
