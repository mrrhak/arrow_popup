part of 'arrow_popup.dart';

/// Opens and closes an [ArrowPopup] from code.
///
/// Pass it to one [ArrowPopup] with `controller:`. A controller can be used
/// by only one [ArrowPopup] at a time, and is free again once that
/// [ArrowPopup] is removed or given another controller.
///
/// ```dart
/// final controller = ArrowPopupController();
///
/// ArrowPopup(
///   controller: controller,
///   trigger: ArrowPopupTrigger.none,
///   content: const Text('Try this new feature'),
///   child: const Icon(Icons.star),
/// )
///
/// // Later, such as when an onboarding step starts:
/// controller.show();
/// ```
///
/// To open a popup from the button it points at, [ArrowPopup.builder] needs
/// no controller.
///
/// [T] is the type of value the popup closes with, as in the [ArrowPopup] it
/// is passed to, and must be that [ArrowPopup]'s type exactly. Dart accepts
/// a controller of a narrower type, such as an `ArrowPopupController<String>`
/// for an `ArrowPopup<String?>`, but the popup asserts in debug builds, and
/// in release builds throws a [TypeError]. Leave the type off the
/// [ArrowPopup] and it takes the controller's.
///
/// Listeners are notified when [isOpen] changes, so a [ListenableBuilder]
/// can rebuild when the popup opens or closes. Like any [ChangeNotifier],
/// call [dispose] when it is no longer needed, such as in the `dispose` of
/// the [State] that created it.
class ArrowPopupController<T> extends ChangeNotifier {
  /// Creates a controller that is not yet used by an [ArrowPopup].
  ArrowPopupController();

  _ArrowPopupState<T>? _state;
  bool _disposed = false;

  /// Whether the popup is showing.
  ///
  /// False when no [ArrowPopup] uses this controller. Listeners are notified
  /// when it changes.
  bool get isOpen => _state?._isOpen ?? false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // For changes made while the tree is locked, when listeners can't rebuild.
  void _notifyAfterFrame() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _notify());
  }

  /// Opens the popup. Completes when it starts closing, with the value passed
  /// to [ArrowPopup.close] from inside the content, or null when it is
  /// dismissed.
  ///
  /// The popup is still fading out then, for [ArrowPopup.transitionDuration].
  /// To open another popup right after, as in a step-by-step tour, wait that
  /// long first, so the two don't show at once.
  ///
  /// It opens as if its trigger were used, so [ArrowPopup.onOpen] and
  /// [ArrowPopup.onClose] are called too. If it is already open, this
  /// completes when that popup closes.
  ///
  /// The controller must be passed to an [ArrowPopup] that is in the tree
  /// and has been laid out, such as when called from a button, and some part
  /// of the anchor must be visible, not scrolled out of view. Otherwise it
  /// asserts in debug builds, and in release builds the popup doesn't open
  /// and this completes with null.
  Future<T?> show() {
    assert(
      !_disposed,
      'ArrowPopupController.show was called after the controller was '
      'disposed.\n'
      'Call dispose only once the ArrowPopup that uses it is gone.',
    );
    assert(
      _state != null,
      'ArrowPopupController.show was called, but no ArrowPopup uses this '
      'controller.\n'
      'Pass it to an ArrowPopup with `controller:`, and call show once that '
      'ArrowPopup is in the tree.',
    );
    return _state?.show() ?? Future<T?>.value();
  }

  /// Closes the popup if it is showing, otherwise opens it.
  ///
  /// Opening works as [show] does, and the future completes as it does. When
  /// it closes an open popup, the future completes with null right away, and
  /// the [show] that opened that popup completes with null too, as with
  /// [hide].
  ///
  /// The same requirements as [show] apply when it opens the popup.
  Future<T?> toggle() {
    if (isOpen) {
      hide();
      return Future<T?>.value();
    }
    return show();
  }

  /// Closes the popup if it is showing, as a dismissal, so [show] completes
  /// and [ArrowPopup.onClose] is called with null.
  ///
  /// [ArrowPopup.onClose] is called before this returns, so a [show] right
  /// after it calls [ArrowPopup.onOpen] after that, as in a step-by-step
  /// tour.
  ///
  /// Does nothing when the popup is closed or no [ArrowPopup] uses this
  /// controller.
  void hide() => _state?.hide();

  // Whether [state] can use this controller. An ArrowPopup of a wider type,
  // such as ArrowPopup<String?> for ArrowPopupController<String>, is given
  // this controller without complaint, but _attach would reject it.
  bool _accepts(Object state) => state is _ArrowPopupState<T>;

  void _attach(_ArrowPopupState<T> state) {
    final previous = _state;
    // A replaced ArrowPopup is only disposed, and one giving up the
    // controller only updated, after the next one attaches, so check after
    // the frame that the previous one is gone or uses another controller.
    assert(() {
      if (previous != null && previous != state) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          assert(
            !previous.mounted || previous.widget.controller != this,
            'An ArrowPopupController can only be used by one ArrowPopup at a '
            'time.',
          );
        });
      }
      return true;
    }());
    _state = state;
    // isOpen now follows this ArrowPopup's popup instead of the previous one.
    if (previous != state && ((previous?._isOpen ?? false) || state._isOpen)) {
      _notifyAfterFrame();
    }
  }

  void _detach(_ArrowPopupState<T> state) {
    if (_state != state) return;
    _state = null;
    if (state._isOpen) _notifyAfterFrame();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
