import 'package:flutter/widgets.dart';

/// [value], passed to `ArrowPopup.close`, as the result type [T] of the popup
/// it closes.
///
/// A value of another type asserts in debug builds with a message naming
/// both types, instead of failing as a bare cast.
T? arrowPopupResult<T>(Object? value) {
  assert(
    value is T?,
    'ArrowPopup.close was called with a value of type ${value.runtimeType}, '
    'but the popup closes with $T.\n'
    'Pass a value of that type, or give the popup the type of the value, '
    'such as ArrowPopup<${value.runtimeType}>.',
  );
  return value as T?;
}

/// Lets `ArrowPopup.close` find the popup its context is in.
class ArrowPopupScope extends InheritedWidget {
  /// Creates a scope that closes its popup with [close].
  const ArrowPopupScope({super.key, required this.close, required super.child});

  /// Closes the popup with a value, or null as a dismissal.
  final ValueChanged<Object?> close;

  @override
  bool updateShouldNotify(ArrowPopupScope oldWidget) => false;
}
