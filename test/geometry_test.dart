import 'package:arrow_popup/arrow_popup.dart';
import 'package:arrow_popup/src/layout/geometry.dart';
import 'package:arrow_popup/src/layout/side_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _viewport = Rect.fromLTRB(10, 10, 390, 790);
const _style = ArrowPopupStyle(padding: EdgeInsets.zero);

AxisDirection _side(
  Rect anchor, {
  Size content = const Size(100, 50),
  ArrowPopupStyle style = _style,
  ArrowPopupPlacement placement = ArrowPopupPlacement.auto,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return arrowPopupSide(
    contentSize: content,
    viewport: _viewport,
    anchor: anchor,
    style: style,
    placement: placement,
    textDirection: textDirection,
  ).side;
}

ArrowPopupGeometry _layout(
  Rect anchor, {
  Size content = const Size(100, 50),
  ArrowPopupStyle style = _style,
  ArrowPopupPlacement placement = ArrowPopupPlacement.auto,
}) {
  return ArrowPopupGeometry.layout(
    contentSize: content,
    viewport: _viewport,
    anchor: anchor,
    style: style,
    side: _side(anchor, content: content, style: style, placement: placement),
  );
}

void main() {
  test('centers below the anchor with the arrow tip at the gap', () {
    final g = _layout(const Rect.fromLTWH(180, 100, 40, 40));
    expect(g.side, AxisDirection.down);
    expect(g.box, const Rect.fromLTWH(150, 150, 100, 50));
    expect(g.tip, const Offset(200, 142));
  });

  test('adds padding around the content', () {
    final g = _layout(
      const Rect.fromLTWH(180, 100, 40, 40),
      style: const ArrowPopupStyle(padding: EdgeInsets.all(8)),
    );
    expect(g.box.size, const Size(116, 66));
  });

  test('shifts inside the viewport and keeps the arrow off corners', () {
    final g = _layout(const Rect.fromLTWH(386, 100, 4, 40));
    expect(g.box.right, 390);
    expect(g.arrowCenter, 390 - 12 - 8);
  });

  test(
    'without an arrow, the tip stays on the anchor side of a shifted box',
    () {
      // Pushed against the left edge, so the box's middle is far from the
      // anchor; the bubble should still grow from the anchor.
      final g = _layout(
        const Rect.fromLTWH(10, 100, 40, 40),
        content: const Size(200, 50),
        style: _style.copyWith(showArrow: false),
      );
      expect(g.arrowSize, Size.zero);
      expect(g.box.left, 10);
      expect(g.tip, Offset(30, g.box.top));
    },
  );

  test('arrow wider than the bubble stays within it', () {
    final g = _layout(
      const Rect.fromLTWH(180, 100, 40, 40),
      content: const Size(20, 20),
      style: _style.copyWith(arrowSize: const Size(40, 8)),
    );
    expect(
      g.arrowCenter - g.arrowSize.width / 2,
      greaterThanOrEqualTo(g.box.left),
    );
    expect(
      g.arrowCenter + g.arrowSize.width / 2,
      lessThanOrEqualTo(g.box.right),
    );
    expect(g.arrowSize.height, 8);
  });

  test('corners shrunk to fit the arrow survive rounding', () {
    // The corners shrink to exactly leave room for the arrow, so the range
    // the arrow can move in is empty and rounding can invert it.
    for (var i = 0; i < 2000; i++) {
      for (final placement in ArrowPopupPlacement.values) {
        final g = _layout(
          Rect.fromLTWH(100 + i * 0.137, 300 + i * 0.071, 13.3, 17.1),
          content: Size(20 + i % 7 * 0.31, 30 + i % 5 * 0.23),
          style: _style.copyWith(borderRadius: 999),
          placement: placement,
        );
        expect(g.arrowCenter.isFinite, isTrue);
      }
    }
  });

  group('beside the anchor', () {
    const anchor = Rect.fromLTWH(100, 300, 40, 40);

    test('right centers vertically with the tip at the gap', () {
      final g = _layout(anchor, placement: ArrowPopupPlacement.right);
      expect(g.side, AxisDirection.right);
      expect(g.box, const Rect.fromLTWH(150, 295, 100, 50));
      expect(g.tip, const Offset(142, 320));
    });

    test('left mirrors right', () {
      final g = _layout(
        const Rect.fromLTWH(250, 300, 40, 40),
        placement: ArrowPopupPlacement.left,
      );
      expect(g.side, AxisDirection.left);
      expect(g.box, const Rect.fromLTWH(140, 295, 100, 50));
      expect(g.tip, const Offset(248, 320));
    });

    test('shifts inside the viewport and keeps the arrow off corners', () {
      final g = _layout(
        const Rect.fromLTWH(100, 786, 40, 4),
        placement: ArrowPopupPlacement.right,
      );
      expect(g.box.bottom, 790);
      expect(g.arrowCenter, 790 - 12 - 8);
    });

    test('arrow wider than the bubble stays within it', () {
      final g = _layout(
        anchor,
        content: const Size(100, 20),
        style: _style.copyWith(arrowSize: const Size(40, 8)),
        placement: ArrowPopupPlacement.left,
      );
      expect(
        g.arrowCenter - g.arrowSize.width / 2,
        greaterThanOrEqualTo(g.box.top),
      );
      expect(
        g.arrowCenter + g.arrowSize.width / 2,
        lessThanOrEqualTo(g.box.bottom),
      );
    });

    test('side constraints use the space on that side', () {
      BoxConstraints constraints(AxisDirection side) {
        return arrowPopupSideConstraints(
          viewport: _viewport,
          anchor: anchor,
          style: _style,
          side: side,
        );
      }

      expect(constraints(AxisDirection.right).maxWidth, 390 - 140 - 10);
      expect(constraints(AxisDirection.left).maxWidth, 100 - 10 - 10);
      expect(constraints(AxisDirection.left).maxHeight, 780);
      expect(constraints(AxisDirection.down).maxHeight, 790 - 340 - 10);
    });

    test('path covers the arrow on the side edge', () {
      final g = _layout(anchor, placement: ArrowPopupPlacement.right);
      expect(g.path.contains(g.tip + const Offset(2, 0)), isTrue);
      expect(g.path.contains(g.tip - const Offset(2, 0)), isFalse);
    });
  });

  group('auto tries below, above, right, then left', () {
    // Leaves 240 below and 490 above, in the viewport from 10 to 790.
    const lower = Rect.fromLTWH(180, 500, 40, 40);

    test('below when it fits, even with more room above', () {
      expect(_side(lower), AxisDirection.down);
    });

    test('right when neither above nor below fits', () {
      // Fills the viewport's height, leaving 130 on each side.
      expect(
        _side(
          const Rect.fromLTWH(150, 10, 100, 780),
          content: const Size(50, 50),
        ),
        AxisDirection.right,
      );
    });

    test('right before left, even when left has more room', () {
      // Leaves 80 on the right and 180 on the left.
      const anchor = Rect.fromLTWH(200, 10, 100, 780);
      const content = Size(50, 50);
      expect(_side(anchor, content: content), AxisDirection.right);
      // Unlike below, which tries the roomier of the other two first.
      expect(
        _side(anchor, content: content, placement: ArrowPopupPlacement.below),
        AxisDirection.left,
      );
    });

    test('left when only left fits', () {
      // Leaves 30 on the right and 230 on the left.
      expect(
        _side(
          const Rect.fromLTWH(250, 10, 100, 780),
          content: const Size(50, 50),
        ),
        AxisDirection.left,
      );
    });

    test('left before right in right-to-left text', () {
      // Leaves 130 on each side.
      expect(
        _side(
          const Rect.fromLTWH(150, 10, 100, 780),
          content: const Size(50, 50),
          textDirection: TextDirection.rtl,
        ),
        AxisDirection.left,
      );
    });
  });

  group('start and end follow the text direction', () {
    // Room on every side.
    const anchor = Rect.fromLTWH(180, 380, 40, 40);

    test('left-to-right', () {
      expect(
        _side(anchor, placement: ArrowPopupPlacement.start),
        AxisDirection.left,
      );
      expect(
        _side(anchor, placement: ArrowPopupPlacement.end),
        AxisDirection.right,
      );
    });

    test('right-to-left', () {
      expect(
        _side(
          anchor,
          placement: ArrowPopupPlacement.start,
          textDirection: TextDirection.rtl,
        ),
        AxisDirection.right,
      );
      expect(
        _side(
          anchor,
          placement: ArrowPopupPlacement.end,
          textDirection: TextDirection.rtl,
        ),
        AxisDirection.left,
      );
    });

    test('left and right ignore it', () {
      expect(
        _side(
          anchor,
          placement: ArrowPopupPlacement.left,
          textDirection: TextDirection.rtl,
        ),
        AxisDirection.left,
      );
    });

    test('start flips to end when it does not fit', () {
      // At the right edge in right-to-left text, so start has no room.
      expect(
        _side(
          const Rect.fromLTWH(350, 380, 40, 40),
          placement: ArrowPopupPlacement.start,
          textDirection: TextDirection.rtl,
        ),
        AxisDirection.left,
      );
    });
  });

  test('auto opens above when only the top has room', () {
    final g = _layout(const Rect.fromLTWH(180, 740, 40, 40));
    expect(g.side, AxisDirection.up);
    expect(g.box.bottom, 740 - 10);
  });

  group('anchor outside the viewport, as behind the keyboard', () {
    // Below the viewport's bottom edge at 790.
    const hidden = Rect.fromLTWH(180, 900, 40, 40);

    test('bubble stays inside the viewport', () {
      final g = _layout(hidden);
      expect(g.side, AxisDirection.up);
      expect(g.box, const Rect.fromLTWH(150, 740, 100, 50));
      // Still points toward the anchor, which it doesn't cover.
      expect(g.arrowSize, isNot(Size.zero));
    });

    test('arrow is hidden when the bubble has to cover the anchor', () {
      // An anchor that fills the viewport leaves room on no side.
      final g = _layout(const Rect.fromLTWH(0, 0, 400, 800));
      expect(_viewport.contains(g.box.center), isTrue);
      expect(g.arrowSize, Size.zero);
    });

    test('content is never taller than the viewport', () {
      final c = arrowPopupSideConstraints(
        viewport: _viewport,
        anchor: hidden,
        style: _style,
        side: AxisDirection.up,
      );
      expect(c.maxHeight, 780);
    });

    test('beside it, the bubble stays inside too', () {
      final g = _layout(
        const Rect.fromLTWH(-200, 100, 40, 40),
        placement: ArrowPopupPlacement.right,
      );
      expect(g.box.left, 10);
    });
  });

  test('with no gap, rounding never hides the arrow', () {
    const style = ArrowPopupStyle(padding: EdgeInsets.zero, gap: 0);
    // Big enough that the bubble fits on every side without shifting.
    const viewport = Rect.fromLTWH(0, 0, 2000, 2000);
    for (final side in AxisDirection.values) {
      for (var i = 0; i < 10000; i++) {
        // Fractional positions, where (a + 8) - 8 is not always a.
        final offset = 200 + i * 0.1;
        final g = ArrowPopupGeometry.layout(
          contentSize: const Size(100, 50),
          viewport: viewport,
          anchor: Rect.fromLTWH(offset, offset, 20.3, 20.3),
          style: style,
          side: side,
        );
        expect(g.arrowSize, isNot(Size.zero), reason: '$side at $offset');
      }
    }
  });

  group('falls back when the preferred side has no room', () {
    test('uses the preferred side when it fits', () {
      final side = _side(
        const Rect.fromLTWH(180, 100, 40, 40),
        placement: ArrowPopupPlacement.above,
      );
      expect(side, AxisDirection.up);
    });

    test('above flips below near the top', () {
      final side = _side(
        const Rect.fromLTWH(180, 20, 40, 40),
        placement: ArrowPopupPlacement.above,
      );
      expect(side, AxisDirection.down);
    });

    test('below flips above near the bottom', () {
      final side = _side(
        const Rect.fromLTWH(180, 740, 40, 40),
        placement: ArrowPopupPlacement.below,
      );
      expect(side, AxisDirection.up);
    });

    test('right flips left near the right edge', () {
      final side = _side(
        const Rect.fromLTWH(340, 300, 40, 40),
        placement: ArrowPopupPlacement.right,
      );
      expect(side, AxisDirection.left);
    });

    test('beside goes to the roomier of above and below when neither fits', () {
      // 200 wide content fits on neither side of a centered anchor.
      final side = _side(
        const Rect.fromLTWH(180, 200, 40, 40),
        content: const Size(200, 50),
        placement: ArrowPopupPlacement.left,
      );
      expect(side, AxisDirection.down);
    });

    test('above and below go beside when neither fits', () {
      // 600 tall content fits only beside an anchor in the middle.
      final side = _side(
        const Rect.fromLTWH(20, 380, 40, 40),
        content: const Size(100, 600),
        placement: ArrowPopupPlacement.above,
      );
      expect(side, AxisDirection.right);
    });

    test('fitting nowhere picks the roomier of the preferred axis', () {
      final result = arrowPopupSide(
        contentSize: const Size(380, 600),
        viewport: _viewport,
        anchor: const Rect.fromLTWH(180, 500, 40, 40),
        style: _style,
        placement: ArrowPopupPlacement.below,
      );
      expect(result.fits, isFalse);
      expect(result.side, AxisDirection.up);
      // 480 of 780 above is plenty, so it shrinks instead of overlapping.
      expect(result.coversAnchor, isFalse);
    });
  });

  group('content wider than the viewport', () {
    test('beside the anchor shrinks to the room on that side', () {
      final result = arrowPopupSide(
        contentSize: const Size(600, 50),
        viewport: _viewport,
        anchor: const Rect.fromLTWH(180, 400, 40, 40),
        style: _style,
        placement: ArrowPopupPlacement.left,
      );
      expect(result.fits, isFalse);
      expect(result.coversAnchor, isFalse);
      expect(axisDirectionToAxis(result.side), Axis.horizontal);
    });
  });

  group('anchor with almost no room around it', () {
    // Leaves 70 below, under a quarter of the viewport's 780 height, and no
    // room above or beside.
    const big = Rect.fromLTWH(10, 10, 380, 700);

    test('overlaps when the roomier side has under a quarter', () {
      final result = arrowPopupSide(
        contentSize: const Size(100, 200),
        viewport: _viewport,
        anchor: big,
        style: _style,
        placement: ArrowPopupPlacement.auto,
      );
      expect(result.fits, isFalse);
      expect(result.coversAnchor, isTrue);
    });

    test('still uses the side when the content fits there', () {
      final result = arrowPopupSide(
        contentSize: const Size(100, 50),
        viewport: _viewport,
        anchor: big,
        style: _style,
        placement: ArrowPopupPlacement.auto,
      );
      expect(result.fits, isTrue);
      expect(result.coversAnchor, isFalse);
      expect(result.side, AxisDirection.down);
    });

    test('overlapping centers on the visible anchor without an arrow', () {
      final g = ArrowPopupGeometry.layout(
        contentSize: const Size(100, 200),
        viewport: _viewport,
        // Hangs past the viewport's bottom, so only 10 to 790 shows.
        anchor: const Rect.fromLTWH(10, 10, 380, 1000),
        style: _style,
        side: AxisDirection.down,
        coversAnchor: true,
      );
      expect(g.box, const Rect.fromLTWH(150, 300, 100, 200));
      expect(g.arrowSize, Size.zero);
      // The open animation grows from the middle.
      expect(g.tip, g.box.center);
    });
  });

  test('hidden arrow puts the bubble right after the gap', () {
    final g = _layout(
      const Rect.fromLTWH(180, 100, 40, 40),
      style: _style.copyWith(showArrow: false),
    );
    expect(g.arrowSize, Size.zero);
    expect(g.box.top, 142);
  });

  test('natural constraints are the whole viewport', () {
    final c = arrowPopupNaturalConstraints(viewport: _viewport, style: _style);
    expect(c.maxWidth, 380);
    expect(c.maxHeight, 780);
  });

  test('maxWidth limits the bubble, padding included', () {
    final c = arrowPopupNaturalConstraints(
      viewport: _viewport,
      style: const ArrowPopupStyle(maxWidth: 200, padding: EdgeInsets.all(8)),
    );
    expect(c.maxWidth, 200 - 16);
  });

  test('the viewport still wins over a larger maxWidth', () {
    final c = arrowPopupNaturalConstraints(
      viewport: _viewport,
      style: _style.copyWith(maxWidth: 1000),
    );
    expect(c.maxWidth, 380);
  });

  test('path covers the bubble and the arrow', () {
    final g = _layout(const Rect.fromLTWH(180, 100, 40, 40));
    final path = g.path;
    expect(path.contains(g.box.center), isTrue);
    expect(path.contains(g.tip + const Offset(0, 2)), isTrue);
    expect(path.contains(g.tip - const Offset(0, 2)), isFalse);
  });
}
