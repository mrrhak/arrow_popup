import 'dart:async';

import 'package:arrow_popup/arrow_popup.dart';
import 'package:arrow_popup/src/route/route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support.dart' as s;

void main() {
  group('when the anchor scrolls out of view', () {
    // A list that keeps the anchor alive however far it scrolls, inside a
    // 200px tall box in the middle of the screen.
    Widget scrollingApp(ScrollController scroll, ArrowPopupController popup) {
      return s.app(
        SizedBox(
          width: 300,
          height: 200,
          child: SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                const SizedBox(height: 50),
                s.popup(controller: popup),
                const SizedBox(height: 1000),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('stays open while part of the anchor shows', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final popup = ArrowPopupController();
      addTearDown(popup.dispose);
      await tester.pumpWidget(scrollingApp(scroll, popup));
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();

      // The 40px anchor starts 50px down, so 10px of it is still showing.
      scroll.jumpTo(80);
      await tester.pumpAndSettle();
      expect(popup.isOpen, isTrue);
      expect(find.byKey(s.contentKey), findsOneWidget);
    });

    testWidgets('closes once the scroll view clips it away', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final popup = ArrowPopupController();
      addTearDown(popup.dispose);
      await tester.pumpWidget(scrollingApp(scroll, popup));
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();

      // Still on screen, but above the top of the scroll view.
      scroll.jumpTo(100);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(s.anchorKey)).top, greaterThan(0));
      expect(popup.isOpen, isFalse);
      expect(find.byKey(s.contentKey), findsNothing);
    });

    testWidgets('ArrowPopup.show closes with null too', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      late BuildContext anchorContext;
      await tester.pumpWidget(
        s.app(
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              controller: scroll,
              child: Column(
                children: [
                  Builder(
                    builder: (context) {
                      anchorContext = context;
                      return const SizedBox(width: 40, height: 40);
                    },
                  ),
                  const SizedBox(height: 1000),
                ],
              ),
            ),
          ),
        ),
      );
      final result = ArrowPopup.show<int>(
        context: anchorContext,
        content: const SizedBox(key: s.contentKey, width: 100, height: 50),
      );
      await tester.pumpAndSettle();

      scroll.jumpTo(500);
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsNothing);
      expect(await result, isNull);
    });

    testWidgets('does not open while it is hidden', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final popup = ArrowPopupController();
      addTearDown(popup.dispose);
      await tester.pumpWidget(scrollingApp(scroll, popup));
      scroll.jumpTo(100);
      await tester.pumpAndSettle();

      await expectLater(
        popup.show(),
        throwsA(
          isAssertionError.having(
            (e) => e.message,
            'message',
            contains('no part of its anchor is visible'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(popup.isOpen, isFalse);
      expect(find.byKey(s.contentKey), findsNothing);
    });

    testWidgets('ArrowPopup.show does not open while it is hidden', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final popup = ArrowPopupController();
      addTearDown(popup.dispose);
      await tester.pumpWidget(scrollingApp(scroll, popup));
      scroll.jumpTo(100);
      await tester.pumpAndSettle();

      expect(
        () => ArrowPopup.show<void>(
          context: tester.element(find.byKey(s.anchorKey)),
          content: const SizedBox(key: s.contentKey),
        ),
        throwsA(
          isAssertionError.having(
            (e) => e.message,
            'message',
            contains('not visible'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsNothing);
    });
  });

  testWidgets('anchorKey points the arrow at another widget', (tester) async {
    final target = GlobalKey();
    await tester.pumpWidget(
      s.app(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ArrowPopup(
              anchorKey: target,
              content: const SizedBox(
                key: s.contentKey,
                width: 100,
                height: 50,
              ),
              child: const s.Anchor(),
            ),
            const SizedBox(width: 200),
            SizedBox(key: target, width: 40, height: 40),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    final targetRect = tester.getRect(find.byKey(target));
    expect(
      s.layoutOf(tester).geometry!.tip.dx,
      moreOrLessEquals(targetRect.center.dx),
    );
  });

  testWidgets('anchorKey can point outside a nested navigator', (tester) async {
    final target = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            SizedBox(key: target, width: 40, height: 40),
            Expanded(
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute(
                  builder: (_) => Theme(
                    data: ThemeData(
                      colorScheme: const ColorScheme.light(
                        surfaceContainer: Color(0xFF123456),
                      ),
                    ),
                    child: Center(
                      child: ArrowPopup(
                        anchorKey: target,
                        style: const ArrowPopupStyle(shadows: []),
                        content: const SizedBox(
                          key: s.contentKey,
                          width: 100,
                          height: 50,
                        ),
                        child: const s.Anchor(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(s.contentKey), findsOneWidget);
    final targetRect = tester.getRect(find.byKey(target));
    expect(
      s.layoutOf(tester).geometry!.tip.dx,
      moreOrLessEquals(targetRect.center.dx),
    );
    // Themes come from where the ArrowPopup is, not from the anchor.
    expect(s.layoutOf(tester), paints..path(color: const Color(0xFF123456)));
  });

  group('autoCloseDuration', () {
    Widget popup({
      Duration autoCloseDuration = Duration.zero,
      ArrowPopupController<String>? controller,
      ValueChanged<String?>? onClose,
    }) {
      return s.app(
        ArrowPopup<String>(
          controller: controller,
          autoCloseDuration: autoCloseDuration,
          onClose: onClose,
          content: const SizedBox(key: s.contentKey, width: 100, height: 50),
          child: const s.Anchor(),
        ),
      );
    }

    testWidgets('closes the popup after the duration, as a dismissal', (
      tester,
    ) async {
      var closes = 0;
      String? closedWith = 'unset';
      await tester.pumpWidget(
        popup(
          autoCloseDuration: const Duration(seconds: 2),
          onClose: (value) {
            closes++;
            closedWith = value;
          },
        ),
      );
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 1900));
      expect(find.byKey(s.contentKey), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsNothing);
      expect(closes, 1);
      expect(closedWith, isNull);
    });

    testWidgets('cancels the timer when dismissed first', (tester) async {
      await tester.pumpWidget(
        popup(autoCloseDuration: const Duration(seconds: 2)),
      );
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();
      final route =
          ModalRoute.of(tester.element(find.byKey(s.contentKey)))!
              as ArrowPopupRoute<String>;
      expect(route.debugAutoClosePending, isTrue);

      // A tap outside closes it. The timer stops right away, not once the
      // close animation is over.
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(route.isActive, isFalse);
      expect(route.debugAutoClosePending, isFalse);
      await tester.pumpAndSettle();
    });

    testWidgets('cancels the timer when the content pops', (tester) async {
      await tester.pumpWidget(
        s.app(
          ArrowPopup<String>(
            autoCloseDuration: const Duration(seconds: 2),
            content: Builder(
              builder: (context) => TextButton(
                key: s.contentKey,
                onPressed: () => Navigator.pop(context, 'done'),
                child: const Text('done'),
              ),
            ),
            child: const s.Anchor(),
          ),
        ),
      );
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();
      final route =
          ModalRoute.of(tester.element(find.byKey(s.contentKey)))!
              as ArrowPopupRoute<String>;

      await tester.tap(find.text('done'));
      await tester.pump();
      expect(route.debugAutoClosePending, isFalse);
      await tester.pumpAndSettle();
    });

    testWidgets('stays open by default', (tester) async {
      await tester.pumpWidget(popup());
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(hours: 1));
      expect(find.byKey(s.contentKey), findsOneWidget);
    });

    testWidgets('times each popup on its own', (tester) async {
      final controller = ArrowPopupController<String>();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        popup(
          controller: controller,
          autoCloseDuration: const Duration(seconds: 2),
        ),
      );

      unawaited(controller.show());
      await tester.pump(const Duration(seconds: 1));
      controller.hide();
      await tester.pumpAndSettle();
      unawaited(controller.show());
      await tester.pump();

      // The first popup's time is up, but this one has a second left.
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byKey(s.contentKey), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsNothing);
    });

    testWidgets('ArrowPopup.show completes with null', (tester) async {
      late Future<String?> result;
      await tester.pumpWidget(
        s.app(
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => result = ArrowPopup.show<String>(
                context: context,
                autoCloseDuration: const Duration(seconds: 1),
                content: const SizedBox(key: s.contentKey),
              ),
              child: const s.Anchor(),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsNothing);
      expect(await result, isNull);
    });

    testWidgets('rejects a negative duration', (tester) async {
      final controller = ArrowPopupController<String>();
      addTearDown(controller.dispose);
      late BuildContext anchorContext;
      await tester.pumpWidget(
        s.app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ArrowPopup<String>(
                controller: controller,
                autoCloseDuration: const Duration(seconds: -1),
                content: const SizedBox(),
                child: const s.Anchor(),
              ),
              Builder(
                builder: (context) {
                  anchorContext = context;
                  return const SizedBox(width: 40, height: 40);
                },
              ),
            ],
          ),
        ),
      );

      await expectLater(controller.show(), throwsAssertionError);
      expect(
        () => ArrowPopup.show<void>(
          context: anchorContext,
          autoCloseDuration: const Duration(seconds: -1),
          content: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });
  });

  testWidgets('barrierDismissible: false keeps it open on outside taps', (
    tester,
  ) async {
    await tester.pumpWidget(
      s.app(
        const ArrowPopup(
          barrierDismissible: false,
          content: SizedBox(key: s.contentKey, width: 100, height: 50),
          child: s.Anchor(),
        ),
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsOneWidget);
  });

  testWidgets('useRootNavigator shows the popup above a nested navigator', (
    tester,
  ) async {
    final nested = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          key: nested,
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: ArrowPopup(
                  useRootNavigator: true,
                  content: SizedBox(key: s.contentKey, width: 100, height: 50),
                  child: s.Anchor(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    expect(find.byKey(s.contentKey), findsOneWidget);
    // Nothing was pushed on the nested navigator.
    expect(nested.currentState!.canPop(), isFalse);
  });

  testWidgets('showArrow: false puts the bubble right after the gap', (
    tester,
  ) async {
    await tester.pumpWidget(
      s.app(s.popup(style: const ArrowPopupStyle(showArrow: false))),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    final anchor = tester.getRect(find.byKey(s.anchorKey));
    final geometry = s.layoutOf(tester).geometry!;
    expect(geometry.arrowSize, Size.zero);
    expect(geometry.box.top, moreOrLessEquals(anchor.bottom + 2));
  });

  for (final placement in [
    ArrowPopupPlacement.left,
    ArrowPopupPlacement.right,
  ]) {
    testWidgets('placement ${placement.name} opens beside the anchor', (
      tester,
    ) async {
      await tester.pumpWidget(s.app(s.popup(placement: placement)));
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();

      final anchor = tester.getRect(find.byKey(s.anchorKey));
      final content = tester.getRect(find.byKey(s.contentKey));
      expect(content.center.dy, moreOrLessEquals(anchor.center.dy));
      if (placement == ArrowPopupPlacement.left) {
        expect(content.right, lessThan(anchor.left));
      } else {
        expect(content.left, greaterThan(anchor.right));
      }
      final tip = s.layoutOf(tester).geometry!.tip;
      expect(tip.dy, moreOrLessEquals(anchor.center.dy));
    });
  }

  testWidgets('an open popup moves when placement changes', (tester) async {
    await tester.pumpWidget(s.app(s.popup()));
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    expect(s.layoutOf(tester).geometry!.side, AxisDirection.down);

    await tester.pumpWidget(
      s.app(s.popup(placement: ArrowPopupPlacement.above)),
    );
    await tester.pumpAndSettle();
    final anchor = tester.getRect(find.byKey(s.anchorKey));
    final content = tester.getRect(find.byKey(s.contentKey));
    expect(content.bottom, lessThan(anchor.top));
  });

  testWidgets('hide works when another route is on top of the popup', (
    tester,
  ) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      s.app(
        ArrowPopup(
          controller: controller,
          content: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const Text('dialog'),
              ),
              child: const Text('more'),
            ),
          ),
          child: const s.Anchor(),
        ),
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('more'));
    await tester.pumpAndSettle();

    controller.hide();
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
    expect(find.text('more'), findsNothing);
    expect(find.text('dialog'), findsOneWidget);
  });
}
