// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:gem_ore_struct_finder_mc/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GemOreStructFinderApp());

    // Verify that the app title is displayed.
    expect(find.text('Gem, Ore & Struct Finder'), findsOneWidget);

    // Verify that the search tab is displayed by default.
    expect(find.text('Search'), findsOneWidget);
  });
}
