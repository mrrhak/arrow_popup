import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('show after dispose asserts in debug builds', () {
    final controller = ArrowPopupController<String>()..dispose();

    expect(controller.show, throwsAssertionError);
  });
}
