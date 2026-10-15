import 'package:flutter/widgets.dart';

/// Tracks where the anchor widget is, relative to the popup's overlay.
class ArrowPopupAnchor extends ChangeNotifier {
  /// Creates an anchor for [box], measured in [overlay]'s coordinates.
  ArrowPopupAnchor(this._box, this._overlay) {
    update();
  }

  final RenderBox _box;
  final RenderBox _overlay;
  bool _disposed = false;

  /// Whether the anchor's render object is still in the tree.
  bool get isAttached => _box.attached;

  /// The anchor's bounds when last measured.
  Rect get rect => _rect;
  Rect _rect = Rect.zero;

  /// Whether any part of the anchor showed when last measured: inside the
  /// overlay and not clipped away by an ancestor, such as a scroll view.
  bool get isVisible => _isVisible;
  bool _isVisible = true;

  /// Measures the anchor again and notifies listeners if it moved.
  ///
  /// Must not be called during layout. Keeps the last bounds once the anchor
  /// is gone.
  void update() {
    final rect = measure();
    if (rect == null) return;
    _isVisible = _visibleArea(_box, _overlay).overlaps(rect);
    if (rect == _rect) return;
    _rect = rect;
    notifyListeners();
  }

  /// The anchor's bounds now, or null once it is gone.
  ///
  /// Unlike [update], it neither stores the bounds nor notifies, so it can
  /// be called while painting.
  Rect? measure() {
    if (!_box.attached || !_overlay.attached || !_box.hasSize) return null;
    return _measure(_box, _overlay);
  }

  /// Whether any part of [box] shows now: inside [overlay] and not clipped
  /// away by an ancestor, such as a scroll view.
  ///
  /// [box] must be laid out.
  static bool isShowing(RenderBox box, RenderBox overlay) {
    return _visibleArea(box, overlay).overlaps(_measure(box, overlay));
  }

  // The bounds of [box] in [overlay]'s coordinates.
  static Rect _measure(RenderBox box, RenderBox overlay) {
    return MatrixUtils.transformRect(
      box.getTransformTo(overlay),
      Offset.zero & box.size,
    );
  }

  /// Measures the anchor again after every frame until [dispose], and calls
  /// [onLost] once its widget is removed, or once no part of it is visible
  /// unless [keepHidden] returns true.
  ///
  /// The anchor can move in any frame (scrolling, animation, rotation, the
  /// keyboard), so it is measured after each one. Post-frame callbacks don't
  /// schedule frames, so this costs nothing while the screen is idle.
  void track(VoidCallback onLost, {ValueGetter<bool>? keepHidden}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      // The anchor's widget was removed, so there is nothing to point at.
      if (!isAttached) {
        onLost();
        return;
      }
      update();
      // Scrolled out of view, so the arrow would point at nothing.
      if (!isVisible && !(keepHidden?.call() ?? false)) {
        onLost();
        return;
      }
      track(onLost, keepHidden: keepHidden);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Where the anchor can show, in the overlay's coordinates: the screen,
  // minus what its ancestors clip. Clips are rare, so this transforms only a
  // few rects.
  static Rect _visibleArea(RenderBox box, RenderBox overlay) {
    var area = Rect.largest;
    RenderObject child = box;
    // The overlay, or the top of the tree when the anchor is outside the
    // overlay, such as above a nested navigator. Either covers the screen.
    RenderBox screen = box;
    for (var parent = child.parent; parent != null; parent = parent.parent) {
      final clip = parent.describeApproximatePaintClip(child);
      if (clip != null) {
        area = area.intersect(
          MatrixUtils.transformRect(parent.getTransformTo(overlay), clip),
        );
      }
      if (parent is RenderBox) screen = parent;
      if (identical(parent, overlay)) break;
      child = parent;
    }
    return area.intersect(
      MatrixUtils.transformRect(
        screen.getTransformTo(overlay),
        Offset.zero & screen.size,
      ),
    );
  }
}
