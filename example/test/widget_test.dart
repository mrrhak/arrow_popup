import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('tooltip opens on tap and closes on barrier tap', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(find.textContaining('You have used'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.textContaining('You have used'), findsNothing);
  });

  testWidgets('storage bar segments show their size', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.byKey(const ValueKey('Photos')));
    await tester.pumpAndSettle();
    expect(find.text('6.1 GB · 41%'), findsOneWidget);
  });

  testWidgets('menu returns the picked value', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.scrollUntilVisible(find.text('Sorted by Newest'), 200);
    await tester.ensureVisible(find.text('Sort'));
    await tester.pumpAndSettle();
    expect(find.text('Sorted by Newest'), findsOneWidget);

    await tester.tap(find.text('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();

    expect(find.text('Sorted by Name'), findsOneWidget);
    // Budget 2026.xlsx now comes before Holiday.jpg.
    expect(
      tester.getTopLeft(find.text('Budget 2026.xlsx')).dy,
      lessThan(tester.getTopLeft(find.text('Holiday.jpg')).dy),
    );
  });

  testWidgets('file menu deletes and undo restores', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    final file = find.text('Pitch deck.pdf');
    await tester.scrollUntilVisible(file, 200);
    await tester.ensureVisible(file);
    await tester.pumpAndSettle();

    final more = find.descendant(
      of: find.ancestor(of: file, matching: find.byType(ListTile)),
      matching: find.byIcon(Icons.more_vert_rounded),
    );
    await tester.tap(more);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(file, findsNothing);
    expect(find.text('Deleted Pitch deck.pdf'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(file, findsOneWidget);
  });

  testWidgets('undo after the menu demo scrolled away does nothing', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    final file = find.text('Pitch deck.pdf');
    await tester.scrollUntilVisible(file, 200);
    await tester.ensureVisible(file);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.ancestor(of: file, matching: find.byType(ListTile)),
        matching: find.byIcon(Icons.more_vert_rounded),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Far enough that the list disposes the menu demo, while the SnackBar,
    // which belongs to the app, stays.
    await tester.scrollUntilVisible(find.text('Dropdown'), 500);
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('controller runs the feature tour', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.scrollUntilVisible(find.text('Start tour'), 200);
    // The tour points at the mock app bar above the button, so show it too.
    // A popup whose anchor is scrolled out of view closes.
    await tester.ensureVisible(find.text('Inbox'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start tour'));
    await tester.pumpAndSettle();
    expect(find.text('Search everything'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Star what matters'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Tour finished'), findsOneWidget);
    expect(find.text('Replay tour'), findsOneWidget);
  });

  testWidgets('the tour keeps one steady dim between steps', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.scrollUntilVisible(find.text('Start tour'), 200);
    await tester.ensureVisible(find.text('Inbox'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start tour'));
    await tester.pumpAndSettle();

    List<double> dims() => [
      for (final barrier in tester.widgetList<AnimatedModalBarrier>(
        find.byType(AnimatedModalBarrier),
      ))
        if ((barrier.color.value?.a ?? 0) > 0) barrier.color.value!.a,
    ];

    await tester.tap(find.text('Next'));
    // Through the old step closing and the next one opening.
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 25));
      expect(dims(), [closeTo(0.4, 0.01)]);
    }
  });

  testWidgets('icon opens its own hint', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.scrollUntilVisible(find.byIcon(Icons.ios_share_rounded), 200);
    await tester.ensureVisible(find.byIcon(Icons.ios_share_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.ios_share_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Share in a tap'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Share in a tap'), findsNothing);
  });

  testWidgets('country dropdown searches and selects', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    final field = find.text('Cambodia');
    await tester.scrollUntilVisible(field, 200);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();

    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'jap');
    await tester.pumpAndSettle();
    expect(find.text('Vietnam'), findsNothing);

    await tester.tap(find.text('Japan'));
    await tester.pumpAndSettle();
    expect(find.text('Japan'), findsOneWidget);
    expect(find.text('Cambodia'), findsNothing);
  });

  testWidgets('long press reacts to the message', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    final message = find.textContaining('Shipped the new popup');
    await tester.scrollUntilVisible(message, 200);
    await tester.ensureVisible(message);
    await tester.pumpAndSettle();

    await tester.longPress(message);
    await tester.pumpAndSettle();
    await tester.tap(find.text('🎉'));
    await tester.pumpAndSettle();

    // Only the reaction badge on the message is left.
    expect(find.text('🎉'), findsOneWidget);

    // A sent message reacts on its own.
    await tester.longPress(find.textContaining('Does it work'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('❤️'));
    await tester.pumpAndSettle();
    expect(find.text('❤️'), findsOneWidget);
    expect(find.text('🎉'), findsOneWidget);
  });

  testWidgets('double tap likes the photo', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    final photo = find.byKey(const ValueKey('photo'));
    await tester.scrollUntilVisible(photo, 200);
    await tester.ensureVisible(photo);
    await tester.pumpAndSettle();
    await tester.tap(photo);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(photo);
    await tester.pumpAndSettle();

    expect(find.text('Liked!'), findsOneWidget);
    expect(find.text('42 likes'), findsOneWidget);

    // It goes away by itself.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('Liked!'), findsNothing);
  });

  testWidgets('toolbars open popups toward the canvas', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    final pen = find.byIcon(Icons.edit_outlined);
    await tester.tap(pen);
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.text('Pen')).dx,
      greaterThan(tester.getCenter(pen).dx),
    );

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    final layers = find.byIcon(Icons.layers_outlined);
    await tester.tap(layers);
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.text('Layers')).dx,
      lessThan(tester.getCenter(layers).dx),
    );
  });

  testWidgets('layer inspector recolors the shape while open', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();
    expect(find.text('Rectangle 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fill-2')));
    await tester.pumpAndSettle();

    final layer = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('layer')),
    );
    final gradient = (layer.decoration! as BoxDecoration).gradient!;
    expect(gradient.colors.first, const Color(0xFF22C55E));
    // Still open.
    expect(find.text('Rectangle 1'), findsOneWidget);
  });

  testWidgets('settings picker returns the picked option', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    final picker = find.byKey(const ValueKey('setting-Notifications'));
    await tester.scrollUntilVisible(picker, 200);
    await tester.ensureVisible(picker);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: picker, matching: find.text('All')),
      findsOneWidget,
    );

    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mentions'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: picker, matching: find.text('Mentions')),
      findsOneWidget,
    );

    // Dismissing keeps the value.
    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: picker, matching: find.text('Mentions')),
      findsOneWidget,
    );
  });

  testWidgets('copied popup closes by itself, unless set to never', (
    tester,
  ) async {
    // Widget tests have no platform to answer the clipboard, so stand in.
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(const ExampleApp());
    final copy = find.byTooltip('Copy');
    await tester.scrollUntilVisible(copy, 200);
    await tester.ensureVisible(find.text('Profile link'));
    await tester.pumpAndSettle();

    // 1s, the starting choice.
    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(copied, 'https://github.com/mrrhak');
    expect(find.text('Link copied'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Link copied'), findsNothing);

    // Never: stays until a tap outside.
    await tester.tap(find.text('Never'));
    await tester.pumpAndSettle();
    await tester.tap(copy);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Link copied'), findsOneWidget);
    await tester.tapAt(const Offset(5, 300));
    await tester.pumpAndSettle();
    expect(find.text('Link copied'), findsNothing);
  });

  testWidgets('hovering a tool shows its shortcut', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    final bold = find.byKey(const ValueKey('tool-Bold'));
    await tester.scrollUntilVisible(bold, 200);
    await tester.ensureVisible(bold);
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(bold));
    // The demo waits for the mouse to rest before opening.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Bold'), findsOneWidget);

    await mouse.moveTo(const Offset(5, 300));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.text('Bold'), findsNothing);
  });

  testWidgets('tapping an avatar shows who it is', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    final avatar = find.byKey(const ValueKey('member-David Ara'));
    await tester.scrollUntilVisible(avatar, 200);
    await tester.ensureVisible(avatar);
    await tester.pumpAndSettle();

    await tester.tap(avatar);
    await tester.pumpAndSettle();
    expect(find.text('User'), findsOneWidget);
  });
}
