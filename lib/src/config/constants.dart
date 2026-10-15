import 'package:flutter/material.dart';

// Defaults shared by `ArrowPopup`, `ArrowPopup.builder` and
// `ArrowPopup.show`, so they can't drift apart.

/// Color of the barrier behind the popup.
const defaultBarrierColor = Color(0x1A000000);

/// Length of the open and close transition.
const defaultTransitionDuration = Duration(milliseconds: 150);

/// Curve of the open and close transition.
const defaultCurve = Curves.easeOut;
