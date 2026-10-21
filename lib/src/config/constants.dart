import 'package:flutter/material.dart';

// Defaults shared by `ArrowPopup`, `ArrowPopup.builder` and
// `ArrowPopup.show`, so they can't drift apart.

/// Color of the barrier behind the popup.
const defaultBarrierColor = Color(0x1A000000);

/// Length of the open and close transition.
const defaultTransitionDuration = Duration(milliseconds: 150);

/// How long a hover popup stays after the mouse leaves, so the mouse can
/// cross the gap between the anchor and the bubble.
const defaultHoverCloseDelay = Duration(milliseconds: 100);

/// Curve of the open and close transition.
const defaultCurve = Curves.easeOut;
