import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../config/style.dart';
import 'side_picker.dart';

/// Where the bubble and arrow go once the content has been measured.
@immutable
class ArrowPopupGeometry {
  /// Creates a geometry.
  const ArrowPopupGeometry({
    required this.box,
    required this.radius,
    required this.side,
    required this.arrowCenter,
    required this.arrowSize,
    this.coversAnchor = false,
  });

  /// Places a bubble holding content of [contentSize] on [side] of [anchor],
  /// as chosen by [arrowPopupSide].
  ///
  /// With [coversAnchor], the bubble is centered on the visible part of [anchor]
  /// instead, without an arrow.
  factory ArrowPopupGeometry.layout({
    required Size contentSize,
    required Rect viewport,
    required Rect anchor,
    required ArrowPopupStyle style,
    required AxisDirection side,
    bool coversAnchor = false,
  }) {
    final bubble = style.padding.inflateSize(contentSize);
    if (coversAnchor) {
      return ArrowPopupGeometry._coveringAnchor(
        bubble: bubble,
        viewport: viewport,
        anchor: anchor,
        style: style,
        side: side,
      );
    }

    final box =
        _bubbleOrigin(
          side: side,
          bubble: bubble,
          viewport: viewport,
          anchor: anchor,
          distance: anchorToBubbleDistance(style),
        ) &
        bubble;

    // The arrow's base is never longer than the edge it sits on, and the
    // corners shrink if needed to leave room for it.
    final vertical = axisDirectionToAxis(side) == Axis.vertical;
    final (edgeStart, edgeEnd) = vertical
        ? (box.left, box.right)
        : (box.top, box.bottom);
    final edge = edgeEnd - edgeStart;
    final arrowSize = _arrowSizeFor(
      box: box,
      anchor: anchor,
      style: style,
      side: side,
      edge: edge,
    );
    final radius = math.min(
      style.borderRadius,
      math.min(
        math.min(box.width, box.height) / 2,
        (edge - arrowSize.width) / 2,
      ),
    );

    // Point at the anchor, but keep the arrow off the rounded corners. When
    // the corners shrank to fit the arrow, rounding can put the upper limit
    // just below the lower one, which clamp rejects.
    final arrowMin = edgeStart + radius + arrowSize.width / 2;
    final arrowMax = math.max(arrowMin, edgeEnd - radius - arrowSize.width / 2);
    final arrowCenter = (vertical ? anchor.center.dx : anchor.center.dy)
        .clamp(arrowMin, arrowMax)
        .toDouble();

    return ArrowPopupGeometry(
      box: box,
      radius: radius,
      side: side,
      arrowCenter: arrowCenter,
      arrowSize: arrowSize,
    );
  }

  // A bubble centered on the visible part of the anchor, without an arrow.
  factory ArrowPopupGeometry._coveringAnchor({
    required Size bubble,
    required Rect viewport,
    required Rect anchor,
    required ArrowPopupStyle style,
    required AxisDirection side,
  }) {
    final visible = anchor.intersect(viewport);
    // Only the viewport's center is left when the anchor is out of view.
    final center = visible.isEmpty ? viewport.center : visible.center;
    final box =
        Offset(
          _centerWithin(center.dx, bubble.width, viewport.left, viewport.right),
          _centerWithin(
            center.dy,
            bubble.height,
            viewport.top,
            viewport.bottom,
          ),
        ) &
        bubble;
    final vertical = axisDirectionToAxis(side) == Axis.vertical;
    return ArrowPopupGeometry(
      box: box,
      radius: math.min(style.borderRadius, box.shortestSide / 2),
      side: side,
      arrowCenter: vertical ? box.center.dx : box.center.dy,
      arrowSize: Size.zero,
      coversAnchor: true,
    );
  }

  // Moves a span of [length] that starts at [start] back inside [min] to
  // [max].
  static double _keepWithin(
    double start,
    double length,
    double min,
    double max,
  ) => math.max(math.min(start, max - length), min);

  static double _centerWithin(
    double center,
    double length,
    double min,
    double max,
  ) => _keepWithin(center - length / 2, length, min, max);

  // The bubble's top left corner on [side] of [anchor]: centered on the anchor
  // along the edge facing it, then shifted back inside the viewport. Away from
  // the anchor, it is shifted back too: an anchor partly outside the viewport,
  // such as behind the keyboard, must not take the bubble with it.
  static Offset _bubbleOrigin({
    required AxisDirection side,
    required Size bubble,
    required Rect viewport,
    required Rect anchor,
    required double distance,
  }) {
    double centeredX() => _centerWithin(
      anchor.center.dx,
      bubble.width,
      viewport.left,
      viewport.right,
    );
    double centeredY() => _centerWithin(
      anchor.center.dy,
      bubble.height,
      viewport.top,
      viewport.bottom,
    );
    double keepX(double left) =>
        _keepWithin(left, bubble.width, viewport.left, viewport.right);
    double keepY(double top) =>
        _keepWithin(top, bubble.height, viewport.top, viewport.bottom);

    return switch (side) {
      AxisDirection.down => Offset(
        centeredX(),
        keepY(anchor.bottom + distance),
      ),
      AxisDirection.up => Offset(
        centeredX(),
        keepY(anchor.top - distance - bubble.height),
      ),
      AxisDirection.right => Offset(
        keepX(anchor.right + distance),
        centeredY(),
      ),
      AxisDirection.left => Offset(
        keepX(anchor.left - distance - bubble.width),
        centeredY(),
      ),
    };
  }

