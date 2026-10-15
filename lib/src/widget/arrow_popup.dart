import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../config/constants.dart';
import '../config/enums.dart';
import '../config/platform.dart';
import '../config/style.dart';
import '../layout/anchor.dart';
import '../route/bubble.dart';
import '../route/route.dart';
import '../route/scope.dart';

part 'arrow_popup_controller.dart';
part 'arrow_popup_state.dart';

/// Builds the widget an [ArrowPopup.builder] points at. Call [show] to open
/// the popup, such as from a button's `onPressed`; it completes as
/// [ArrowPopupController.show] does.
typedef ArrowPopupAnchorBuilder<T> =
    Widget Function(BuildContext context, Future<T?> Function() show);

/// Shows [content] in a bubble with an arrow pointing at [child] when
/// [child] is tapped (or long-pressed or double-tapped, see [trigger]).
///
/// If [child] handles the same gesture itself, such as an enabled button, it
/// wins and the popup doesn't open. Use [ArrowPopup.builder] instead and
/// open it from the button's `onPressed`.
///
/// If [content] can be taller than the screen, wrap it in a scroll view.
///
/// It must be below a [Navigator] when it opens, as in any screen of a
/// [MaterialApp]. It is not in the `builder` of an app, which is above the
/// navigator: opening it there throws Flutter's "Navigator operation
/// requested with a context that does not include a Navigator". Hover
/// popups only need an [Overlay], which a navigator provides.
///
/// Except when opened by mouse hover, the popup is a route, so [content] is
/// built in the navigator's overlay. It gets the theme and text direction
/// from here, but not other inherited widgets between the navigator and this
/// widget, such as a provider. Read those outside and
/// pass the values in, or provide them again around [content].
///
/// To close with a value, as a menu does, call [ArrowPopup.close] from inside
/// [content]. [T] is that value's type; [onClose] and
/// [ArrowPopupController.show] receive it.
///
/// While the popup is open, changes to [content], [style] and [placement]
/// show right away. The other settings apply the next time it opens.
class ArrowPopup<T> extends StatefulWidget {
  /// Creates an arrow popup.
  const ArrowPopup({
    super.key,
    required this.content,
    required this.child,
    this.controller,
    this.trigger = ArrowPopupTrigger.tap,
    this.style,
    this.placement = ArrowPopupPlacement.auto,
    this.anchorKey,
    this.focusable = true,
    this.focusDecoration,
    this.semanticLabel,
    this.routeSettings,
    this.barrierColor = defaultBarrierColor,
    this.barrierDismissible = true,
    this.useRootNavigator = false,
    this.transitionDuration = defaultTransitionDuration,
    this.curve = defaultCurve,
    this.autoCloseDuration = Duration.zero,
    this.waitDuration = Duration.zero,
    this.onOpen,
    this.onClose,
  }) : builder = null;

  /// Creates an arrow popup that [builder] opens, such as from a button:
  ///
  /// ```dart
  /// ArrowPopup.builder(
  ///   content: const Text('Saved to your library'),
  ///   builder: (context, show) => IconButton(
  ///     icon: const Icon(Icons.info_outline),
  ///     onPressed: show,
  ///   ),
  /// )
  /// ```
  ///
  /// The built widget handles its own taps and keyboard focus, so the popup
  /// adds no [trigger] and is not [focusable] itself. By default, the arrow
  /// points at the built widget.
  const ArrowPopup.builder({
    super.key,
    required this.content,
    required ArrowPopupAnchorBuilder<T> this.builder,
    this.controller,
    this.style,
    this.placement = ArrowPopupPlacement.auto,
    this.anchorKey,
    this.semanticLabel,
    this.routeSettings,
    this.barrierColor = defaultBarrierColor,
    this.barrierDismissible = true,
    this.useRootNavigator = false,
    this.transitionDuration = defaultTransitionDuration,
    this.curve = defaultCurve,
    this.autoCloseDuration = Duration.zero,
    this.onOpen,
    this.onClose,
  }) : child = null,
       trigger = ArrowPopupTrigger.none,
       focusable = false,
       focusDecoration = null,
       waitDuration = Duration.zero;

  /// The widget shown in the bubble.
  ///
  /// It is given up to the screen's height, so a [Column] fills it unless it
  /// has `mainAxisSize: MainAxisSize.min`.
  final Widget content;

  /// The widget that opens the popup and, by default, that the arrow points
  /// at.
  ///
  /// Null when created with [ArrowPopup.builder].
  final Widget? child;

  /// Builds the widget the arrow points at by default, given a function that
  /// opens the popup.
  ///
  /// Null unless created with [ArrowPopup.builder].
  final ArrowPopupAnchorBuilder<T>? builder;

