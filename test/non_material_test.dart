import 'package:arrow_popup/arrow_popup.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Scaffold, ThemeData, MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support.dart' as s;

// An app without a Material Theme: Cupertino or bare widgets.

Widget _cupertinoApp(Widget child, {Brightness? brightness}) {
  return CupertinoApp(
    theme: CupertinoThemeData(brightness: brightness),
    home: CupertinoPageScaffold(child: Center(child: child)),
  );
}

Widget _widgetsApp(Widget child) {
  return WidgetsApp(
    color: const Color(0xFF000000),
    // The popup needs a navigator, which is below the app's builder.
    home: Center(child: child),
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, _, _) => builder(context),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(s.anchorKey));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens and closes in a CupertinoApp', (tester) async {
    await tester.pumpWidget(_cupertinoApp(s.popup()));
    await _open(tester);
    expect(find.byKey(s.contentKey), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(s.contentKey), findsNothing);
  });

  testWidgets('uses a Cupertino color, light and dark', (tester) async {
    await tester.pumpWidget(
      _cupertinoApp(s.popup(style: const ArrowPopupStyle(shadows: []))),
    );
    await _open(tester);
    expect(
      s.layoutOf(tester),
      paints..path(color: CupertinoColors.secondarySystemGroupedBackground),
    );

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _cupertinoApp(
        s.popup(style: const ArrowPopupStyle(shadows: [])),
        brightness: Brightness.dark,
      ),
    );
    await _open(tester);
    expect(
      s.layoutOf(tester),
      paints..path(
        color: CupertinoColors.secondarySystemGroupedBackground.darkColor,
      ),
    );
  });

  testWidgets('follows the platform brightness in a WidgetsApp', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      _widgetsApp(s.popup(style: const ArrowPopupStyle(shadows: []))),
    );
    await _open(tester);
    expect(
      s.layoutOf(tester),
      paints..path(
        color: CupertinoColors.secondarySystemGroupedBackground.darkColor,
      ),
    );
  });

  testWidgets('content text uses the Cupertino text style', (tester) async {
    await tester.pumpWidget(
      _cupertinoApp(
        ArrowPopup(
          content: const Text('Hello', key: s.contentKey),
          child: const s.Anchor(),
        ),
      ),
    );
    await _open(tester);
    final style = DefaultTextStyle.of(
      tester.element(find.byKey(s.contentKey)),
    ).style;
    expect(
      style.fontFamily,
      const CupertinoThemeData().textTheme.textStyle.fontFamily,
    );
  });

  testWidgets('an ArrowPopupTheme styles the popups below it', (tester) async {
    await tester.pumpWidget(
      _cupertinoApp(
        ArrowPopupTheme(
          style: const ArrowPopupStyle(
            color: Color(0xFF123456),
            borderRadius: 20,
            shadows: [],
          ),
          child: s.popup(style: null),
        ),
      ),
    );
    await _open(tester);
    expect(s.layoutOf(tester), paints..path(color: const Color(0xFF123456)));
    expect(s.layoutOf(tester).geometry!.radius, 20);
  });

  testWidgets('an ArrowPopupTheme wins over the ThemeData extension', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [
            ArrowPopupStyle(color: Color(0xFFAA0000), shadows: []),
          ],
        ),
        home: Scaffold(
          body: Center(
            child: ArrowPopupTheme(
              style: const ArrowPopupStyle(
                color: Color(0xFF00AA00),
                shadows: [],
              ),
              child: s.popup(style: null),
            ),
          ),
        ),
      ),
    );
    await _open(tester);
    expect(s.layoutOf(tester), paints..path(color: const Color(0xFF00AA00)));
  });

  testWidgets('the focus outline uses the Cupertino primary color', (
    tester,
  ) async {
    await tester.pumpWidget(_cupertinoApp(s.popup()));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    final outline = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .where((box) => box.position == DecorationPosition.foreground)
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .where((decoration) => decoration.border != null)
        .single;
    expect(
      (outline.border! as Border).top.color.toARGB32(),
      CupertinoColors.activeBlue.color.toARGB32(),
    );
  });

  testWidgets('a changed ArrowPopupTheme restyles an open hover popup', (
    tester,
  ) async {
    // The same widget each time, so only the theme's dependents rebuild.
    final popup = s.popup(trigger: ArrowPopupTrigger.hover, style: null);
    Widget app(double radius) => s.app(
      ArrowPopupTheme(
        style: ArrowPopupStyle(borderRadius: radius),
        child: popup,
      ),
    );

    await tester.pumpWidget(app(4));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(find.byKey(s.anchorKey)));
    await tester.pumpAndSettle();
    expect(s.layoutOf(tester).geometry!.radius, 4);

    await tester.pumpWidget(app(20));
    await tester.pumpAndSettle();
    expect(s.layoutOf(tester).geometry!.radius, 20);
  });
}
