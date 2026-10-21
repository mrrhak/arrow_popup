import 'package:material_ui/material_ui.dart';

import '../config/enums.dart';
import '../config/platform.dart';
import '../config/style.dart';
import '../layout/anchor.dart';
import '../layout/layout.dart';
import 'scope.dart';

/// The bubble, as shown by both [ArrowPopupRoute] and a popup opened on
/// hover: fills the screen, but only the bubble is hit.
class ArrowPopupBubble extends StatelessWidget {
  /// Creates a bubble pointing at [anchor].
  const ArrowPopupBubble({
    super.key,
    required this.anchor,
    required this.animation,
    required this.content,
    required this.style,
    required this.placement,
    required this.semanticLabel,
    required this.scopesRoute,
    required this.onClose,
    this.onHover,
  });

  /// The widget the arrow points at.
  final ArrowPopupAnchor anchor;

  /// Fades and grows the bubble in, from 0 to 1.
  final Animation<double> animation;

  /// The widget shown in the bubble.
  final Widget content;

  /// Visual settings, or null to use [ArrowPopupStyle.of] the theme.
  final ArrowPopupStyle? style;

  /// Which side of the anchor to use.
  final ArrowPopupPlacement placement;

  /// What screen readers announce when the popup opens.
  final String? semanticLabel;

  /// Whether the bubble is a route of its own for screen readers.
  final bool scopesRoute;

  /// Called by `ArrowPopup.close` from inside [content].
  final ValueChanged<Object?> onClose;

  /// Called with true when a mouse enters the bubble, and false when it
  /// leaves.
  final ValueChanged<bool>? onHover;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final safeArea =
        MediaQuery.paddingOf(context) +
        EdgeInsets.only(bottom: viewInsets.bottom);
    // With reduced motion, only fade, without growing out of the arrow.
    final scale = MediaQuery.disableAnimationsOf(context)
        ? kAlwaysCompleteAnimation
        : animation;
    final style = this.style ?? ArrowPopupStyle.of(context);
    Widget layout = ArrowPopupLayout(
      anchor: anchor,
      safeArea: safeArea,
      style: style,
      color: style.color ?? defaultBubbleColor(context),
      placement: placement,
      scale: scale,
      // The bubble repaints every frame to follow the anchor; this keeps the
      // content from repainting with it.
      child: RepaintBoundary(
        // Lets screen readers announce the popup and move into it.
        child: Semantics(
          scopesRoute: scopesRoute,
          namesRoute: scopesRoute,
          explicitChildNodes: true,
          label: semanticLabel,
          child: Material(
            type: MaterialType.transparency,
            // Without a Theme, the text style of the app's Cupertino theme,
            // not Material's, which is black whatever the brightness.
            textStyle: defaultTextStyle(context),
            child: ArrowPopupScope(close: onClose, child: content),
          ),
        ),
      ),
    );
    final onHover = this.onHover;
    if (onHover != null) {
      // The layout fills the screen but is only hit on the bubble, so this
      // tracks the bubble alone.
      layout = MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: layout,
      );
    }
    return FadeTransition(opacity: animation, child: layout);
  }
}
