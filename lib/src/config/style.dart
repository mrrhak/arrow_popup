import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'theme.dart';

/// Visual settings for the popup bubble and its arrow.
///
/// To set a style for every popup in the app, add one to the theme's
/// extensions, or use an [ArrowPopupTheme] in an app without a [Theme]:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: const [ArrowPopupStyle(borderRadius: 16)],
///   ),
/// )
/// ```
///
/// Popups without their own `style` use it. A popup that passes a `style`
/// uses that one instead, whole; start from [ArrowPopupStyle.of] to change
/// only some of the theme's settings.
@immutable
class ArrowPopupStyle extends ThemeExtension<ArrowPopupStyle> {
  /// Creates a popup style.
  const ArrowPopupStyle({
    this.color,
    this.border = BorderSide.none,
    this.borderRadius = 10,
    this.padding = const EdgeInsets.all(8),
    this.shadows = const [BoxShadow(color: Color(0x1A000000), blurRadius: 10)],
    this.showArrow = true,
    this.arrowSize = const Size(16, 8),
    this.gap = 2,
    this.screenMargin = 10,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
    this.clipBehavior = Clip.none,
  }) : assert(borderRadius >= 0, 'borderRadius must not be negative'),
       assert(gap >= 0, 'gap must not be negative'),
       assert(screenMargin >= 0, 'screenMargin must not be negative'),
       assert(maxWidth >= 0, 'maxWidth must not be negative'),
       assert(maxHeight >= 0, 'maxHeight must not be negative');

  /// Fill color of the bubble and arrow.
  ///
  /// Defaults to the theme's `colorScheme.surfaceContainer`, the color of
  /// Material 3 menus, or a Cupertino background where there is no [Theme].
  final Color? color;

  /// Outline drawn around the bubble and arrow, over the content.
  ///
  /// The line is centered on the bubble's edge, whatever
  /// [BorderSide.strokeAlign] says. A width of 0 draws a one-pixel hairline.
  /// Defaults to [BorderSide.none], which draws nothing.
  final BorderSide border;

  /// Corner radius of the bubble.
  final double borderRadius;

  /// Space between the bubble's edge and its content. Must not be negative.
  ///
  /// [EdgeInsetsDirectional] follows the text direction around the popup.
  final EdgeInsetsGeometry padding;

  /// Shadows painted under the bubble and arrow. `spreadRadius` is ignored.
  final List<BoxShadow> shadows;

  /// Whether to draw the arrow that points at the anchor.
  final bool showArrow;

  /// Width (base) and height (length) of the arrow. Must not be negative.
  final Size arrowSize;

  /// Space between the anchor and the tip of the arrow.
  final double gap;

  /// Minimum distance between the bubble and the edges of the safe area.
  final double screenMargin;

  /// Largest width of the bubble, padding included.
  ///
  /// The bubble is never wider than the screen either way. Set this to keep
  /// long text in tooltips from spanning the whole screen.
  final double maxWidth;

  /// Largest height of the bubble, padding included.
  ///
  /// The bubble is never taller than the room on the screen either way. The
  /// content is only given this much room, so wrap content that can be taller
  /// in a scroll view.
  final double maxHeight;

  /// How to clip the content to the bubble's rounded rectangle.
  ///
  /// Clipping costs some performance, so it is off by default. Turn it on
  /// when content without padding would spill past the rounded corners.
  final Clip clipBehavior;

  /// The style that popups below [context] use when they pass none: the
  /// nearest [ArrowPopupTheme], else the one in the `ThemeData` extensions,
  /// else the default style.
  static ArrowPopupStyle of(BuildContext context) {
    return ArrowPopupTheme.maybeOf(context) ??
        Theme.of(context).extension<ArrowPopupStyle>() ??
        const ArrowPopupStyle();
  }

  /// Returns a copy with the given fields replaced.
  ///
  /// Passing null keeps the current value. To go back to the theme's default
  /// color, create a new [ArrowPopupStyle] instead.
  @override
  ArrowPopupStyle copyWith({
    Color? color,
    BorderSide? border,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    List<BoxShadow>? shadows,
    bool? showArrow,
    Size? arrowSize,
    double? gap,
    double? screenMargin,
    double? maxWidth,
    double? maxHeight,
    Clip? clipBehavior,
  }) {
    return ArrowPopupStyle(
      color: color ?? this.color,
      border: border ?? this.border,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      shadows: shadows ?? this.shadows,
      showArrow: showArrow ?? this.showArrow,
      arrowSize: arrowSize ?? this.arrowSize,
      gap: gap ?? this.gap,
      screenMargin: screenMargin ?? this.screenMargin,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      clipBehavior: clipBehavior ?? this.clipBehavior,
    );
  }

  /// Blends two styles, for when the theme animates.
  ///
  /// [showArrow], [clipBehavior], an infinite [maxWidth] or [maxHeight] and a
  /// null [color] switch halfway.
  @override
  ArrowPopupStyle lerp(ArrowPopupStyle? other, double t) {
    if (other == null) return this;
    T snap<T>(T a, T b) => t < 0.5 ? a : b;
    return ArrowPopupStyle(
      // Color.lerp would treat null, the theme's default, as transparent.
      color: color != null && other.color != null
          ? Color.lerp(color, other.color, t)
          : snap(color, other.color),
      border: BorderSide.lerp(border, other.border, t),
      borderRadius: lerpDouble(borderRadius, other.borderRadius, t)!,
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t)!,
      shadows: BoxShadow.lerpList(shadows, other.shadows, t)!,
      showArrow: snap(showArrow, other.showArrow),
      arrowSize: Size.lerp(arrowSize, other.arrowSize, t)!,
      gap: lerpDouble(gap, other.gap, t)!,
      screenMargin: lerpDouble(screenMargin, other.screenMargin, t)!,
      maxWidth: maxWidth.isFinite && other.maxWidth.isFinite
          ? lerpDouble(maxWidth, other.maxWidth, t)!
          : snap(maxWidth, other.maxWidth),
      maxHeight: maxHeight.isFinite && other.maxHeight.isFinite
          ? lerpDouble(maxHeight, other.maxHeight, t)!
          : snap(maxHeight, other.maxHeight),
      clipBehavior: snap(clipBehavior, other.clipBehavior),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ArrowPopupStyle &&
        other.color == color &&
        other.border == border &&
        other.borderRadius == borderRadius &&
        other.padding == padding &&
        listEquals(other.shadows, shadows) &&
        other.showArrow == showArrow &&
        other.arrowSize == arrowSize &&
        other.gap == gap &&
        other.screenMargin == screenMargin &&
        other.maxWidth == maxWidth &&
        other.maxHeight == maxHeight &&
        other.clipBehavior == clipBehavior;
  }

  @override
  int get hashCode => Object.hash(
    color,
    border,
    borderRadius,
    padding,
    Object.hashAll(shadows),
    showArrow,
    arrowSize,
    gap,
    screenMargin,
    maxWidth,
    maxHeight,
    clipBehavior,
  );
}
