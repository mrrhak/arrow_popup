import 'dart:async';

import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support.dart' as s;

void main() {
  group('after Tab', () {
    bool anchorFocused(WidgetTester tester) =>
        Focus.of(tester.element(find.byKey(s.anchorKey))).hasFocus;

    Future<void> tabToAnchor(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(anchorFocused(tester), isTrue);
    }

    final gestures = <ArrowPopupTrigger, Future<void> Function(WidgetTester)>{
      ArrowPopupTrigger.tap: (tester) =>
          tester.tap(find.byKey(s.anchorKey), kind: PointerDeviceKind.mouse),
      ArrowPopupTrigger.longPress: (tester) => tester.longPress(
        find.byKey(s.anchorKey),
        kind: PointerDeviceKind.mouse,
      ),
      ArrowPopupTrigger.doubleTap: (tester) async {
        await tester.tap(
          find.byKey(s.anchorKey),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump(kDoubleTapMinTime);
        await tester.tap(
          find.byKey(s.anchorKey),
          kind: PointerDeviceKind.mouse,
        );
      },
    };
    for (final MapEntry(key: trigger, value: gesture) in gestures.entries) {
      testWidgets('a click with ${trigger.name} takes focus off the anchor', (
        tester,
      ) async {
        await tester.pumpWidget(s.app(s.popup(trigger: trigger)));
        await tabToAnchor(tester);

        await gesture(tester);
        await tester.pumpAndSettle();
        expect(find.byKey(s.contentKey), findsOneWidget);

        await tester.tapAt(const Offset(5, 5), kind: PointerDeviceKind.mouse);
        await tester.pumpAndSettle();
        expect(find.byKey(s.contentKey), findsNothing);
        expect(anchorFocused(tester), isFalse);
      });
    }

    testWidgets('Enter and Escape keep focus on the anchor', (tester) async {
      await tester.pumpWidget(s.app(s.popup()));
      await tabToAnchor(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsNothing);
      expect(anchorFocused(tester), isTrue);
    });
  });

  group('focusDecoration', () {
    Decoration decoration(WidgetTester tester) => tester
        .widget<DecoratedBox>(
          find.ancestor(
            of: find.byKey(s.anchorKey),
            matching: find.byType(DecoratedBox),
          ),
        )
        .decoration;

    Widget popup(Decoration focusDecoration) => s.app(
      ArrowPopup(
        focusDecoration: focusDecoration,
        content: const SizedBox(),
        child: const s.Anchor(),
      ),
    );

    testWidgets('replaces the outline while focused', (tester) async {
      const circle = ShapeDecoration(
        shape: CircleBorder(side: BorderSide(color: Colors.teal, width: 2)),
      );
      await tester.pumpWidget(popup(circle));
      expect(decoration(tester), const BoxDecoration());

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(decoration(tester), circle);
    });

    testWidgets('an empty BoxDecoration draws nothing', (tester) async {
      await tester.pumpWidget(popup(const BoxDecoration()));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      // Focused, but nothing shows.
      expect(
        Focus.of(tester.element(find.byKey(s.anchorKey))).hasFocus,
        isTrue,
      );
      expect(decoration(tester), const BoxDecoration());
    });

    for (final setting in ['focusable', 'trigger']) {
      testWidgets('is gone when $setting turns focus off and on again', (
        tester,
      ) async {
        const outline = BoxDecoration(color: Colors.teal);
        Widget popup({required bool on}) => s.app(
          ArrowPopup(
            focusable: setting != 'focusable' || on,
            trigger: setting != 'trigger' || on
                ? ArrowPopupTrigger.tap
                : ArrowPopupTrigger.none,
            focusDecoration: outline,
            content: const SizedBox(),
            child: const s.Anchor(),
          ),
        );
        await tester.pumpWidget(popup(on: true));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(decoration(tester), outline);

        await tester.pumpWidget(popup(on: false));
        await tester.pumpWidget(popup(on: true));
        await tester.pump();

        expect(
          Focus.of(tester.element(find.byKey(s.anchorKey))).hasFocus,
          isFalse,
        );
        expect(decoration(tester), const BoxDecoration());
      });
    }
  });

  testWidgets('the child keeps its state when trigger or focusable change', (
    tester,
  ) async {
    Widget popup(ArrowPopupTrigger trigger, bool focusable) => ArrowPopup(
      trigger: trigger,
      focusable: focusable,
      content: const SizedBox(),
      child: const s.StatefulChild(),
    );
    await tester.pumpWidget(s.app(popup(ArrowPopupTrigger.tap, true)));
    final state = tester.state(find.byType(s.StatefulChild));

    for (final (trigger, focusable) in [
      (ArrowPopupTrigger.tap, false),
      (ArrowPopupTrigger.doubleTap, false),
      (ArrowPopupTrigger.doubleTap, true),
      (ArrowPopupTrigger.none, true),
      (ArrowPopupTrigger.longPress, true),
    ]) {
      await tester.pumpWidget(s.app(popup(trigger, focusable)));
      expect(
        tester.state(find.byType(s.StatefulChild)),
        same(state),
        reason: '${trigger.name}, focusable: $focusable',
      );
    }
  });

  testWidgets('show explains an anchor that is not a box', (tester) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    final sliverKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            ArrowPopup(
              controller: controller,
              anchorKey: sliverKey,
              trigger: ArrowPopupTrigger.none,
              content: const SizedBox(),
              child: const s.Anchor(),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    key: sliverKey,
                    child: const SizedBox(height: 40),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await expectLater(
      controller.show(),
      throwsA(
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('not a laid-out box'),
        ),
      ),
    );
    expect(controller.isOpen, isFalse);
  });

  testWidgets('show explains an anchorKey that is not in the tree', (
    tester,
  ) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      s.app(
        ArrowPopup(
          controller: controller,
          // Never given to a widget, so it doesn't fall back to the child.
          anchorKey: GlobalKey(),
          trigger: ArrowPopupTrigger.none,
          content: const SizedBox(key: s.contentKey),
          child: const s.Anchor(),
        ),
      ),
    );

    await expectLater(
      controller.show(),
      throwsA(
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('anchorKey belongs to is not in the tree'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
    expect(find.byKey(s.contentKey), findsNothing);
  });

  for (final reduceMotion in [false, true]) {
    testWidgets('grows out of the arrow unless motion is reduced '
        '(reduced: $reduceMotion)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: Scaffold(body: Center(child: s.popup())),
        ),
      );

      await tester.tap(find.byKey(s.anchorKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      // As painted, with the scale.
      final size = tester.getRect(find.byKey(s.contentKey)).size;
      if (reduceMotion) {
        expect(size, const Size(100, 50));
      } else {
        expect(size.width, lessThan(100));
      }
    });
  }

  testWidgets('taps outside the growing bubble reach the barrier', (
    tester,
  ) async {
    await tester.pumpWidget(s.app(s.popup()));
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));

    // Inside the bubble's final shape, but far from the arrow, where the
    // bubble hasn't grown to yet.
    final box = s.layoutOf(tester).geometry!.box;
    await tester.tapAt(Offset(box.right - 12, box.bottom - 2));
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsNothing);
  });

  testWidgets('a throwing onOpen leaves the popup closed', (tester) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    var fail = true;
    await tester.pumpWidget(
      s.app(
        s.popup(
          controller: controller,
          onOpen: () {
            if (fail) throw StateError('onOpen');
          },
        ),
      ),
    );

    await expectLater(controller.show(), throwsStateError);
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
    expect(find.byKey(s.contentKey), findsNothing);

    fail = false;
    unawaited(controller.show());
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsOneWidget);
  });

  testWidgets('show from onOpen waits for the popup that is opening', (
    tester,
  ) async {
    final controller = ArrowPopupController<String>();
    addTearDown(controller.dispose);
    final observer = s.RecordingObserver();
    Future<String?>? nested;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Scaffold(
          body: Center(
            child: ArrowPopup<String>(
              controller: controller,
              onOpen: () => nested ??= controller.show(),
              content: Builder(
                builder: (context) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context, 'picked'),
                  child: const SizedBox(
                    key: s.contentKey,
                    width: 100,
                    height: 50,
                  ),
                ),
              ),
              child: const s.Anchor(),
            ),
          ),
        ),
      ),
    );
    observer.pushed.clear();

    final outer = controller.show();
    await tester.pumpAndSettle();
    expect(observer.pushed, hasLength(1));
    expect(find.byKey(s.contentKey), findsOneWidget);

    await tester.tap(find.byKey(s.contentKey));
    await tester.pumpAndSettle();
    expect(await outer, 'picked');
    expect(await nested, 'picked');
  });

  testWidgets('show from a throwing onOpen completes with null', (
    tester,
  ) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    Future<Object?>? nested;
    await tester.pumpWidget(
      s.app(
        s.popup(
          controller: controller,
          onOpen: () {
            nested = controller.show();
            throw StateError('onOpen');
          },
        ),
      ),
    );

    await expectLater(controller.show(), throwsStateError);
    expect(await nested, isNull);
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
  });
}
