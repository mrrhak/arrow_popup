import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:arrow_popup/arrow_popup.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'frame.dart';

final posterKey = GlobalKey();

// The test font draws every glyph as a box, so load the real ones that ship
// with Flutter.
Future<void> loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) {
    throw StateError('FLUTTER_ROOT is not set. Run this with flutter test.');
  }
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> font(String file) async =>
      ByteData.sublistView(await File('$dir/$file').readAsBytes());
  await (FontLoader('Roboto')
        ..addFont(font('Roboto-Regular.ttf'))
        ..addFont(font('Roboto-Medium.ttf'))
        ..addFont(font('Roboto-Bold.ttf')))
      .load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(font('MaterialIcons-Regular.otf'))).load();
}

ThemeData buildTheme({required bool dark}) {
  final base = ThemeData(
    colorSchemeSeed: Colors.indigo,
    brightness: dark ? Brightness.dark : Brightness.light,
  );
  return base.copyWith(
    extensions: [
      ArrowPopupStyle(
        color: base.colorScheme.surfaceContainerHighest,
        borderRadius: 14,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.45 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    ],
  );
}

Future<void> pumpPoster(
  WidgetTester tester, {
  bool dark = false,
  bool glow = false,
  required String title,
  required String subtitle,
  required Widget screen,
}) {
  return pump(
    tester,
    dark: dark,
    // 800 x 480 logical pixels at 1.5x: 1200 x 720, sharp at the 400 pixel
    // width of the README and small enough to keep the package light.
    size: const Size(1200, 720),
    pixelRatio: 1.5,
    home: Poster(title: title, subtitle: subtitle, screen: screen, glow: glow),
  );
}

Future<void> pump(
  WidgetTester tester, {
  bool dark = false,
  required Size size,
  required double pixelRatio,
  required Widget home,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);
  // Tests draw shadows without blur unless told otherwise. capture turns
  // this back on, since the test checks it before tear-down.
  debugDisableShadows = false;
  await tester.pumpWidget(
    RepaintBoundary(
      key: posterKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(dark: dark),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openPopup(
  WidgetTester tester,
  GlobalKey anchor,
  Widget content, {
  ArrowPopupPlacement placement = ArrowPopupPlacement.auto,
  ArrowPopupStyle Function(ArrowPopupStyle base)? style,
}) async {
  final context = anchor.currentContext!;
  unawaited(
    ArrowPopup.show<void>(
      context: context,
      content: content,
      placement: placement,
      style: style?.call(ArrowPopupStyle.of(context)),
      barrierColor: null,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(posterKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(
      pixelRatio: tester.view.devicePixelRatio,
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('../screenshots/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}
