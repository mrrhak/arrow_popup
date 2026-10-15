import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../config/enums.dart';
import '../config/style.dart';
import '../layout/anchor.dart';
import 'bubble.dart';
import 'scope.dart';

/// The route behind [ArrowPopup.show].
class ArrowPopupRoute<T> extends PopupRoute<T> {
  /// Creates a route anchored to the widget of [anchorContext].
  ///
  /// Themes and localizations come from [context], which must be below
  /// [navigator]. [anchorContext] only says where to point, so it may be
  /// anywhere on screen.
  ArrowPopupRoute({
    required BuildContext context,
    required BuildContext anchorContext,
    required NavigatorState navigator,
    required Widget content,
    required ArrowPopupStyle? style,
    required ArrowPopupPlacement placement,
    this.semanticLabel,
    super.settings,
    required this.barrierColor,
    required this.barrierDismissible,
    required this.transitionDuration,
    required this.curve,
    this.autoCloseDuration = Duration.zero,
  }) : assert(
         autoCloseDuration >= Duration.zero,
         'autoCloseDuration must not be negative',
       ),
       _liveContent = ValueNotifier((
         content: content,
         style: style,
         placement: placement,
       )),
       anchor = ArrowPopupAnchor(
         anchorContext.findRenderObject()! as RenderBox,
         navigator.overlay!.context.findRenderObject()! as RenderBox,
       ),
       // Keep themes set between the navigator and the popup's caller.
       capturedThemes = InheritedTheme.capture(
         from: context,
         to: navigator.context,
       ),
       // Not a theme, so capturing themes doesn't keep it.
       textDirection = Directionality.of(context),
       barrierLabel =
           Localizations.of<MaterialLocalizations>(
             context,
             MaterialLocalizations,
           )?.modalBarrierDismissLabel ??
           Localizations.of<CupertinoLocalizations>(
             context,
             CupertinoLocalizations,
           )?.modalBarrierDismissLabel ??
           'Dismiss';

  final ValueNotifier<
    ({Widget content, ArrowPopupStyle? style, ArrowPopupPlacement placement})
  >
  _liveContent;

  /// Replaces what the open popup shows.
  ///
  /// Must not be called during a build.
  void update({
    required Widget content,
    required ArrowPopupStyle? style,
    required ArrowPopupPlacement placement,
  }) {
    _liveContent.value = (content: content, style: style, placement: placement);
  }

  /// What screen readers announce when the popup opens.
  final String? semanticLabel;

  /// Curve for the fade and scale transition.
  final Curve curve;

  /// The widget the arrow points at.
  final ArrowPopupAnchor anchor;

  /// Themes captured from where the popup was shown.
  final CapturedThemes capturedThemes;

  /// Text direction where the popup was shown, which decides the start and
  /// end placements, directional padding and the content's direction.
  final TextDirection textDirection;

  @override
  final Color? barrierColor;

  @override
  final bool barrierDismissible;

  @override
  final String barrierLabel;

  @override
  final Duration transitionDuration;

  CurvedAnimation? _curved;
  // Set by buildPage, which rebuilds when the keyboard opens or closes.
  bool _keyboardOpen = false;
  Timer? _autoClose;

  /// How long after opening the popup closes by itself, or [Duration.zero]
  /// to stay open until it is dismissed.
  final Duration autoCloseDuration;

  @override
  void install() {
    super.install();
    // While the keyboard is open, it is usually what hides the anchor, as
    // when the Scaffold shrinks a list to make room for it, and the popup is
    // in use, so it stays above the keyboard instead.
    anchor.track(close, keepHidden: () => _keyboardOpen);
  }

  /// Whether the auto-close timer is still waiting to close the popup.
  @visibleForTesting
  bool get debugAutoClosePending => _autoClose?.isActive ?? false;

  @override
  TickerFuture didPush() {
    if (autoCloseDuration > Duration.zero) {
      _autoClose = Timer(autoCloseDuration, close);
    }
    return super.didPush();
  }

  // Runs however the popup closes: a tap outside, Escape, a pop from the
  // content, hide, or the timer itself. Once closed there is nothing left
  // to close, so stop the timer now rather than after the close animation.
  @override
  void didComplete(T? result) {
    _autoClose?.cancel();
    super.didComplete(result);
  }

  /// Closes the popup with [result], even when another route is above it.
  void close([T? result]) {
    // Once popped, a route is no longer active, so this never closes twice.
    if (!isActive) return;
    if (isCurrent) {
      navigator!.pop(result);
    } else {
      navigator!.removeRoute(this, result);
    }
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final curved = _curved ??= CurvedAnimation(parent: animation, curve: curve);
    _keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return capturedThemes.wrap(
      Directionality(
        textDirection: textDirection,
        child: ValueListenableBuilder(
          valueListenable: _liveContent,
          builder: (context, config, _) => ArrowPopupBubble(
            anchor: anchor,
            animation: curved,
            content: config.content,
            style: config.style,
            placement: config.placement,
            semanticLabel: semanticLabel,
            scopesRoute: true,
            onClose: (value) => close(arrowPopupResult<T>(value)),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _liveContent.dispose();
    _curved?.dispose();
    anchor.dispose();
    super.dispose();
  }
}
