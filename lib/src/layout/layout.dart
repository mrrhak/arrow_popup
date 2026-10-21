import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../config/enums.dart';
import '../config/style.dart';
import 'anchor.dart';
import 'geometry.dart';
import 'side_picker.dart';

/// Fills its parent and places [child] in a bubble that points at [anchor].
class ArrowPopupLayout extends SingleChildRenderObjectWidget {
  /// Creates the popup layout.
  const ArrowPopupLayout({
    super.key,
    required this.anchor,
    required this.safeArea,
    required this.style,
    required this.color,
    required this.placement,
    required this.scale,
    this.textDirection,
    super.child,
  });

  /// The widget the arrow points at.
  final ArrowPopupAnchor anchor;

  /// Insets the bubble must stay clear of, such as system bars.
  final EdgeInsets safeArea;

  /// Visual settings.
  final ArrowPopupStyle style;

  /// Resolved fill color.
  final Color color;

  /// Which side of the anchor to use.
  final ArrowPopupPlacement placement;

  /// Scales the bubble out of the arrow's tip, from 0 to 1.
  final Animation<double> scale;

  /// Resolves directional padding and the start and end placements.
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  @override
  RenderArrowPopupLayout createRenderObject(BuildContext context) {
    return RenderArrowPopupLayout(
      anchor: anchor,
      safeArea: safeArea,
      style: style,
      color: color,
      placement: placement,
      scale: scale,
      textDirection: textDirection ?? Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderArrowPopupLayout renderObject,
  ) {
    renderObject
      ..anchor = anchor
      ..safeArea = safeArea
      ..style = style
      ..color = color
      ..placement = placement
      ..scale = scale
      ..textDirection = textDirection ?? Directionality.of(context);
  }
}

/// Render object for [ArrowPopupLayout].
class RenderArrowPopupLayout extends RenderShiftedBox {
  /// Creates the render object.
  RenderArrowPopupLayout({
    required this._anchor,
    required this._safeArea,
    required ArrowPopupStyle style,
    required this._color,
    required this._placement,
    required this._scale,
    required this._textDirection,
    RenderBox? child,
  }) : _style = style,
       assert(_debugCheckStyle(style)),
       super(child);

  // The const style constructor can't check these, so check them here.
  static bool _debugCheckStyle(ArrowPopupStyle style) {
    assert(
      style.arrowSize.width >= 0 && style.arrowSize.height >= 0,
      'ArrowPopupStyle.arrowSize must not be negative',
    );
    assert(
      style.padding.isNonNegative,
      'ArrowPopupStyle.padding must not be negative',
    );
    return true;
  }

  ArrowPopupAnchor _anchor;
  set anchor(ArrowPopupAnchor value) {
    if (identical(value, _anchor)) return;
    if (attached) _anchor.removeListener(markNeedsLayout);
    _anchor = value;
    if (attached) _anchor.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  EdgeInsets _safeArea;
  set safeArea(EdgeInsets value) {
    if (value == _safeArea) return;
    _safeArea = value;
    markNeedsLayout();
  }

  ArrowPopupStyle _style;
  set style(ArrowPopupStyle value) {
    if (value == _style) return;
    assert(_debugCheckStyle(value));
    _style = value;
    markNeedsLayout();
  }

  Color _color;
  set color(Color value) {
    if (value == _color) return;
    _color = value;
    markNeedsPaint();
  }

  ArrowPopupPlacement _placement;
  set placement(ArrowPopupPlacement value) {
    if (value == _placement) return;
    _placement = value;
    markNeedsLayout();
  }

  Animation<double> _scale;
  set scale(Animation<double> value) {
    if (identical(value, _scale)) return;
    if (attached) _scale.removeListener(markNeedsPaint);
    _scale = value;
    if (attached) _scale.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  // From the last layout: the area the bubble stays in, where the anchor
  // was, and where that put the bubble.
  Rect _viewport = Rect.zero;
  Rect _laidOutAnchor = Rect.zero;
  ArrowPopupGeometry? _laidOutGeometry;
  // Where the bubble is painted, which follows the anchor between layouts,
  // and how far that moved it from where it was laid out.
  Rect _paintedAnchor = Rect.zero;
  ArrowPopupGeometry? _paintedGeometry;
  Path? _path;
  Offset _paintOffset = Offset.zero;
  int? _followCallbackId;
  final LayerHandle<TransformLayer> _transformLayer =
      LayerHandle<TransformLayer>();
  final LayerHandle<ClipRRectLayer> _clipLayer = LayerHandle<ClipRRectLayer>();

  /// Where the bubble was last painted, for tests.
  @visibleForTesting
  ArrowPopupGeometry? get geometry => _paintedGeometry;

  // Repainted every frame, often while the anchor moves, so this keeps it
  // from repainting what is around it.
  @override
  bool get isRepaintBoundary => true;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _anchor.addListener(markNeedsLayout);
    _scale.addListener(markNeedsPaint);
    _scheduleFollow();
  }

  @override
  void detach() {
    if (_followCallbackId case final id?) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(id);
      _followCallbackId = null;
    }
    _anchor.removeListener(markNeedsLayout);
    _scale.removeListener(markNeedsPaint);
    super.detach();
  }

