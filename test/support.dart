import 'package:arrow_popup/arrow_popup.dart';
import 'package:arrow_popup/src/layout/layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Helpers shared by the widget tests.

const contentKey = Key('content');
const anchorKey = Key('anchor');

Widget app(Widget child, {Alignment alignment = Alignment.center}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(alignment: alignment, child: child),
    ),
  );
}

ArrowPopup popup({
  ArrowPopupController? controller,
  ArrowPopupTrigger trigger = ArrowPopupTrigger.tap,
  ArrowPopupStyle? style = const ArrowPopupStyle(),
  ArrowPopupPlacement placement = ArrowPopupPlacement.auto,
  VoidCallback? onOpen,
  ValueChanged<Object?>? onClose,
  double contentWidth = 100,
}) {
  return ArrowPopup(
    controller: controller,
    trigger: trigger,
    style: style,
    placement: placement,
    onOpen: onOpen,
    onClose: onClose,
    content: SizedBox(key: contentKey, width: contentWidth, height: 50),
    child: const Anchor(),
  );
}

RenderArrowPopupLayout layoutOf(WidgetTester tester) {
  return tester.renderObject(find.byType(ArrowPopupLayout));
}

/// The widget the popup points at. Unlike an empty SizedBox, it is hit by
/// taps, so tester.tap doesn't warn that it missed.
class Anchor extends StatelessWidget {
  const Anchor({this.width = 40}) : super(key: anchorKey);

  final double width;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x00000000),
      child: SizedBox(width: width, height: 40),
    );
  }
}

/// Records the routes pushed on a navigator.
class RecordingObserver extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}

/// An anchor with state, to check that it survives rebuilds.
class StatefulChild extends StatefulWidget {
  const StatefulChild({super.key});

  @override
  State<StatefulChild> createState() => _StatefulChildState();
}

class _StatefulChildState extends State<StatefulChild> {
  @override
  Widget build(BuildContext context) => const Anchor();
}

/// Creates and disposes its own controller, like most apps do.
class OwnsController extends StatefulWidget {
  const OwnsController({super.key});

  @override
  State<OwnsController> createState() => _OwnsControllerState();
}

class _OwnsControllerState extends State<OwnsController> {
  final _controller = ArrowPopupController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => popup(controller: _controller);
}