  /// Opens and closes the popup from code.
  final ArrowPopupController<T>? controller;

  /// The gesture on [child] that opens the popup.
  final ArrowPopupTrigger trigger;

  /// Visual settings for the bubble and arrow.
  ///
  /// Defaults to [ArrowPopupStyle.of] the theme.
  final ArrowPopupStyle? style;

  /// Which side of the anchor the bubble appears on.
  final ArrowPopupPlacement placement;

  /// Points the arrow at another widget instead of [child].
  ///
  /// That widget must be in the tree when the popup opens. Otherwise the
  /// popup asserts in debug builds, and in release builds doesn't open.
  final GlobalKey? anchorKey;

  /// Whether [child] can take keyboard focus and open the popup with Enter or
  /// Space.
  ///
  /// Set this to false when [child] can already take focus, such as a button,
  /// so it isn't focused twice and screen readers don't find a button inside
  /// a button. Better still, open the popup from the button's `onPressed`
  /// with [ArrowPopup.builder]. Ignored when [trigger] is
  /// [ArrowPopupTrigger.none].
  ///
  /// While focused from the keyboard, [child] shows [focusDecoration].
  /// Opening the popup with a click or touch takes that focus away, so the
  /// outline doesn't come back when the popup closes.
  final bool focusable;

  /// Drawn over [child] while it has keyboard focus.
  ///
  /// Defaults to a 2 pixel outline in the theme's primary color with
  /// rounded corners. Pass `BoxDecoration()` to draw nothing, such as when
  /// [child] shows its own focus, or a decoration that fits its shape:
  ///
  /// ```dart
  /// ShapeDecoration(
  ///   shape: CircleBorder(side: BorderSide(color: Colors.teal, width: 2)),
  /// )
  /// ```
  final Decoration? focusDecoration;

  /// What screen readers announce when the popup opens, such as "Options".
  ///
  /// With [ArrowPopupTrigger.hover], screen readers also read it as the
  /// anchor's tooltip when they reach [child], since a popup opened by mouse
  /// hover is not announced. Set it to the popup's text, such as
  /// "Bold, Command B", so they hear what the popup shows.
  final String? semanticLabel;

  /// Name and arguments of the popup's route, for navigator observers such
  /// as analytics.
  ///
  /// A popup opened by mouse hover is not a route, so it ignores this.
  final RouteSettings? routeSettings;

  /// Color of the barrier behind the popup.
  final Color? barrierColor;

  /// Whether tapping outside the bubble closes it.
  final bool barrierDismissible;

  /// Whether to show the popup on the root navigator.
  ///
  /// A popup opened by mouse hover is not a route, so it ignores this and
  /// shows in the nearest overlay, as Flutter's `Tooltip` does.
  final bool useRootNavigator;

  /// Length of the open and close transition.
  final Duration transitionDuration;

  /// Curve of the open and close transition.
  final Curve curve;

  /// How long after opening the popup closes by itself, as a dismissal, so
  /// [onClose] gets null. The default, [Duration.zero], never closes it by
  /// itself.
  ///
  /// Useful for brief confirmations, such as "Copied" or "Liked!".
  ///
  /// A popup opened by mouse hover ignores it and closes once the mouse
  /// leaves instead. Opened by tap, such as on a touch screen, it still
  /// closes by itself.
  final Duration autoCloseDuration;

  /// How long the mouse must rest on [child] before a popup opened by
  /// [ArrowPopupTrigger.hover] shows. If the mouse leaves sooner, the popup
  /// doesn't open and [onOpen] isn't called. The default, [Duration.zero],
  /// opens it right away, as Flutter's `Tooltip` does.
  ///
  /// Useful for toolbars, so moving the mouse across them doesn't flash a
  /// popup for every icon on the way.
  ///
  /// Only mouse hover waits. A tap, the keyboard and
  /// [ArrowPopupController.show] open the popup right away.
  final Duration waitDuration;

  /// Called just before the popup opens.
  ///
  /// [ArrowPopupController.show] called from here doesn't open a second
  /// popup; it completes when this one closes.
  ///
  /// [ArrowPopupController.hide] called from here keeps the popup from
  /// opening, as if it were dismissed right away: [onClose] is called with
  /// null, and [ArrowPopupController.show] completes with null.
  final VoidCallback? onOpen;

  /// Called after the popup has closed, with the value passed to
  /// [ArrowPopup.close] from inside [content], or null when it was
  /// dismissed.
  ///
  /// Not called if this [ArrowPopup] has been removed, such as when the
  /// popup closes because its anchor is gone. [ArrowPopupController.show]
  /// still completes then, with null.
  final ValueChanged<T?>? onClose;