  // The anchor can move in any frame, such as while a list scrolls, but is
  // only measured again after it. So repaint at the start of every frame,
  // and paint, which comes after all of the frame's layout, moves the bubble
  // to wherever the anchor is by then. Like
  // OverlayPortal.overlayChildLayoutBuilder, this asks for no frames itself,
  // so it costs nothing while the screen is idle.
  void _scheduleFollow() {
    _followCallbackId = SchedulerBinding.instance.scheduleFrameCallback((_) {
      _followCallbackId = null;
      if (!attached) return;
      markNeedsPaint();
      _scheduleFollow();
    }, scheduleNewFrame: false);
  }

  @override
  void dispose() {
    _transformLayer.layer = null;
    _clipLayer.layer = null;
    super.dispose();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      _laidOutGeometry = null;
      _paintedGeometry = null;
      _path = null;
      _paintOffset = Offset.zero;
      return;
    }

    final viewport = _bubbleViewport();
    final anchorRect = _anchor.rect;
    final geometry = _layoutChildAndPlaceBubble(child, viewport, anchorRect);
    (child.parentData! as BoxParentData).offset =
        geometry.box.topLeft + _style.padding.resolve(_textDirection).topLeft;
    _viewport = viewport;
    _laidOutAnchor = anchorRect;
    _laidOutGeometry = geometry;
    _paintedAnchor = anchorRect;
    _paintedGeometry = geometry;
    _path = geometry.path;
    _paintOffset = Offset.zero;
  }

  // The area the bubble must stay inside: the screen minus the safe area and
  // the style's margin.
  Rect _bubbleViewport() {
    final margin = _style.screenMargin;
    return Rect.fromLTRB(
      _safeArea.left + margin,
      _safeArea.top + margin,
      size.width - _safeArea.right - margin,
      size.height - _safeArea.bottom - margin,
    );
  }

  // Measures the content at its natural size and picks a side it fits on,
  // then returns where the bubble goes there.
  ArrowPopupGeometry _layoutChildAndPlaceBubble(
    RenderBox child,
    Rect viewport,
    Rect anchorRect,
  ) {
    child.layout(
      arrowPopupNaturalConstraints(viewport: viewport, style: _style),
      parentUsesSize: true,
    );
    final (:side, :fits, :coversAnchor) = arrowPopupSide(
      contentSize: child.size,
      viewport: viewport,
      anchor: anchorRect,
      style: _style,
      placement: _placement,
      textDirection: _textDirection,
    );
    // It fits on no side, so shrink it to the room on the chosen one, unless
    // that room is so small that it covers the anchor instead.
    if (!fits && !coversAnchor) {
      child.layout(
        arrowPopupSideConstraints(
          viewport: viewport,
          anchor: anchorRect,
          style: _style,
          side: side,
        ),
        parentUsesSize: true,
      );
    }
    return ArrowPopupGeometry.layout(
      contentSize: child.size,
      viewport: viewport,
      anchor: anchorRect,
      style: _style,
      side: side,
      coversAnchor: coversAnchor,
    );
  }

