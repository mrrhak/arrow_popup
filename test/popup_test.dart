import 'dart:async';

import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support.dart' as s;

void main() {
  testWidgets('tapping the anchor opens and the barrier closes', (
    tester,
  ) async {
    var opened = 0;
    var closed = 0;
    await tester.pumpWidget(
      s.app(s.popup(onOpen: () => opened++, onClose: (_) => closed++)),
    );

    expect(find.byKey(s.contentKey), findsNothing);
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsOneWidget);
    expect(opened, 1);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsNothing);
    expect(closed, 1);
  });

  testWidgets('an open popup updates when ArrowPopup rebuilds', (tester) async {
    var count = 0;
    await tester.pumpWidget(
      s.app(
        StatefulBuilder(
          builder: (context, setState) => ArrowPopup(
            style: ArrowPopupStyle(
              color: count.isEven ? Colors.white : Colors.black,
              shadows: const [],
            ),
            content: TextButton(
              onPressed: () => setState(() => count++),
              child: Text('count $count'),
            ),
            child: const s.Anchor(),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('count 0'));
    await tester.pumpAndSettle();

    expect(find.text('count 1'), findsOneWidget);
    expect(s.layoutOf(tester), paints..path(color: Colors.black));
  });

  testWidgets('calls the latest onClose', (tester) async {
    var closedBy = '';
    await tester.pumpWidget(s.app(s.popup(onClose: (_) => closedBy = 'old')));
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    await tester.pumpWidget(s.app(s.popup(onClose: (_) => closedBy = 'new')));
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(closedBy, 'new');
  });

  testWidgets('closes when the ArrowPopup is removed', (tester) async {
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    final controller = ArrowPopupController<Object?>();
    addTearDown(controller.dispose);
    var closed = 0;
    await tester.pumpWidget(
      s.app(
        ValueListenableBuilder(
          valueListenable: visible,
          builder: (context, show, _) => show
              ? s.popup(controller: controller, onClose: (_) => closed++)
              : const SizedBox(),
        ),
      ),
    );
    final result = controller.show();
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsOneWidget);

    visible.value = false;
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsNothing);
    // Removed, so onClose isn't called, as with PopupMenuButton, but show
    // still completes.
    expect(closed, 0);
    expect(await result, isNull);
  });

  testWidgets('Escape closes the popup', (tester) async {
    var closed = 0;
    await tester.pumpWidget(s.app(s.popup(onClose: (_) => closed++)));
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsNothing);
    expect(closed, 1);
  });

  testWidgets('tapping the bubble itself does not close it', (tester) async {
    await tester.pumpWidget(s.app(s.popup()));
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    // Inside the padding, outside the content.
    final content = tester.getRect(find.byKey(s.contentKey));
    await tester.tapAt(content.bottomLeft + const Offset(2, 4));
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsOneWidget);
  });

  testWidgets('controller shows and hides the popup', (tester) async {
    final controller = ArrowPopupController();
    await tester.pumpWidget(
      s.app(s.popup(controller: controller, trigger: ArrowPopupTrigger.none)),
    );

    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsNothing);
    expect(controller.isOpen, isFalse);

    unawaited(controller.show());
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsOneWidget);
    expect(controller.isOpen, isTrue);

    controller.hide();
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsNothing);
    expect(controller.isOpen, isFalse);
  });

  testWidgets('controller toggle opens and closes the popup', (tester) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      s.app(s.popup(controller: controller, trigger: ArrowPopupTrigger.none)),
    );

    final opened = controller.toggle();
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsOneWidget);
    expect(controller.isOpen, isTrue);

    final closed = controller.toggle();
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsNothing);
    expect(controller.isOpen, isFalse);
    expect(await opened, isNull);
    expect(await closed, isNull);

    unawaited(controller.toggle());
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsOneWidget);
  });

  testWidgets('controller show right after hide opens it again', (
    tester,
  ) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      s.app(s.popup(controller: controller, trigger: ArrowPopupTrigger.none)),
    );
    var firstResult = 'pending';
    unawaited(controller.show().then((value) => firstResult = '$value'));
    await tester.pumpAndSettle();

    controller.hide();
    expect(controller.isOpen, isFalse);
    var secondDone = false;
    unawaited(controller.show().then((_) => secondDone = true));
    await tester.pumpAndSettle();
    expect(firstResult, 'null');
    expect(find.byKey(s.contentKey), findsOneWidget);
    expect(controller.isOpen, isTrue);
    expect(secondDone, isFalse);

    controller.hide();
    await tester.pumpAndSettle();
    expect(secondDone, isTrue);
    expect(controller.isOpen, isFalse);
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
          trigger: ArrowPopupTrigger.none,
          onOpen: () => log.add('open'),
          onClose: (_) => log.add('close'),
        ),
      ),
    );
    unawaited(controller.show());
    await tester.pumpAndSettle();

    controller.hide();
    unawaited(controller.show());
    await tester.pumpAndSettle();
    expect(log, ['open', 'close', 'open']);
    expect(controller.isOpen, isTrue);
  });

  testWidgets('hide, show, hide calls each callback in order', (tester) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    final log = <String>[];
    await tester.pumpWidget(
      s.app(
        s.popup(
          controller: controller,
          trigger: ArrowPopupTrigger.none,
          onOpen: () => log.add('open'),
          onClose: (_) => log.add('close'),
        ),
      ),
    );
    unawaited(controller.show());
    await tester.pumpAndSettle();

    controller.hide();
    Object? result = 'pending';
    unawaited(controller.show().then((value) => result = value));
    controller.hide();
    await tester.pumpAndSettle();
    expect(log, ['open', 'close', 'open', 'close']);
    expect(result, isNull);
    expect(find.byKey(s.contentKey), findsNothing);
    expect(controller.isOpen, isFalse);
  });

  testWidgets('hide from onOpen keeps the popup closed', (tester) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    final log = <String>[];
    await tester.pumpWidget(
      s.app(
        s.popup(
          controller: controller,
          trigger: ArrowPopupTrigger.none,
          onOpen: () {
            log.add('open');
            controller.hide();
          },
          onClose: (value) => log.add('close $value'),
        ),
      ),
    );
    Object? result = 'pending';
    unawaited(controller.show().then((value) => result = value));
    await tester.pumpAndSettle();
    expect(log, ['open', 'close null']);
    expect(result, isNull);
    expect(find.byKey(s.contentKey), findsNothing);
    expect(controller.isOpen, isFalse);

    // It can be shown again afterwards.
    log.clear();
    controller.hide();
    expect(log, isEmpty);
  });

  testWidgets('hide then show from onOpen opens it once', (tester) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    final log = <String>[];
    var first = true;
    await tester.pumpWidget(
      s.app(
        s.popup(
          controller: controller,
          trigger: ArrowPopupTrigger.none,
          onOpen: () {
            log.add('open');
            if (!first) return;
            first = false;
            controller.hide();
            unawaited(controller.show());
          },
          onClose: (_) => log.add('close'),
        ),
      ),
    );
    unawaited(controller.show());
    await tester.pumpAndSettle();
    expect(log, ['open', 'close', 'open']);
    expect(find.byKey(s.contentKey), findsOneWidget);
    expect(controller.isOpen, isTrue);
  });

  testWidgets('controller of a narrower type asserts with both types', (
    tester,
  ) async {
    final controller = ArrowPopupController<String>();
    addTearDown(controller.dispose);
    // Older Flutter versions follow the failed build with more errors from
    // the half-built tree, so only the first one is checked.
    final onError = FlutterError.onError;
    final errors = <Object>[];
    FlutterError.onError = (details) => errors.add(details.exception);
    await tester.pumpWidget(
      s.app(
        ArrowPopup<String?>(
          controller: controller,
          trigger: ArrowPopupTrigger.none,
          content: const SizedBox(key: s.contentKey, width: 100, height: 50),
          child: const s.Anchor(),
        ),
      ),
    );
    FlutterError.onError = onError;
    expect(errors, isNotEmpty);
    expect(errors.first, isAssertionError);
    expect(
      '${errors.first}',
      allOf(
        contains('ArrowPopup<String?>'),
        contains('ArrowPopupController<String>'),
      ),
    );
  });

  test('controller without an ArrowPopup asserts on show', () {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    expect(controller.show, throwsAssertionError);
    // Hiding what isn't open is harmless, so it stays quiet.
    controller.hide();
  });

  testWidgets('controller moves to an ArrowPopup that replaces its own', (
    tester,
  ) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    Widget app(int key) => s.app(
      ArrowPopup(
        key: ValueKey(key),
        controller: controller,
        trigger: ArrowPopupTrigger.none,
        content: const SizedBox(key: s.contentKey, width: 100, height: 50),
        child: const s.Anchor(),
      ),
    );

    await tester.pumpWidget(app(1));
    await tester.pumpWidget(app(2));
    expect(tester.takeException(), isNull);

    unawaited(controller.show());
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsOneWidget);
  });

  testWidgets('controller moves to another ArrowPopup in the same rebuild', (
    tester,
  ) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    // The ArrowPopup receiving the controller updates before the one giving
    // it up, which is still in the tree afterwards.
    Widget app({required bool toFirst}) => s.app(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ArrowPopup(
            controller: toFirst ? controller : null,
            trigger: ArrowPopupTrigger.none,
            content: const SizedBox(key: s.contentKey, width: 100, height: 50),
            child: const s.Anchor(),
          ),
          ArrowPopup(
            controller: toFirst ? null : controller,
            trigger: ArrowPopupTrigger.none,
            content: const SizedBox(),
            child: const SizedBox(width: 40, height: 40),
          ),
        ],
      ),
    );

    await tester.pumpWidget(app(toFirst: false));
    await tester.pumpWidget(app(toFirst: true));
    await tester.pump();
    expect(tester.takeException(), isNull);

    unawaited(controller.show());
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsOneWidget);
  });

  testWidgets('controller rejects two ArrowPopups at once', (tester) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      s.app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ArrowPopup(
              controller: controller,
              content: const SizedBox(),
              child: const SizedBox(width: 40, height: 40),
            ),
            ArrowPopup(
              controller: controller,
              content: const SizedBox(),
              child: const SizedBox(width: 40, height: 40),
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('a button child opens the popup through the controller', (
    tester,
  ) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      s.app(
        ArrowPopup(
          controller: controller,
          trigger: ArrowPopupTrigger.none,
          content: const SizedBox(key: s.contentKey, width: 100, height: 50),
          child: IconButton(
            key: s.anchorKey,
            onPressed: controller.show,
            icon: const Icon(Icons.info_outline),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsOneWidget);
  });

  testWidgets('show while already open completes when it closes', (
    tester,
  ) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(s.app(s.popup(controller: controller)));
    var firstDone = false;
    var secondDone = false;
    unawaited(controller.show().then((_) => firstDone = true));
    await tester.pumpAndSettle();

    unawaited(controller.show().then((_) => secondDone = true));
    await tester.pumpAndSettle();
    expect(secondDone, isFalse);

    controller.hide();
    await tester.pumpAndSettle();
    expect(firstDone, isTrue);
    expect(secondDone, isTrue);
  });

  testWidgets('show completes even if onClose throws', (tester) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      s.app(
        ArrowPopup(
          controller: controller,
          onClose: (_) => throw StateError('onClose failed'),
          content: const SizedBox(key: s.contentKey, width: 100, height: 50),
          child: const s.Anchor(),
        ),
      ),
    );
    Object? firstResult = 'pending';
    var secondDone = false;
    unawaited(controller.show().then((value) => firstResult = value));
    await tester.pumpAndSettle();
    controller.show().whenComplete(() => secondDone = true).ignore();
    await tester.pumpAndSettle();

    // hide calls onClose itself, so its error comes out of hide.
    expect(controller.hide, throwsStateError);
    await tester.pumpAndSettle();
    expect(firstResult, isNull);
    expect(secondDone, isTrue);
    expect(controller.isOpen, isFalse);
  });

  testWidgets('controller notifies listeners on open and close', (
    tester,
  ) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    final states = <bool>[];
    controller.addListener(() => states.add(controller.isOpen));
    await tester.pumpWidget(s.app(s.popup(controller: controller)));

    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(states, [true, false]);
  });

  testWidgets('controller notifies listeners when removed while open', (
    tester,
  ) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    final states = <bool>[];
    controller.addListener(() => states.add(controller.isOpen));
    await tester.pumpWidget(
      s.app(
        ValueListenableBuilder(
          valueListenable: visible,
          builder: (context, show, _) =>
              show ? s.popup(controller: controller) : const SizedBox(),
        ),
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    visible.value = false;
    await tester.pumpAndSettle();
    expect(states, [true, false]);
  });

  testWidgets('controller notifies listeners when replaced while open', (
    tester,
  ) async {
    final controller = ArrowPopupController();
    addTearDown(controller.dispose);
    final states = <bool>[];
    controller.addListener(() => states.add(controller.isOpen));
    Widget app(int key) => s.app(
      KeyedSubtree(
        key: ValueKey(key),
        child: s.popup(controller: controller),
      ),
    );
    await tester.pumpWidget(app(1));
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    await tester.pumpWidget(app(2));
    await tester.pumpAndSettle();
    expect(states, [true, false]);
    expect(find.byKey(s.contentKey), findsNothing);
  });

  testWidgets('swapping controllers while open notifies both', (tester) async {
    final first = ArrowPopupController();
    final second = ArrowPopupController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    final firstStates = <bool>[];
    final secondStates = <bool>[];
    first.addListener(() => firstStates.add(first.isOpen));
    second.addListener(() => secondStates.add(second.isOpen));
    await tester.pumpWidget(s.app(s.popup(controller: first)));
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    await tester.pumpWidget(s.app(s.popup(controller: second)));
    await tester.pumpAndSettle();
    expect(firstStates, [true, false]);
    expect(secondStates, [true]);
  });

  testWidgets('controller disposed along with an open popup', (tester) async {
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    await tester.pumpWidget(
      s.app(
        ValueListenableBuilder(
          valueListenable: visible,
          builder: (context, show, _) =>
              show ? const s.OwnsController() : const SizedBox(),
        ),
      ),
    );
    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    visible.value = false;
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsNothing);
  });

  testWidgets('longPress trigger opens only on long press', (tester) async {
    await tester.pumpWidget(
      s.app(s.popup(trigger: ArrowPopupTrigger.longPress)),
    );

    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsNothing);

    await tester.longPress(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsOneWidget);
  });

  testWidgets('ArrowPopup.show asserts for a context that is a sliver', (
    tester,
  ) async {
    await tester.pumpWidget(
      s.app(
        const CustomScrollView(
          slivers: [SliverToBoxAdapter(child: SizedBox(height: 40))],
        ),
      ),
    );
    final context = tester.element(find.byType(SliverToBoxAdapter));
    expect(
      () => ArrowPopup.show<void>(context: context, content: const Text('x')),
      throwsAssertionError,
    );
  });
}
