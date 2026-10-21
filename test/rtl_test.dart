import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart' as s;

void main() {
  group('right-to-left', () {
    Widget rtlApp(AlignmentGeometry alignment, {ArrowPopup? popup}) {
      return MaterialApp(
        // Wraps the navigator, so the popup's overlay is RTL too.
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: Scaffold(
          body: Align(alignment: alignment, child: popup ?? s.popup()),
        ),
      );
    }

    testWidgets('start opens to the right of the anchor', (tester) async {
      await tester.pumpWidget(
        rtlApp(
          Alignment.center,
          popup: s.popup(placement: ArrowPopupPlacement.start),
        ),
      );
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();

      expect(s.layoutOf(tester).geometry!.side, AxisDirection.right);
      expect(
        tester.getRect(find.byKey(s.contentKey)).left,
        greaterThan(tester.getRect(find.byKey(s.anchorKey)).right),
      );
    });

    testWidgets('directional padding puts start on the right', (tester) async {
      await tester.pumpWidget(
        rtlApp(
          Alignment.center,
          popup: s.popup(
            style: const ArrowPopupStyle(
              padding: EdgeInsetsDirectional.fromSTEB(20, 8, 4, 8),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();

      final box = s.layoutOf(tester).geometry!.box;
      final content = tester.getRect(find.byKey(s.contentKey));
      expect(box.right - content.right, moreOrLessEquals(20));
      expect(content.left - box.left, moreOrLessEquals(4));
    });

    testWidgets('centers on the anchor with the arrow pointing at it', (
      tester,
    ) async {
      await tester.pumpWidget(rtlApp(Alignment.center));
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();

      final anchor = tester.getRect(find.byKey(s.anchorKey));
      final content = tester.getRect(find.byKey(s.contentKey));
      final geometry = s.layoutOf(tester).geometry!;
      expect(content.center.dx, moreOrLessEquals(anchor.center.dx));
      expect(content.top, greaterThan(anchor.bottom));
      expect(geometry.tip.dx, moreOrLessEquals(anchor.center.dx));
    });

    testWidgets('stays on screen at the start edge', (tester) async {
      await tester.pumpWidget(rtlApp(AlignmentDirectional.centerStart));
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();

      // In RTL, "start" is the right side of the screen.
      final anchor = tester.getRect(find.byKey(s.anchorKey));
      expect(anchor.right, 800);
      final geometry = s.layoutOf(tester).geometry!;
      expect(geometry.box.right, lessThanOrEqualTo(800 - 10));
      expect(geometry.box.left, greaterThanOrEqualTo(10));
      // Held back from the corner, but still pointing at the anchor.
      expect(geometry.tip.dx, inInclusiveRange(anchor.left, anchor.right));
      expect(
        geometry.arrowCenter + 8,
        lessThanOrEqualTo(geometry.box.right - geometry.radius),
      );
    });

    testWidgets('content is laid out right-to-left', (tester) async {
      await tester.pumpWidget(rtlApp(Alignment.center));
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();

      expect(
        Directionality.of(tester.element(find.byKey(s.contentKey))),
        TextDirection.rtl,
      );
    });

    testWidgets('follows a Directionality set below the navigator', (
      tester,
    ) async {
      // The app is left-to-right; only the popup's caller is right-to-left.
      await tester.pumpWidget(
        s.app(
          Directionality(
            textDirection: TextDirection.rtl,
            child: s.popup(
              placement: ArrowPopupPlacement.end,
              style: const ArrowPopupStyle(
                padding: EdgeInsetsDirectional.fromSTEB(20, 8, 4, 8),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(s.anchorKey));
      await tester.pumpAndSettle();

      // In RTL, "end" is the left side and start padding is on the right.
      final geometry = s.layoutOf(tester).geometry!;
      expect(geometry.side, AxisDirection.left);
      final content = tester.getRect(find.byKey(s.contentKey));
      expect(geometry.box.right - content.right, moreOrLessEquals(20));
      expect(
        Directionality.of(tester.element(find.byKey(s.contentKey))),
        TextDirection.rtl,
      );
    });
  });

  testWidgets('positions correctly inside a nested navigator', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            const SizedBox(height: 200),
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 300),
                  Expanded(
                    child: Navigator(
                      onGenerateRoute: (_) => MaterialPageRoute(
                        builder: (_) =>
                            Scaffold(body: Center(child: s.popup())),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(s.anchorKey));
    await tester.pumpAndSettle();

    final anchor = tester.getRect(find.byKey(s.anchorKey));
    final content = tester.getRect(find.byKey(s.contentKey));
    expect(content.center.dx, moreOrLessEquals(anchor.center.dx));
    expect(content.top, greaterThan(anchor.bottom));
    expect(content.top, lessThan(anchor.bottom + 40));
  });
}
