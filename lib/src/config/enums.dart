import 'style.dart';

/// Which side of its anchor an arrow popup prefers.
///
/// The popup opens on that side if it fits there. Otherwise it opens on the
/// opposite side, then on one of the other two, the roomier first, so it
/// never overflows. [auto] tries the sides in a fixed order instead. If it
/// fits nowhere, it shrinks to the room on the preferred side or its
/// opposite, whichever is larger, so wrap content that can be tall in a
/// scroll view. When even that room is under a quarter of
/// the screen, as beside an anchor that fills it, the bubble is centered over
/// the anchor instead, without an arrow.
///
/// Content is measured at its natural width, so long text may not fit beside
/// the anchor. Set [ArrowPopupStyle.maxWidth] to make it wrap sooner.
enum ArrowPopupPlacement {
  /// The first side the bubble fits on, trying below, above, [end] and
  /// [start] in that order: right before left in left-to-right text. When it
  /// fits on none, it shrinks to fit below or above, whichever has more room.
  auto,

  /// Above the anchor.
  above,

  /// Below the anchor.
  below,

  /// To the left of the anchor, whatever the text direction.
  left,

  /// To the right of the anchor, whatever the text direction.
  right,

  /// Before the anchor in reading order: to its left in left-to-right text,
  /// to its right in right-to-left text.
  start,

  /// After the anchor in reading order: to its right in left-to-right text,
  /// to its left in right-to-left text.
  end,
}

/// The gesture on the anchor that opens an [ArrowPopup].
///
/// [ArrowPopup]: package:arrow_popup/arrow_popup.dart
enum ArrowPopupTrigger {
  /// Opens on tap.
  tap,

  /// Opens on long press.
  longPress,

  /// Opens on double tap.
  doubleTap,

  /// Opens while a mouse is over the anchor, like a tooltip, and closes
  /// shortly after it has left both the anchor and the bubble, so the mouse
  /// can move into the bubble. Escape closes it too, without moving the
  /// mouse. Set `ArrowPopup.waitDuration` to open it only once the mouse
  /// has rested on the anchor that long, and `ArrowPopup.closeDelay` to
  /// change how long it stays after the mouse leaves.
  ///
  /// A popup opened this way doesn't dim the screen, block taps outside it
  /// or take keyboard focus. Touch screens can't hover, so there it opens
  /// on tap instead, like [tap]. A click, Enter or Space on the anchor while
  /// the bubble is already open leaves it open, as hovering already opened
  /// it. Otherwise, Enter or Space on the focused anchor opens a regular
  /// popup, with a barrier and focus.
  ///
  /// Unlike other popups, it is shown in the overlay rather than pushed as a
  /// route, so navigator observers don't see it, and `Navigator.pop` closes
  /// the screen below, not the popup. Close it from its content with
  /// `ArrowPopup.close`.
  ///
  /// Opened by touch, the keyboard or a controller, the same popup is a
  /// route, so its content can't see inherited widgets between the navigator
  /// and the anchor, such as a provider, which a mouse-opened one can.
  hover,

  /// Never opens from a gesture; use an `ArrowPopupController` instead.
  none,
}