  // Moves the bubble to where the anchor is now, keeping the side and size
  // from layout. If the new spot calls for another side, the next layout
  // picks it, once the anchor has been measured again.
  void _follow() {
    final laidOut = _laidOutGeometry;
    final rect = _anchor.measure();
    // Once the anchor is gone, stay put until the popup closes.
    if (laidOut == null || rect == null || rect == _paintedAnchor) return;
    final geometry = rect == _laidOutAnchor
        ? laidOut
        : ArrowPopupGeometry.layout(
            contentSize: child!.size,
            viewport: _viewport,
            anchor: rect,
            style: _style,
            side: laidOut.side,
            coversAnchor: laidOut.coversAnchor,
          );
    _paintedAnchor = rect;
    _paintedGeometry = geometry;
    _path = geometry.path;
    _paintOffset = geometry.box.topLeft - laidOut.box.topLeft;
  }

  Matrix4 _scaleAround(double scale, Offset origin) {
    return Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(origin.dx * (1 - scale), origin.dy * (1 - scale), 0);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _follow();
    final geometry = _paintedGeometry;
    final scale = _scale.value;
    if (child == null || geometry == null || scale <= 0) {
      _transformLayer.layer = null;
      _clipLayer.layer = null;
      return;
    }
    if (scale >= 1) {
      _transformLayer.layer = null;
      _paintBubble(context, offset);
      return;
    }
    _transformLayer.layer = context.pushTransform(
      needsCompositing,
      offset,
      _scaleAround(scale, geometry.tip),
      _paintBubble,
      oldLayer: _transformLayer.layer,
    );
  }

  void _paintBubble(PaintingContext context, Offset offset) {
    final path = _path!.shift(offset);
    final canvas = context.canvas;
    for (final shadow in _style.shadows) {
      canvas.drawPath(path.shift(shadow.offset), shadow.toPaint());
    }
    canvas.drawPath(path, Paint()..color = _color);
    if (_style.clipBehavior == Clip.none) {
      _clipLayer.layer = null;
      _paintChild(context, offset);
    } else {
      final geometry = _paintedGeometry!;
      _clipLayer.layer = context.pushClipRRect(
        needsCompositing,
        offset,
        geometry.box,
        RRect.fromRectAndRadius(geometry.box, Radius.circular(geometry.radius)),
        _paintChild,
        clipBehavior: _style.clipBehavior,
        oldLayer: _clipLayer.layer,
      );
    }
    // Over the content, so content without padding doesn't hide it.
    final border = _style.border;
    // A width of 0 draws a hairline, as elsewhere in Flutter.
    if (border.style != BorderStyle.none) {
      // The canvas may have changed while painting the child.
      context.canvas.drawPath(path, border.toPaint());
    }
  }

  void _paintChild(PaintingContext context, Offset offset) {
    final childParentData = child!.parentData! as BoxParentData;
    context.paintChild(child!, offset + childParentData.offset + _paintOffset);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final geometry = _paintedGeometry;
    final scale = _scale.value;
    if (geometry != null && scale > 0 && scale < 1) {
      transform.multiply(_scaleAround(scale, geometry.tip));
    }
    transform.multiply(
      Matrix4.translationValues(_paintOffset.dx, _paintOffset.dy, 0),
    );
    super.applyPaintTransform(child, transform);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    final childParentData = child.parentData! as BoxParentData;
    // Where the content was painted, not where it was laid out.
    return result.addWithPaintOffset(
      offset: childParentData.offset + _paintOffset,
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Only the bubble as painted is hit, so taps elsewhere reach the barrier
    // below, even while it is still growing.
    final path = _path;
    final geometry = _paintedGeometry;
    final scale = _scale.value;
    if (path == null || geometry == null || scale <= 0) return false;
    final tip = geometry.tip;
    final unscaled = scale >= 1 ? position : tip + (position - tip) / scale;
    if (!path.contains(unscaled)) return false;
    // Ignore the content while it is scaling in or out.
    if (scale >= 1) hitTestChildren(result, position: position);
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
}
