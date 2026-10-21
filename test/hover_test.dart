import 'dart:async';

import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart' as s;

void main() {
  group('hover trigger', () {
    const away = Offset(5, 5);

    Future<TestGesture> mouseAt(WidgetTester tester, Offset location) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: location);
      await tester.pump();
      return mouse;
    }

    testWidgets('opens on hover and closes shortly after leaving', (
      tester,
    ) async {
      await tester.pumpWidget(s.app(s.popup(trigger: ArrowPopupTrigger.hover)));
      final mouse = await mouseAt(tester, away);
      expect(find.byKey(s.contentKey), findsNothing);

      await mouse.moveTo(tester.getCenter(find.byKey(s.anchorKey)));
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsOneWidget);

      await mouse.moveTo(away);
      await tester.pump();
      // Not yet, so the mouse can still reach the bubble.
      expect(find.byKey(s.contentKey), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsNothing);
    });

    testWidgets('stays open while the mouse is over the bubble', (
      tester,
    ) async {
      await tester.pumpWidget(s.app(s.popup(trigger: ArrowPopupTrigger.hover)));
      final mouse = await mouseAt(
        tester,
        tester.getCenter(find.byKey(s.anchorKey)),
      );
      await tester.pumpAndSettle();

      await mouse.moveTo(tester.getCenter(find.byKey(s.contentKey)));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsOneWidget);

      await mouse.moveTo(away);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsNothing);
    });

    testWidgets('show right after hide calls onClose before onOpen', (
      tester,
    ) async {
      final controller = ArrowPopupController();
      addTearDown(controller.dispose);
      final log = <String>[];
      await tester.pumpWidget(
        s.app(
          s.popup(
            controller: controller,
            trigger: ArrowPopupTrigger.hover,
            onOpen: () => log.add('open'),
            onClose: (_) => log.add('close'),
          ),
        ),
      );
      await mouseAt(tester, tester.getCenter(find.byKey(s.anchorKey)));
      await tester.pumpAndSettle();

      controller.hide();
      unawaited(controller.show());
      await tester.pumpAndSettle();
      expect(log, ['open', 'close', 'open']);
      expect(controller.isOpen, isTrue);
    });

    testWidgets('does not block taps or take focus', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var pressed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextButton(
                  focusNode: focus,
                  autofocus: true,
                  onPressed: () => pressed++,
                  child: const Text('other'),
                ),
                const SizedBox(height: 100),
                s.popup(trigger: ArrowPopupTrigger.hover),
              ],
            ),
          ),
        ),
      );
      final barriers = tester.widgetList(find.byType(ModalBarrier)).length;
      await mouseAt(tester, tester.getCenter(find.byKey(s.anchorKey)));
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsOneWidget);

      expect(focus.hasFocus, isTrue);
      expect(tester.widgetList(find.byType(ModalBarrier)).length, barriers);
      await tester.tap(find.text('other'));
      expect(pressed, 1);
    });

    testWidgets('opens on tap for touch, with the usual barrier', (
      tester,
    ) async {
      await tester.pumpWidget(s.app(s.popup(trigger: ArrowPopupTrigger.hover)));
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsOneWidget);

      await tester.tapAt(away);
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsNothing);
    });

    testWidgets('leaves a popup opened another way open', (tester) async {
      final controller = ArrowPopupController<Object?>();
      addTearDown(controller.dispose);
      var closed = 0;
      await tester.pumpWidget(
        s.app(
          s.popup(
            controller: controller,
            trigger: ArrowPopupTrigger.hover,
            onClose: (_) => closed++,
          ),
        ),
      );
      // The mouse rests on the anchor, which opens a hover popup.
      await mouseAt(tester, tester.getCenter(find.byKey(s.anchorKey)));
      await tester.pumpAndSettle();
      controller.hide();
      await tester.pumpAndSettle();
      expect(closed, 1);

      // Opened from code, it has a barrier, which covers the anchor as if
      // the mouse had left it. That must not close it.
      unawaited(controller.show());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      // Had it closed, the uncovered anchor would open a hover popup again,
      // so count the closes rather than look for the content.
      expect(closed, 1);
      expect(controller.isOpen, isTrue);
    });

    Widget autoClosing() => s.app(
      ArrowPopup(
        trigger: ArrowPopupTrigger.hover,
        autoCloseDuration: const Duration(seconds: 1),
        content: const SizedBox(key: s.contentKey, width: 100, height: 50),
        child: const s.Anchor(),
      ),
    );

    testWidgets('ignores autoCloseDuration when opened by the mouse', (
      tester,
    ) async {
      await tester.pumpWidget(autoClosing());
      final mouse = await mouseAt(
        tester,
        tester.getCenter(find.byKey(s.anchorKey)),
      );
      await tester.pumpAndSettle();
      await mouse.moveTo(tester.getCenter(find.byKey(s.contentKey)));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsOneWidget);
    });

    testWidgets('keeps autoCloseDuration when opened by tap', (tester) async {
      await tester.pumpWidget(autoClosing());
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsNothing);
    });

    testWidgets('keeps the normal mouse cursor', (tester) async {
      await tester.pumpWidget(s.app(s.popup(trigger: ArrowPopupTrigger.hover)));
      await mouseAt(tester, tester.getCenter(find.byKey(s.anchorKey)));
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.basic,
      );
    });

    testWidgets('a pop from the hovered button closes its screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    body: Center(
                      child: ArrowPopup(
                        trigger: ArrowPopupTrigger.hover,
                        focusable: false,
                        content: const SizedBox(
                          key: s.contentKey,
                          width: 100,
                          height: 50,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final back = tester.getCenter(find.byIcon(Icons.arrow_back));
      final mouse = await mouseAt(tester, back);
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsOneWidget);

      await mouse.down(back);
      await mouse.up();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byKey(s.contentKey), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('is not seen by navigator observers', (tester) async {
      final observer = s.RecordingObserver();
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Scaffold(
            body: Center(child: s.popup(trigger: ArrowPopupTrigger.hover)),
          ),
        ),
      );
      observer.pushed.clear();
      await mouseAt(tester, tester.getCenter(find.byKey(s.anchorKey)));
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsOneWidget);
      expect(observer.pushed, isEmpty);
    });

    testWidgets('ArrowPopup.close closes it with a value', (tester) async {
      final controller = ArrowPopupController<String>();
      addTearDown(controller.dispose);
      String? closedWith;
      await tester.pumpWidget(
        s.app(
          ArrowPopup<String>(
            controller: controller,
            trigger: ArrowPopupTrigger.hover,
            onClose: (value) => closedWith = value,
            content: Builder(
              builder: (context) => TextButton(
                onPressed: () => ArrowPopup.close(context, 'picked'),
                child: const Text('item'),
              ),
            ),
            child: const s.Anchor(),
          ),
        ),
      );
      final mouse = await mouseAt(
        tester,
        tester.getCenter(find.byKey(s.anchorKey)),
      );
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);

      await mouse.moveTo(tester.getCenter(find.text('item')));
      await mouse.down(tester.getCenter(find.text('item')));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(closedWith, 'picked');
      expect(controller.isOpen, isFalse);
      expect(find.text('item'), findsNothing);
    });

    group('closeDelay', () {
      Widget popup(Duration delay) => s.app(
        ArrowPopup(
          trigger: ArrowPopupTrigger.hover,
          closeDelay: delay,
          content: const SizedBox(key: s.contentKey, width: 100, height: 50),
          child: const s.Anchor(),
        ),
      );

      testWidgets('closes once the mouse has been away that long', (
        tester,
      ) async {
        const delay = Duration(seconds: 1);
        await tester.pumpWidget(popup(delay));
        final mouse = await mouseAt(
          tester,
          tester.getCenter(find.byKey(s.anchorKey)),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(s.contentKey), findsOneWidget);

        await mouse.moveTo(away);
        await tester.pump(delay - const Duration(milliseconds: 1));
        expect(find.byKey(s.contentKey), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 1));
        await tester.pumpAndSettle();
        expect(find.byKey(s.contentKey), findsNothing);
      });

      testWidgets('returning sooner keeps it open', (tester) async {
        const delay = Duration(seconds: 1);
        await tester.pumpWidget(popup(delay));
        final anchor = tester.getCenter(find.byKey(s.anchorKey));
        final mouse = await mouseAt(tester, anchor);
        await tester.pumpAndSettle();

        await mouse.moveTo(away);
        await tester.pump(delay ~/ 2);
        await mouse.moveTo(anchor);
        await tester.pump(delay * 2);
        await tester.pumpAndSettle();
        expect(find.byKey(s.contentKey), findsOneWidget);
      });
    });

    group('waitDuration', () {
      const wait = Duration(seconds: 1);

      Widget popup({VoidCallback? onOpen}) => s.app(
        ArrowPopup(
          trigger: ArrowPopupTrigger.hover,
          waitDuration: wait,
          onOpen: onOpen,
          content: const SizedBox(key: s.contentKey, width: 100, height: 50),
          child: const s.Anchor(),
        ),
      );

      testWidgets('opens once the mouse has rested that long', (tester) async {
        await tester.pumpWidget(popup());
        await mouseAt(tester, tester.getCenter(find.byKey(s.anchorKey)));
        await tester.pump(wait - const Duration(milliseconds: 1));
        expect(find.byKey(s.contentKey), findsNothing);

        await tester.pump(const Duration(milliseconds: 1));
        await tester.pumpAndSettle();
        expect(find.byKey(s.contentKey), findsOneWidget);
      });

      testWidgets('never opens when the mouse leaves sooner', (tester) async {
        var opened = 0;
        await tester.pumpWidget(popup(onOpen: () => opened++));
        final mouse = await mouseAt(tester, away);

        await mouse.moveTo(tester.getCenter(find.byKey(s.anchorKey)));
        await tester.pump(wait ~/ 2);
        await mouse.moveTo(away);
        await tester.pump(wait * 2);
        await tester.pumpAndSettle();
        expect(find.byKey(s.contentKey), findsNothing);
        expect(opened, 0);
      });

      testWidgets('starts over when the mouse comes back', (tester) async {
        await tester.pumpWidget(popup());
        final mouse = await mouseAt(tester, away);
        final anchor = tester.getCenter(find.byKey(s.anchorKey));

        await mouse.moveTo(anchor);
        await tester.pump(wait ~/ 2);
        await mouse.moveTo(away);
        await tester.pump();
        await mouse.moveTo(anchor);
        await tester.pump(wait ~/ 2 + const Duration(milliseconds: 100));
        expect(find.byKey(s.contentKey), findsNothing);

        await tester.pump(wait ~/ 2);
        await tester.pumpAndSettle();
        expect(find.byKey(s.contentKey), findsOneWidget);
      });

      testWidgets('a tap still opens right away', (tester) async {
        await tester.pumpWidget(popup());
        await tester.tap(find.byKey(s.anchorKey));
        await tester.pumpAndSettle();
        expect(find.byKey(s.contentKey), findsOneWidget);
      });

      testWidgets('removing the popup while waiting opens nothing', (
        tester,
      ) async {
        var opened = 0;
        await tester.pumpWidget(popup(onOpen: () => opened++));
        await mouseAt(tester, tester.getCenter(find.byKey(s.anchorKey)));
        await tester.pumpWidget(s.app(const SizedBox()));
        await tester.pump(wait * 2);
        expect(opened, 0);
      });
    });

    testWidgets('Escape closes it as a dismissal', (tester) async {
      final closed = <Object?>[];
      await tester.pumpWidget(
        s.app(s.popup(trigger: ArrowPopupTrigger.hover, onClose: closed.add)),
      );
      final anchor = tester.getRect(find.byKey(s.anchorKey));
      final mouse = await mouseAt(tester, anchor.center);
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsNothing);
      expect(closed, [null]);

      // The mouse is still over the anchor, but it hasn't entered it again.
      await mouse.moveTo(anchor.center + const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsNothing);
    });

    testWidgets('Escape that closes it goes no further', (tester) async {
      var escapes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): () =>
                    escapes++,
              },
              child: Column(
                children: [
                  const Focus(autofocus: true, child: Text('focused')),
                  const SizedBox(height: 100),
                  s.popup(trigger: ArrowPopupTrigger.hover),
                ],
              ),
            ),
          ),
        ),
      );
      await mouseAt(tester, tester.getCenter(find.byKey(s.anchorKey)));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsNothing);
      expect(escapes, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(escapes, 1);
    });

    testWidgets('closes when the trigger is no longer hover', (tester) async {
      var closed = 0;
      Widget popup(ArrowPopupTrigger trigger) =>
          s.app(s.popup(trigger: trigger, onClose: (_) => closed++));
      await tester.pumpWidget(popup(ArrowPopupTrigger.hover));
      await mouseAt(tester, tester.getCenter(find.byKey(s.anchorKey)));
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsOneWidget);

      await tester.pumpWidget(popup(ArrowPopupTrigger.tap));
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsNothing);
      expect(closed, 1);
    });

    testWidgets('closes with null when removed', (tester) async {
      final controller = ArrowPopupController<Object?>();
      addTearDown(controller.dispose);
      final closed = <Object?>[];
      await tester.pumpWidget(
        s.app(
          s.popup(
            controller: controller,
            trigger: ArrowPopupTrigger.hover,
            onClose: closed.add,
          ),
        ),
      );
      await mouseAt(tester, tester.getCenter(find.byKey(s.anchorKey)));
      await tester.pumpAndSettle();
      final result = controller.show();

      await tester.pumpWidget(s.app(const SizedBox()));
      await tester.pumpAndSettle();
      expect(await result, isNull);
      // Removed, so onClose isn't called.
      expect(closed, isEmpty);
      expect(controller.isOpen, isFalse);
    });
  });

  testWidgets('doubleTap trigger opens only on double tap', (tester) async {
    await tester.pumpWidget(
      s.app(s.popup(trigger: ArrowPopupTrigger.doubleTap)),
    );

    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle(kDoubleTapTimeout);
    expect(find.byKey(s.contentKey), findsNothing);

    await tester.tap(find.byKey(s.anchorKey));
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsOneWidget);
  });

  for (final trigger in [
    ArrowPopupTrigger.tap,
    ArrowPopupTrigger.longPress,
    ArrowPopupTrigger.doubleTap,
  ]) {
    testWidgets('screen readers can open the ${trigger.name} trigger', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(s.app(s.popup(trigger: trigger)));

      final node = tester.getSemantics(find.byKey(s.anchorKey));
      final action = trigger == ArrowPopupTrigger.longPress
          ? SemanticsAction.longPress
          : SemanticsAction.tap;
      node.owner!.performAction(node.id, action);
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsOneWidget);
      handle.dispose();
    });
  }

  for (final focusable in [true, false]) {
    testWidgets('shows a click cursor over the anchor '
        '(focusable: $focusable)', (tester) async {
      await tester.pumpWidget(
        s.app(
          ArrowPopup(
            focusable: focusable,
            content: const SizedBox(),
            child: const s.Anchor(),
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(
        location: tester.getCenter(find.byKey(s.anchorKey)),
      );
      await tester.pump();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click,
      );
    });
  }

  testWidgets('screen readers hear the anchor as a button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(s.app(s.popup()));
    expect(
      tester.getSemantics(find.byKey(s.anchorKey)),
      matchesSemantics(
        isButton: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('trigger none adds no cursor or button semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(s.app(s.popup(trigger: ArrowPopupTrigger.none)));
    expect(
      find.descendant(
        of: find.byType(ArrowPopup),
        matching: find.byType(MouseRegion),
      ),
      findsNothing,
    );
    expect(
      tester.getSemantics(find.byKey(s.anchorKey)),
      isNot(matchesSemantics(isButton: true)),
    );
    handle.dispose();
  });

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    testWidgets('keyboard focus and ${key.keyLabel} open the popup', (
      tester,
    ) async {
      await tester.pumpWidget(s.app(s.popup()));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(find.byKey(s.contentKey), findsOneWidget);
    });
  }

  testWidgets('Enter opens the popup with the web shortcuts', (tester) async {
    // On the web, Enter activates buttons only, with ButtonActivateIntent.
    await tester.pumpWidget(
      MaterialApp(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ButtonActivateIntent(),
        },
        home: Scaffold(body: Center(child: s.popup())),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsOneWidget);
  });

  testWidgets('focusable: false keeps the anchor out of focus', (tester) async {
    await tester.pumpWidget(
      s.app(
        ArrowPopup(
          focusable: false,
          content: const SizedBox(key: s.contentKey, width: 100, height: 50),
          child: const s.Anchor(),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsNothing);
  });

  testWidgets('keyboard focus outlines the anchor', (tester) async {
    await tester.pumpWidget(s.app(s.popup()));
    BoxDecoration decoration() =>
        tester
                .widget<DecoratedBox>(
                  find.ancestor(
                    of: find.byKey(s.anchorKey),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    expect(decoration().border, isNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      decoration().border,
      Border.all(
        color: Theme.of(tester.element(find.byKey(s.anchorKey)))
            .colorScheme
            .primary,
        width: 2,
      ),
    );
  });
}
