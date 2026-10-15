import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../config/enums.dart';
import '../config/style.dart';

/// The room on the chosen side, as a fraction of the viewport, below which the
/// bubble covers the anchor instead of being squeezed beside it.
const _minUsableSpaceFraction = 0.25;

/// Distance from the anchor's edge to the bubble's edge.
double anchorToBubbleDistance(ArrowPopupStyle style) =>
    style.gap + (style.showArrow ? style.arrowSize.height : 0);

/// Room for the bubble on [side] of the anchor, after the gap and arrow.
///
/// Beside an anchor that is partly outside the viewport, such as behind the
/// keyboard, this can be more than the viewport itself, or negative.
double _availableSpace(
  AxisDirection side,
  Rect viewport,
  Rect anchor,
  double distance,
) {
  return switch (side) {
    AxisDirection.up => anchor.top - distance - viewport.top,
    AxisDirection.down => viewport.bottom - anchor.bottom - distance,
    AxisDirection.left => anchor.left - distance - viewport.left,
    AxisDirection.right => viewport.right - anchor.right - distance,
  };
}

/// Constraints for content whose bubble is at most [width] by [height].
BoxConstraints _constraintsFor(
  double width,
  double height,
  ArrowPopupStyle style,
) {
  return BoxConstraints(
    maxWidth: math.max(
      0,
      math.min(width, style.maxWidth) - style.padding.horizontal,
    ),
    maxHeight: math.max(
      0,
      math.min(height, style.maxHeight) - style.padding.vertical,
    ),
  );
}

/// The largest size the popup content may take before a side is chosen: its
/// natural size, limited only by the viewport and [ArrowPopupStyle.maxWidth].
///
/// [viewport] is the area the bubble must stay inside.
BoxConstraints arrowPopupNaturalConstraints({
  required Rect viewport,
  required ArrowPopupStyle style,
}) {
  return _constraintsFor(viewport.width, viewport.height, style);
}

/// The largest size the popup content may take on [side] of [anchor].
///
/// Used when the content fits on no side at its natural size, so it has to
/// shrink, or scroll, to fit.
BoxConstraints arrowPopupSideConstraints({
  required Rect viewport,
  required Rect anchor,
  required ArrowPopupStyle style,
  required AxisDirection side,
}) {
  final space = _availableSpace(
    side,
    viewport,
    anchor,
    anchorToBubbleDistance(style),
  );
  return axisDirectionToAxis(side) == Axis.vertical
      ? _constraintsFor(viewport.width, math.min(space, viewport.height), style)
      : _constraintsFor(
          math.min(space, viewport.width),
          viewport.height,
          style,
        );
}

/// Which side of [anchor] the bubble goes on, for content of [contentSize].
///
/// The side [placement] asks for is used if the bubble fits there, otherwise
/// the opposite side, otherwise the other two sides, the roomier first.
/// [ArrowPopupPlacement.auto] tries below, above, end and start, in that
/// order, and counts as asking for below. [textDirection] decides which
/// physical sides start and end are. When the bubble fits nowhere,
/// [fits] is false and [side] is whichever of the asked-for side and its
/// opposite has more room; the content must then be laid out again with
/// [arrowPopupSideConstraints].
///
/// If that side has less than a quarter of the viewport, as beside an anchor
/// that fills the screen, the content would be squeezed to almost nothing.
/// Then [coversAnchor] is true instead: the content keeps its natural size and the
/// bubble covers the anchor, laid out with `coversAnchor` in
/// [ArrowPopupGeometry.layout].
({AxisDirection side, bool fits, bool coversAnchor}) arrowPopupSide({
  required Size contentSize,
  required Rect viewport,
  required Rect anchor,
  required ArrowPopupStyle style,
  required ArrowPopupPlacement placement,
  TextDirection textDirection = TextDirection.ltr,
}) {
  final distance = anchorToBubbleDistance(style);
  final bubble = style.padding.inflateSize(contentSize);
  double space(AxisDirection side) =>
      _availableSpace(side, viewport, anchor, distance);
  bool fits(AxisDirection side) => axisDirectionToAxis(side) == Axis.vertical
      ? bubble.height <= space(side) && bubble.width <= viewport.width
      : bubble.width <= space(side) && bubble.height <= viewport.height;

  final (start, end) = switch (textDirection) {
    TextDirection.ltr => (AxisDirection.left, AxisDirection.right),
    TextDirection.rtl => (AxisDirection.right, AxisDirection.left),
  };
  final preferred = switch (placement) {
    ArrowPopupPlacement.auto || ArrowPopupPlacement.below => AxisDirection.down,
    ArrowPopupPlacement.above => AxisDirection.up,
    ArrowPopupPlacement.left => AxisDirection.left,
    ArrowPopupPlacement.right => AxisDirection.right,
    ArrowPopupPlacement.start => start,
    ArrowPopupPlacement.end => end,
  };
  final opposite = flipAxisDirection(preferred);
  final (sideA, sideB) = axisDirectionToAxis(preferred) == Axis.vertical
      ? (AxisDirection.right, AxisDirection.left)
      : (AxisDirection.down, AxisDirection.up);
  final perpendicularSides = space(sideB) > space(sideA)
      ? [sideB, sideA]
      : [sideA, sideB];
  final order = placement == ArrowPopupPlacement.auto
      ? [AxisDirection.down, AxisDirection.up, end, start]
      : [preferred, opposite, ...perpendicularSides];

  for (final side in order) {
    if (fits(side)) return (side: side, fits: true, coversAnchor: false);
  }
  final side = space(opposite) > space(preferred) ? opposite : preferred;
  final extent = axisDirectionToAxis(side) == Axis.vertical
      ? viewport.height
      : viewport.width;
  return (
    side: side,
    fits: false,
    coversAnchor: space(side) < extent * _minUsableSpaceFraction,
  );
}
