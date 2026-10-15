import 'dart:async';

import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support.dart' as s;

void main() {
  group('anchor tooltip for screen readers', () {
    Widget popup(ArrowPopupTrigger trigger, {String? semanticLabel}) {
      return s.app(
        ArrowPopup(
          trigger: trigger,
          semanticLabel: semanticLabel,
          content: const SizedBox(key: s.contentKey, width: 100, height: 50),
          child: const s.Anchor(),
        ),
      );
    }

    testWidgets('a hover anchor reads semanticLabel as its tooltip', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        popup(ArrowPopupTrigger.hover, semanticLabel: 'Bold'),
      );
      // Without hovering: screen readers hear it when they reach the anchor.
      expect(
        tester.getSemantics(find.byKey(s.anchorKey)).getSemanticsData().tooltip,
        'Bold',
      );
      handle.dispose();
    });

    testWidgets('a hover anchor without semanticLabel has no tooltip', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(popup(ArrowPopupTrigger.hover));
      expect(
        tester.getSemantics(find.byKey(s.anchorKey)).getSemanticsData().tooltip,
        isEmpty,
      );
      handle.dispose();
    });

    testWidgets('other triggers keep semanticLabel for the open popup only', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        popup(ArrowPopupTrigger.tap, semanticLabel: 'Options'),
      );
      expect(
        tester.getSemantics(find.byKey(s.anchorKey)).getSemanticsData().tooltip,
        isEmpty,
      );
      handle.dispose();
    });
  });

  for (final useFunction in [false, true]) {
    testWidgets('screen readers hear the popup open '
        '(${useFunction ? 'ArrowPopup.show' : 'ArrowPopup'})', (tester) async {
      final handle = tester.ensureSemantics();
      const content = SizedBox(key: s.contentKey, width: 100, height: 50);
      await tester.pumpWidget(
        s.app(
          useFunction
              ? Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => ArrowPopup.show<void>(
                      context: context,
                      semanticLabel: 'Options',
                      content: content,
                    ),
                    child: const s.Anchor(),
                  ),
                )
              : const ArrowPopup(
                  semanticLabel: 'Options',
                  content: content,
                  child: s.Anchor(),
                ),
        ),
      );

      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.byKey(s.contentKey)),
        matchesSemantics(label: 'Options', scopesRoute: true, namesRoute: true),
      );
      handle.dispose();
    });
  }

  testWidgets('ArrowPopup.show returns the popped value', (tester) async {
    late Future<String?> result;
    await tester.pumpWidget(
      s.app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => result = ArrowPopup.show<String>(
              context: context,
              content: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.pop(context, 'picked'),
                  child: const Text('item'),
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
    await tester.tap(find.text('item'));
    await tester.pumpAndSettle();
    expect(await result, 'picked');
  });

  group('ArrowPopup result', () {
    Widget menu(
      ArrowPopupController<String> controller, {
      ValueChanged<String?>? onClose,
    }) {
      return s.app(
        ArrowPopup<String>(
          controller: controller,
          onClose: onClose,
          content: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.pop(context, 'picked'),
              child: const Text('item'),
            ),
          ),
          child: const s.Anchor(),
        ),
      );
    }

    testWidgets('show and onClose get the popped value', (tester) async {
      final controller = ArrowPopupController<String>();
      addTearDown(controller.dispose);
      String? closedWith;
      await tester.pumpWidget(menu(controller, onClose: (v) => closedWith = v));

      final result = controller.show();
      // A second show while open gets the same value.
      final again = controller.show();
      await tester.pumpAndSettle();
      await tester.tap(find.text('item'));
      await tester.pumpAndSettle();
      expect(await result, 'picked');
      expect(await again, 'picked');
      expect(closedWith, 'picked');
    });

    testWidgets('a dismissed popup gives null', (tester) async {
      final controller = ArrowPopupController<String>();
      addTearDown(controller.dispose);
      var closedWith = 'unset' as String?;
      await tester.pumpWidget(menu(controller, onClose: (v) => closedWith = v));

      final result = controller.show();
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(await result, isNull);
      expect(closedWith, isNull);
    });

    testWidgets('a tap trigger also reports the value', (tester) async {
      String? closedWith;
      await tester.pumpWidget(
        s.app(
          ArrowPopup<int>(
            onClose: (v) => closedWith = '$v',
            content: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.pop(context, 7),
                child: const Text('seven'),
              ),
            ),
            child: const s.Anchor(),
          ),
        ),
      );

      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('seven'));
      await tester.pumpAndSettle();
      expect(closedWith, '7');
    });
  });

  group('ArrowPopup.builder', () {
    const buttonKey = Key('button');

    Widget menu({
      ArrowPopupController<String>? controller,
      ValueChanged<String?>? onClose,
      ValueChanged<Future<String?>>? onShown,
    }) {
      return s.app(
        ArrowPopup<String>.builder(
          controller: controller,
          onClose: onClose,
          content: Builder(
            builder: (context) => TextButton(
              onPressed: () => ArrowPopup.close(context, 'picked'),
              child: const Text('item'),
            ),
          ),
          builder: (context, show) => TextButton(
            key: buttonKey,
            onPressed: onShown == null ? show : () => onShown(show()),
            child: const Text('open'),
          ),
        ),
      );
    }

    testWidgets('the built button opens the popup', (tester) async {
      await tester.pumpWidget(menu());
      await tester.tap(find.byKey(buttonKey));
      await tester.pumpAndSettle();
      expect(find.text('item'), findsOneWidget);
    });

    testWidgets('show completes with the closing value', (tester) async {
      Future<String?>? result;
      String? closedWith;
      await tester.pumpWidget(
        menu(onShown: (r) => result = r, onClose: (v) => closedWith = v),
      );

      await tester.tap(find.byKey(buttonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('item'));
      await tester.pumpAndSettle();
      expect(await result, 'picked');
      expect(closedWith, 'picked');
    });

    testWidgets('points the arrow at the built widget', (tester) async {
      await tester.pumpWidget(menu());
      await tester.tap(find.byKey(buttonKey));
      await tester.pumpAndSettle();

      final button = tester.getRect(find.byKey(buttonKey));
      expect(s.layoutOf(tester).geometry!.tip.dx, closeTo(button.center.dx, 1));
    });

    testWidgets('adds no gesture detector or focus stop of its own', (
      tester,
    ) async {
      await tester.pumpWidget(menu());
      final popup = find.byType(ArrowPopup<String>);
      expect(
        find.descendant(
          of: popup,
          matching: find.byType(FocusableActionDetector),
        ),
        findsNothing,
      );
      // Only the button's own detector.
      expect(
        find.descendant(of: popup, matching: find.byType(GestureDetector)),
        findsOneWidget,
      );
    });

    testWidgets('works with a controller', (tester) async {
      final controller = ArrowPopupController<String>();
      addTearDown(controller.dispose);
      await tester.pumpWidget(menu(controller: controller));

      await tester.tap(find.byKey(buttonKey));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);

      controller.hide();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(find.text('item'), findsNothing);
    });
  });

  group('ArrowPopup.close', () {
    Widget item(String value) => Builder(
      builder: (context) => TextButton(
        onPressed: () => ArrowPopup.close(context, value),
        child: const Text('item'),
      ),
    );

    testWidgets('gives ArrowPopup its value', (tester) async {
      final controller = ArrowPopupController<String>();
      addTearDown(controller.dispose);
      String? closedWith;
      await tester.pumpWidget(
        s.app(
          ArrowPopup<String>(
            controller: controller,
            onClose: (value) => closedWith = value,
            content: item('picked'),
            child: const s.Anchor(),
          ),
        ),
      );

      final result = controller.show();
      await tester.pumpAndSettle();
      await tester.tap(find.text('item'));
      await tester.pumpAndSettle();
      expect(await result, 'picked');
      expect(closedWith, 'picked');
      expect(find.text('item'), findsNothing);
    });

    testWidgets('gives ArrowPopup.show its value', (tester) async {
      late Future<String?> result;
      await tester.pumpWidget(
        s.app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => result = ArrowPopup.show<String>(
                context: context,
                content: item('picked'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('item'));
      await tester.pumpAndSettle();
      expect(await result, 'picked');
    });

    testWidgets('closes only its popup when a route is above it', (
      tester,
    ) async {
      late Future<String?> result;
      late BuildContext itemContext;
      await tester.pumpWidget(
        s.app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => result = ArrowPopup.show<String>(
                context: context,
                content: Builder(
                  builder: (context) {
                    itemContext = context;
                    return const SizedBox(width: 100, height: 50);
                  },
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      unawaited(
        showDialog<void>(
          context: itemContext,
          builder: (_) => const Text('dialog'),
        ),
      );
      await tester.pumpAndSettle();

      ArrowPopup.close(itemContext, 'picked');
      await tester.pumpAndSettle();
      expect(await result, 'picked');
      expect(find.text('dialog'), findsOneWidget);
    });

    testWidgets('asserts with a value of another type', (tester) async {
      final controller = ArrowPopupController<String>();
      addTearDown(controller.dispose);
      late BuildContext itemContext;
      await tester.pumpWidget(
        s.app(
          ArrowPopup<String>(
            controller: controller,
            content: Builder(
              builder: (context) {
                itemContext = context;
                return const SizedBox(width: 100, height: 50);
              },
            ),
            child: const s.Anchor(),
          ),
        ),
      );
      unawaited(controller.show());
      await tester.pumpAndSettle();

      expect(
        () => ArrowPopup.close(itemContext, 42),
        throwsA(
          isAssertionError.having(
            (e) => e.message,
            'message',
            contains('value of type int, but the popup closes with String'),
          ),
        ),
      );
      expect(controller.isOpen, isTrue);
    });

    testWidgets('asserts outside a popup', (tester) async {
      await tester.pumpWidget(s.app(const s.Anchor()));
      expect(
        () => ArrowPopup.close(tester.element(find.byKey(s.anchorKey))),
        throwsAssertionError,
      );
    });
  });
}