  // The arrow's size, or [Size.zero] when it is hidden or the bubble had to
  // cover the anchor to stay inside the viewport, since the arrow would then
  // point past it. The tolerance keeps rounding from hiding the arrow when
  // the gap is 0.
  static Size _arrowSizeFor({
    required Rect box,
    required Rect anchor,
    required ArrowPopupStyle style,
    required AxisDirection side,
    required double edge,
  }) {
    final arrowLength = style.arrowSize.height;
    const tolerance = precisionErrorTolerance;
    final arrowPointsPastAnchor = switch (side) {
      AxisDirection.down => box.top - arrowLength < anchor.bottom - tolerance,
      AxisDirection.up => box.bottom + arrowLength > anchor.top + tolerance,
      AxisDirection.right => box.left - arrowLength < anchor.right - tolerance,
      AxisDirection.left => box.right + arrowLength > anchor.left + tolerance,
    };
    if (!style.showArrow || arrowPointsPastAnchor) return Size.zero;
    return Size(math.min(style.arrowSize.width, edge), arrowLength);
  }

  /// The bubble's rectangle, without the arrow.
  final Rect box;

  /// Corner radius actually used, never more than half the shorter side and
  /// small enough to leave room for the arrow.
  final double radius;

  /// Which way the bubble is from the anchor. The arrow is on the opposite
  /// edge, facing the anchor.
  final AxisDirection side;

  /// Center of the arrow's base along its edge: an x coordinate when the
  /// bubble is above or below the anchor, a y coordinate when beside it.
  ///
  /// Set even when the arrow is hidden, to where it would point.
  final double arrowCenter;

  /// Size of the arrow, or [Size.zero] when it is hidden or the bubble had to
  /// cover the anchor. The width is the base, never longer than the edge it
  /// sits on.
  final Size arrowSize;

  /// Whether the bubble was centered over the anchor because there was no
  /// room around it.
  final bool coversAnchor;

  /// The point of the arrow, or the point at [arrowCenter] on the bubble's edge
  /// facing the anchor when the arrow is hidden, so the bubble grows from
  /// the anchor either way. The bubble's center when it covers the anchor,
  /// so it grows from the middle.
  Offset get tip => coversAnchor
      ? box.center
      : switch (side) {
          AxisDirection.down => Offset(arrowCenter, box.top - arrowSize.height),
          AxisDirection.up => Offset(
            arrowCenter,
            box.bottom + arrowSize.height,
          ),
          AxisDirection.right => Offset(
            box.left - arrowSize.height,
            arrowCenter,
          ),
          AxisDirection.left => Offset(
            box.right + arrowSize.height,
            arrowCenter,
          ),
        };

  /// Outline of the bubble and arrow as a single shape.
  Path get path {
    final corner = Radius.circular(radius);
    final halfBase = arrowSize.width / 2;
    final hasArrow = !arrowSize.isEmpty;
    final tip = this.tip;
    // Clockwise from the top-left corner. The arrow is on the edge that
    // faces the anchor.
    final path = Path()..moveTo(box.left + radius, box.top);
    if (hasArrow && side == AxisDirection.down) {
      path
        ..lineTo(arrowCenter - halfBase, box.top)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(arrowCenter + halfBase, box.top);
    }
    path
      ..lineTo(box.right - radius, box.top)
      ..arcToPoint(Offset(box.right, box.top + radius), radius: corner);
    if (hasArrow && side == AxisDirection.left) {
      path
        ..lineTo(box.right, arrowCenter - halfBase)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(box.right, arrowCenter + halfBase);
    }
    path
      ..lineTo(box.right, box.bottom - radius)
      ..arcToPoint(Offset(box.right - radius, box.bottom), radius: corner);
    if (hasArrow && side == AxisDirection.up) {
      path
        ..lineTo(arrowCenter + halfBase, box.bottom)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(arrowCenter - halfBase, box.bottom);
    }
    path
      ..lineTo(box.left + radius, box.bottom)
      ..arcToPoint(Offset(box.left, box.bottom - radius), radius: corner);
    if (hasArrow && side == AxisDirection.right) {
      path
        ..lineTo(box.left, arrowCenter + halfBase)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(box.left, arrowCenter - halfBase);
    }
    return path
      ..lineTo(box.left, box.top + radius)
      ..arcToPoint(Offset(box.left + radius, box.top), radius: corner)
      ..close();
  }
}
