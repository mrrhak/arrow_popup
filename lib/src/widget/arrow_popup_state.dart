part of 'arrow_popup.dart';

class _ArrowPopupState<T> extends State<ArrowPopup<T>>
    with SingleTickerProviderStateMixin {
  ArrowPopupRoute<T>? _route;
  // Completes when the open popup, or the one being opened, closes.
  Completer<T?>? _closed;
  // While onOpen runs, before the popup is shown.
  bool _opening = false;
  // The wrappers around the child depend on trigger and focusable, so this
  // keeps the child's state when they change.
  final _childKey = GlobalKey();
  final _focusNode = FocusNode(debugLabel: 'ArrowPopup');
  bool _showFocus = false;

  // Hover trigger: where the mouse is, the pending open while it waits for
  // waitDuration, and the pending close once it has left both the anchor
  // and the bubble.
  static const _hoverCloseDelay = Duration(milliseconds: 100);
  bool _overAnchor = false;
  bool _overBubble = false;
  Timer? _hoverOpen;
  Timer? _hoverClose;

  // A popup opened on hover is a tooltip, shown in the overlay rather than
  // pushed as a route, so a Navigator.pop meant for the screen below, such
  // as from the hovered button, doesn't close it instead, and navigator
  // observers don't see every hover.
  final _hoverPortal = OverlayPortalController();
  // Created on the first hover, so other popups never make one.
  AnimationController? _hoverAnimation;
  CurvedAnimation? _hoverCurved;
  // Set while the hover popup shows, including while it fades out.
  ArrowPopupAnchor? _hoverAnchor;
  // Set while the hover popup is open; completes when it closes.
  Completer<T?>? _hoverClosed;

  bool get _isOpen => _route != null || _hoverClosed != null;

  @override
  void initState() {
    super.initState();
    _attachController();
  }

  void _attachController() {
    final controller = widget.controller;
    if (controller == null) return;
    assert(
      controller._accepts(this),
      '${widget.runtimeType} was given an ${controller.runtimeType}, which '
      'only an ArrowPopup of the same type can use.\n'
      'Give the ArrowPopup and its controller the same type, or leave the '
      'type off the ArrowPopup so it takes the controller\'s.',
    );
    controller._attach(this);
  }

  @override
  void didUpdateWidget(ArrowPopup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      _attachController();
    }
    // Without the focus detector, nothing turns the outline off, and a new
    // detector starts unfocused without saying so.
    if (!widget.focusable || widget.trigger == ArrowPopupTrigger.none) {
      _showFocus = false;
    }
    if (_hoverClosed != null && widget.trigger != ArrowPopupTrigger.hover) {
      // Without the hover trigger, leaving no longer closes it. Listeners
      // can't rebuild during this build, so close it right after.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.trigger != ArrowPopupTrigger.hover) {
          _closeHover();
        }
      });
    }
    final route = _route;
    final changed =
        oldWidget.content != widget.content ||
        oldWidget.style != widget.style ||
        oldWidget.placement != widget.placement;
    if (route != null && changed) {
      // The popup is in another part of the tree, which can't be rebuilt
      // during this build, so update it right after.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !identical(_route, route) || !route.isActive) return;
        route.update(
          content: widget.content,
          style: widget.style,
          placement: widget.placement,
        );
      });
    }
  }

  @override
  void dispose() {
    _hoverOpen?.cancel();
    _hoverClose?.cancel();
    FocusManager.instance.removeEarlyKeyEventHandler(_onHoverKey);
    widget.controller?._detach(this);
    // The hover popup is removed with this widget, so it has closed.
    final hoverResult = _hoverClosed;
    _hoverClosed = null;
    hoverResult?.complete(null);
    _hoverAnchor?.dispose();
    _hoverCurved?.dispose();
    _hoverAnimation?.dispose();
    _focusNode.dispose();
    // Don't leave the popup pointing at a widget that is gone. The navigator
    // can't change while the tree is being torn down, so close it after.
    if (_route != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) => hide());
    }
    super.dispose();
  }

  Future<T?> show() => _show(byHover: false);

  // Opened by a click or touch, so the keyboard is no longer in use: drop
  // focus from Tab, so it doesn't come back with the outline on close, as
  // a browser hides its focus ring after a click.
  void _showByPointer() {
    // A click on a hover anchor opens it now, so stop waiting.
    _hoverOpen?.cancel();
    _focusNode.unfocus();
    unawaited(show());
  }

  Future<T?> _show({required bool byHover}) async {
    if (_isOpen || _opening) return _closed!.future;
    final anchor = _resolveAnchor();
    if (anchor == null) return null;
    // A hover popup shows in the nearest overlay, any other in a navigator's.
    final navigator = byHover
        ? null
        : Navigator.of(context, rootNavigator: widget.useRootNavigator);
    final overlay = navigator?.overlay ?? Overlay.of(context);
    // It would close again right away, once it sees the anchor is hidden.
    final isAnchorVisible = ArrowPopupAnchor.isShowing(
      anchor.box,
      overlay.context.findRenderObject()! as RenderBox,
    );
    assert(
      isAnchorVisible,
      'ArrowPopup could not open because no part of its anchor is visible, '
      'such as when it is scrolled out of view.\n'
      'Scroll it into view first, for example with Scrollable.ensureVisible, '
      'and call show once that is done.',
    );
    if (!isAnchorVisible) return null;

    final closed = _runOnOpen();
    // hide was called from onOpen, and has already finished this popup.
    if (closed.isCompleted) return null;
    ArrowPopupRoute<T>? route;
    final Future<T?> popup;
    if (navigator == null) {
      popup = _showHover(anchor.box, overlay);
    } else {
      route = _createRoute(anchor.context, navigator);
      _route = route;
      _notifyController();
      popup = navigator.push(route);
    }
    final result = await popup;
    if (route != null && identical(_route, route)) {
      _route = null;
      _notifyController();
    }
    _finish(closed, result);
    return result;
  }

  // The widget the arrow points at and its box, or null when the popup can't
  // open because the anchor is missing or not laid out.
  ({BuildContext context, RenderBox box})? _resolveAnchor() {
    final anchorKey = widget.anchorKey;
    // A named anchor must exist; pointing at the child instead would hide
    // the mistake.
    final anchorContext = anchorKey == null
        ? context
        : anchorKey.currentContext;
    assert(
      anchorContext != null,
      'ArrowPopup could not open because the widget its anchorKey belongs to '
      'is not in the tree.\n'
      'Give anchorKey to a widget that is built when the popup opens, or set '
      'anchorKey to null to point at the child.',
    );
    if (anchorContext == null) return null;
    final anchorBox = anchorContext.findRenderObject();
    assert(
      anchorBox is RenderBox && anchorBox.hasSize,
      'ArrowPopup could not open because its anchor is not a laid-out box '
      'widget.\n'
      'Call show after the first frame, for example from a button or '
      'WidgetsBinding.instance.addPostFrameCallback. If anchorKey is set, it '
      'must point at a box widget, not a sliver.',
    );
    if (anchorBox is! RenderBox || !anchorBox.hasSize) return null;
    return (context: anchorContext, box: anchorBox);
  }

  // Starts a new popup and calls onOpen. A show from inside onOpen waits for
  // this popup instead of opening another.
  Completer<T?> _runOnOpen() {
    final closed = _closed = Completer<T?>();
    _opening = true;
    try {
      // Before anything else changes, so if it throws the popup stays
      // closed and can be shown again.
      widget.onOpen?.call();
    } catch (_) {
      if (!closed.isCompleted) closed.complete(null);
      rethrow;
    } finally {
      _opening = false;
    }
    return closed;
  }

  ArrowPopupRoute<T> _createRoute(
    BuildContext anchorContext,
    NavigatorState navigator,
  ) {
    return ArrowPopupRoute<T>(
      context: context,
      anchorContext: anchorContext,
      navigator: navigator,
      content: widget.content,
      style: widget.style,
      placement: widget.placement,
      semanticLabel: widget.semanticLabel,
      settings: widget.routeSettings,
      barrierColor: widget.barrierColor,
      barrierDismissible: widget.barrierDismissible,
      transitionDuration: widget.transitionDuration,
      curve: widget.curve,
      autoCloseDuration: widget.autoCloseDuration,
    );
  }

  // Calls onClose and completes [closed], once per popup: hide finishes it
  // right away, and the popup's future completing finishes it otherwise.
  void _finish(Completer<T?> closed, T? result) {
    if (closed.isCompleted) return;
    try {
      // Not once this ArrowPopup is removed, as with PopupMenuButton, so a
      // callback that calls setState doesn't run on a disposed State.
      if (mounted) widget.onClose?.call(result);
    } finally {
      closed.complete(result);
    }
  }

  void _notifyController() {
    final controller = widget.controller;
    if (controller?._state == this) controller!._notify();
  }

  // A tooltip: it doesn't block the screen or take focus, and leaving it,
  // not autoCloseDuration, closes it.
  // [overlay] is the one OverlayPortal shows the bubble in.
  Future<T?> _showHover(RenderBox anchorBox, OverlayState overlay) {
    // The last one may still be fading out.
    _hoverAnchor?.dispose();
    final anchor = _hoverAnchor = ArrowPopupAnchor(
      anchorBox,
      overlay.context.findRenderObject()! as RenderBox,
    );
    anchor.track(_closeHover);
    final animation = _hoverAnimation ??= AnimationController(vsync: this);
    if (_hoverCurved?.curve != widget.curve) {
      _hoverCurved?.dispose();
      _hoverCurved = CurvedAnimation(parent: animation, curve: widget.curve);
    }
    animation.duration = widget.transitionDuration;
    final result = _hoverClosed = Completer<T?>();
    // The bubble never has focus, so catch keys before the focused widget.
    FocusManager.instance.addEarlyKeyEventHandler(_onHoverKey);
    // Rebuilds the bubble with the new anchor.
    setState(_hoverPortal.show);
    unawaited(animation.forward());
    _notifyController();
    return result.future;
  }

  void _closeHover([T? value]) {
    final result = _hoverClosed;
    if (result == null) return;
    _hoverClosed = null;
    _overBubble = false;
    _hoverClose?.cancel();
    FocusManager.instance.removeEarlyKeyEventHandler(_onHoverKey);
    _notifyController();
    result.complete(value);
    // Opening it created this.
    final animation = _hoverAnimation!;
    animation.reverse().whenCompleteOrCancel(() {
      // Unless it was opened again while fading out.
      if (!mounted || !animation.isDismissed) return;
      _hoverPortal.hide();
      _hoverAnchor?.dispose();
      _hoverAnchor = null;
    });
  }

  // Escape closes it without moving the mouse away, as with Flutter's
  // Tooltip. Handled here, so the same press doesn't also reach the app.
  KeyEventResult _onHoverKey(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    _closeHover();
    return KeyEventResult.handled;
  }

  void _onAnchorHover(PointerEvent event, {required bool inside}) {
    // Touch can't hover; it opens with a tap instead.
    if (event.kind == PointerDeviceKind.touch) return;
    _overAnchor = inside;
    _hoverOpen?.cancel();
    if (inside) {
      _hoverClose?.cancel();
      if (_isOpen) return;
      final wait = widget.waitDuration;
      if (wait <= Duration.zero) {
        unawaited(_show(byHover: true));
        return;
      }
      _hoverOpen = Timer(wait, () {
        // Unless it opened another way, or stopped opening on hover.
        if (!mounted || _isOpen || widget.trigger != ArrowPopupTrigger.hover) {
          return;
        }
        unawaited(_show(byHover: true));
      });
    } else {
      _closeAfterHover();
    }
  }

  void _onBubbleHover(bool inside) {
    _overBubble = inside;
    if (inside) {
      _hoverClose?.cancel();
    } else {
      _closeAfterHover();
    }
  }

  // Waits a moment, so the mouse can cross the gap between the anchor and
  // the bubble without closing it.
  void _closeAfterHover() {
    if (_hoverClosed == null) return;
    _hoverClose?.cancel();
    _hoverClose = Timer(_hoverCloseDelay, () {
      if (mounted && !_overAnchor && !_overBubble) _closeHover();
    });
  }

  void hide() {
    // Unless it already closed by itself, such as with a value from
    // ArrowPopup.close, and is only waiting to finish. While onOpen runs,
    // this stops it from opening.
    final closing =
        _opening || _hoverClosed != null || (_route?.isActive ?? false);
    // A show from onOpen after this opens it again.
    _opening = false;
    _closeHover();
    final route = _route;
    if (route != null) {
      // Closed from now on, not once the route's future completes, so a show
      // right after this opens it again.
      _route = null;
      route.close();
      _notifyController();
    }
    // Likewise finished now, so that show's onOpen comes after this onClose.
    final closed = _closed;
    if (closing && closed != null) _finish(closed, null);
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _hoverPortal,
      overlayChildBuilder: _buildHoverBubble,
      child: _buildAnchor(context),
    );
  }

  // Built with the latest settings, so it updates as soon as they change.
  Widget _buildHoverBubble(BuildContext context) {
    return ArrowPopupBubble(
      anchor: _hoverAnchor!,
      animation: _hoverCurved!,
      content: widget.content,
      style: widget.style,
      placement: widget.placement,
      semanticLabel: widget.semanticLabel,
      scopesRoute: false,
      onClose: (value) => _closeHover(arrowPopupResult<T>(value)),
      onHover: _onBubbleHover,
    );
  }

  Widget _buildAnchor(BuildContext context) {
    final child = KeyedSubtree(
      key: _childKey,
      child: widget.builder?.call(context, show) ?? widget.child!,
    );
    final trigger = widget.trigger;
    if (trigger == ArrowPopupTrigger.none) return child;
    final hover = trigger == ArrowPopupTrigger.hover;
    final detector = Semantics(
      button: true,
      // The hover bubble is never announced, as with Flutter's Tooltip, so
      // screen readers read the label when they reach the anchor instead.
      tooltip: hover ? widget.semanticLabel : null,
      child: MouseRegion(
        // Hovering, unlike clicking, needs no hint.
        cursor: hover ? MouseCursor.defer : SystemMouseCursors.click,
        onEnter: hover ? (e) => _onAnchorHover(e, inside: true) : null,
        onExit: hover ? (e) => _onAnchorHover(e, inside: false) : null,
        child: _buildDetector(trigger, child),
      ),
    );
    if (!widget.focusable) return detector;
    return FocusableActionDetector(
      focusNode: _focusNode,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => show()),
        // On the web, Enter sends this instead, to activate buttons only.
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: (_) => show(),
        ),
      },
      onShowFocusHighlight: (value) {
        if (mounted && value != _showFocus) {
          setState(() => _showFocus = value);
        }
      },
      // Always present, so showing the outline doesn't rebuild the child.
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: _showFocus
            ? widget.focusDecoration ??
                  BoxDecoration(
                    border: Border.all(
                      color: defaultFocusColor(context),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  )
            : const BoxDecoration(),
        child: detector,
      ),
    );
  }

  Widget _buildDetector(ArrowPopupTrigger trigger, Widget child) {
    return switch (trigger) {
      ArrowPopupTrigger.none => child,
      // Hover also opens on tap, for touch screens.
      ArrowPopupTrigger.tap || ArrowPopupTrigger.hover => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showByPointer,
        child: child,
      ),
      ArrowPopupTrigger.longPress => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: _showByPointer,
        child: child,
      ),
      // GestureDetector doesn't expose double tap to screen readers, so offer
      // their regular tap action instead.
      ArrowPopupTrigger.doubleTap => Semantics(
        onTap: show,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: _showByPointer,
          child: child,
        ),
      ),
    };
  }
}
