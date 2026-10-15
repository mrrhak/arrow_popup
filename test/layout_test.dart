import 'package:arrow_popup/arrow_popup.dart';
import 'package:arrow_popup/src/layout/anchor.dart';
import 'package:arrow_popup/src/layout/layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// The render object is updated in place when the widget is rebuilt with other
// values, so these pump the same layout twice with something changed.

const _rootKey = Key('root');
const _firstKey = Key('first');
const _secondKey = Key('second');
const _childKey = Key('child');

ArrowPopupAnchor _anchorOf(WidgetTester tester, Key key) {
  return ArrowPopupAnchor(
    tester.renderObject<RenderBox>(find.byKey(key)),
    tester.renderObject<RenderBox>(find.byKey(_rootKey)),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  ArrowPopupAnchor? anchor,
  Animation<double> scale = kAlwaysCompleteAnimation,
  TextDirection textDirection = TextDirection.ltr,
  ArrowPopupStyle style = const ArrowPopupStyle(),
  bool withChild = true,
}) {
  return tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        key: _rootKey,
        width: 400,
        height: 800,
        child: Stack(
          children: [
            const Positioned(
              left: 50,
              top: 100,
              child: SizedBox(key: _firstKey, width: 40, height: 40),
            ),
            const Positioned(
              left: 250,
              top: 500,
              child: SizedBox(key: _secondKey, width: 40, height: 40),
            ),
            if (anchor != null)
              Positioned.fill(
                child: ArrowPopupLayout(
                  anchor: anchor,
                  safeArea: EdgeInsets.zero,
                  style: style,
                  color: const Color(0xFFFFFFFF),
                  placement: ArrowPopupPlacement.below,
                  scale: scale,
                  textDirection: textDirection,
                  child: withChild
                      ? const SizedBox(key: _childKey, width: 40, height: 20)
                      : null,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

RenderArrowPopupLayout _render(WidgetTester tester) {
  return tester.renderObject(find.byType(ArrowPopupLayout));
}

void main() {
  testWidgets('moves the bubble when given another anchor', (tester) async {
    await _pump(tester);
    final first = _anchorOf(tester, _firstKey);
    final second = _anchorOf(tester, _secondKey);
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await _pump(tester, anchor: first);
    final before = _render(tester).geometry!.box;
    await _pump(tester, anchor: second);
    final after = _render(tester).geometry!.box;

    expect(after.top, greaterThan(before.top));
    expect(after.left, greaterThan(before.left));
  });

  testWidgets('listens to the new anchor and not the old one', (tester) async {
    await _pump(tester);
    final first = _anchorOf(tester, _firstKey);
    final second = _anchorOf(tester, _secondKey);
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await _pump(tester, anchor: first);
    await _pump(tester, anchor: second);
    // Both notify; only the second's one is listened to, and it relays out.
    first.update();
    second.update();
    await tester.pump();

    expect(_render(tester).geometry, isNotNull);
  });

  testWidgets('swaps the scale animation, hiding at zero', (tester) async {
    await _pump(tester);
    final anchor = _anchorOf(tester, _firstKey);
    addTearDown(anchor.dispose);

    await _pump(tester, anchor: anchor);
    final full = tester.getTopLeft(find.byKey(_childKey));

    const half = AlwaysStoppedAnimation<double>(0.5);
    await _pump(tester, anchor: anchor, scale: half);
    // Painted shrunk toward the arrow, so it moved without a new layout.
    expect(tester.getTopLeft(find.byKey(_childKey)), isNot(full));

    await _pump(tester, anchor: anchor, scale: kAlwaysDismissedAnimation);
    expect(_render(tester).geometry, isNotNull);
    // Nothing is hit while fully scaled away.
    final center = tester.getCenter(find.byKey(_childKey));
    final hit = tester.hitTestOnBinding(center);
    expect(
      hit.path.any((entry) => entry.target is RenderArrowPopupLayout),
      isFalse,
    );
  });

  testWidgets('relays out when the text direction changes', (tester) async {
    await _pump(tester);
    final anchor = _anchorOf(tester, _firstKey);
    addTearDown(anchor.dispose);
    const style = ArrowPopupStyle(
      padding: EdgeInsetsDirectional.only(start: 20),
    );

    await _pump(tester, anchor: anchor, style: style);
    final ltr =
        tester.getTopLeft(find.byKey(_childKey)).dx -
        _render(tester).geometry!.box.left;
    expect(ltr, 20);

    await _pump(
      tester,
      anchor: anchor,
      style: style,
      textDirection: TextDirection.rtl,
    );
    final rtl =
        tester.getTopLeft(find.byKey(_childKey)).dx -
        _render(tester).geometry!.box.left;
    expect(rtl, 0);
  });

  testWidgets('has nothing to paint or hit without a child', (tester) async {
    await _pump(tester);
    final anchor = _anchorOf(tester, _firstKey);
    addTearDown(anchor.dispose);

    await _pump(tester, anchor: anchor);
    expect(_render(tester).geometry, isNotNull);

    await _pump(tester, anchor: anchor, withChild: false);
    expect(_render(tester).geometry, isNull);
    expect(tester.takeException(), isNull);
  });

  test('lerp blends finite max widths', () {
    const a = ArrowPopupStyle(maxWidth: 100);
    const b = ArrowPopupStyle(maxWidth: 200);

    expect(a.lerp(b, 0.5).maxWidth, 150);
  });
}
