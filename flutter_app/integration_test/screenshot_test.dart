import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minecraft_finder/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Play Store Screenshots', () {
    testWidgets('Generate app screenshots for Play Store',
        (WidgetTester tester) async {
      print('🚀 Starting Play Store screenshot generation...');

      // Create screenshots directory
      final screenshotsDir = Directory('../screenshots');
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      // Build the app
      await tester.pumpWidget(const MinecraftOreFinderApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Screenshot 1: Main search screen
      print('📸 Taking main search screen screenshot...');
      await binding.takeScreenshot('01_main_search_screen');

      // Fill in some sample data to make it look more realistic
      final seedField = find.byType(TextFormField).first;
      await tester.enterText(seedField, '8674308105921866736');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Screenshot 2: Search form with data
      print('📸 Taking search form with data screenshot...');
      await binding.takeScreenshot('02_search_form_filled');

      // Try to find and tap the search button
      final searchButtons = find.byType(ElevatedButton);
      if (searchButtons.evaluate().isNotEmpty) {
        print('🔍 Found search button, tapping...');
        await tester.tap(searchButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Screenshot 3: Loading or results screen
        print('📸 Taking search results screenshot...');
        await binding.takeScreenshot('03_search_results');
      }

      // Navigate to results tab
      final resultsTabs = find.text('Results');
      if (resultsTabs.evaluate().isNotEmpty) {
        print('📊 Navigating to results tab...');
        await tester.tap(resultsTabs);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Screenshot 4: Results tab
        print('📸 Taking results tab screenshot...');
        await binding.takeScreenshot('04_results_tab');
      }

      // Navigate to guide tab
      final guideTabs = find.text('Guide');
      if (guideTabs.evaluate().isNotEmpty) {
        print('📖 Navigating to guide tab...');
        await tester.tap(guideTabs);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Screenshot 5: Guide tab
        print('📸 Taking guide tab screenshot...');
        await binding.takeScreenshot('05_guide_tab');
      }

      // Go back to search tab and try theme toggle
      final searchTabs = find.text('Search');
      if (searchTabs.evaluate().isNotEmpty) {
        await tester.tap(searchTabs);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Try to toggle theme
      final themeButtons =
          find.byIcon(Icons.dark_mode).or(find.byIcon(Icons.light_mode));
      if (themeButtons.evaluate().isNotEmpty) {
        print('🌙 Toggling theme...');
        await tester.tap(themeButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Screenshot 6: Dark/Light theme
        print('📸 Taking theme toggle screenshot...');
        await binding.takeScreenshot('06_theme_toggle');
      }

      print('✅ Play Store screenshots generation completed!');
    });
  });
}