  /// Shows [content] in a bubble with an arrow pointing at the widget that
  /// [context] belongs to.
  ///
  /// The returned future completes with the value passed to `ArrowPopup.close`
  /// (or `Navigator.pop`) from inside [content], or null when the popup is
  /// dismissed. The popup also closes, with null, when the widget it points at
  /// is removed.
  ///
  /// If [content] can be taller than the screen, wrap it in a scroll view.
  ///
  /// [content] is built in the navigator's overlay. It gets the theme and text
  /// direction from [context], but not other inherited widgets between the
  /// navigator and [context], such as a provider. Read
  /// those from [context] and pass the values in, or provide them again around
  /// [content].
  ///
  /// [style] defaults to [ArrowPopupStyle.of] the theme.
  ///
  /// [semanticLabel] is what screen readers announce when the popup opens.
  /// [routeSettings] names the popup's route for navigator observers.
  ///
  /// With a positive [autoCloseDuration], the popup closes by itself that long
  /// after it opens, and the future completes with null, as when it is
  /// dismissed. The default, [Duration.zero], never closes it by itself.
  ///
  /// [context] must be a box widget that has been laid out, such as when called
  /// from its `onPressed`, and some part of it must be visible. Otherwise it
  /// asserts in debug builds, and in release builds the popup doesn't open and
  /// the future completes with null.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget content,
    ArrowPopupStyle? style,
    ArrowPopupPlacement placement = ArrowPopupPlacement.auto,
    String? semanticLabel,
    RouteSettings? routeSettings,
    Color? barrierColor = defaultBarrierColor,
    bool barrierDismissible = true,
    bool useRootNavigator = false,
    Duration transitionDuration = defaultTransitionDuration,
    Curve curve = defaultCurve,
    Duration autoCloseDuration = Duration.zero,
  }) {
    final anchorBox = context.findRenderObject();
    assert(
      anchorBox is RenderBox && anchorBox.hasSize,
      'ArrowPopup.show was called with a context that is not a laid-out box '
      'widget.\n'
      'Pass the context of the widget the arrow should point at, after it has '
      'been laid out (for example from its onPressed callback). Slivers '
      'cannot be anchors.',
    );
    if (anchorBox is! RenderBox || !anchorBox.hasSize) return Future.value();
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    final isAnchorVisible = ArrowPopupAnchor.isShowing(
      anchorBox,
      navigator.overlay!.context.findRenderObject()! as RenderBox,
    );
    assert(
      isAnchorVisible,
      'ArrowPopup.show was called for a widget that is not visible, such as '
      'one scrolled out of view.\n'
      'Scroll it into view first, for example with Scrollable.ensureVisible, '
      'and call ArrowPopup.show once that is done.',
    );
    // Reached only in release builds, where the assert above is removed.
    if (!isAnchorVisible) return Future.value(); // coverage:ignore-line
    return navigator.push(
      ArrowPopupRoute<T>(
        context: context,
        anchorContext: context,
        navigator: navigator,
        content: content,
        style: style,
        placement: placement,
        semanticLabel: semanticLabel,
        settings: routeSettings,
        barrierColor: barrierColor,
        barrierDismissible: barrierDismissible,
        transitionDuration: transitionDuration,
        curve: curve,
        autoCloseDuration: autoCloseDuration,
      ),
    );
  }

  /// Closes the popup that [context] is inside, with [value].
  ///
  /// Call it from inside the content of an [ArrowPopup] or [ArrowPopup.show],
  /// such as from a menu item's `onTap`. [value] goes to [onClose],
  /// [ArrowPopupController.show] or the future [ArrowPopup.show] returns.
  /// Without a value, it closes as a dismissal, with null.
  ///
  /// [value] must be of the popup's type, such as a [String] for an
  /// `ArrowPopup<String>`. Otherwise it asserts in debug builds, and in
  /// release builds throws a [TypeError].
  ///
  /// `Navigator.pop` also works, except in a popup opened by mouse hover,
  /// which is not a route: there it would close the screen below instead.
  /// This works either way.
  ///
  /// [context] must be inside the content, such as from a [Builder] around
  /// it. Otherwise it asserts in debug builds, and in release builds does
  /// nothing.
  static void close<T>(BuildContext context, [T? value]) {
    final scope = context.getInheritedWidgetOfExactType<ArrowPopupScope>();
    assert(
      scope != null,
      'ArrowPopup.close was called with a context that is not inside an '
      'arrow popup.\n'
      'Call it with the context of a widget inside the popup\'s content, for '
      'example by wrapping the content in a Builder.',
    );
    scope?.close(value);
  }

  @override
  State<ArrowPopup<T>> createState() => _ArrowPopupState<T>();
}
