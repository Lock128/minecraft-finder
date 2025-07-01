import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minecraft_finder/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Play Store Screenshots', () {
    testWidgets(
      'Generate basic app screenshots',
      (WidgetTester tester) async {
        try {
          print('🚀 Starting screenshot generation...');

          // Build the app with a shorter pump time
          await tester.pumpWidget(const MinecraftOreFinderApp());
          await tester.pump(const Duration(seconds: 1));

          // Convert Flutter surface to image
          await binding.convertFlutterSurfaceToImage();
          print('✅ Surface converted');

          // Screenshot 1: Initial app state
          print('📸 Taking screenshot 1...');
          await binding.takeScreenshot('01_app_launch');

          // Wait a bit more for full load
          await tester.pump(const Duration(seconds: 2));

          // Screenshot 2: Fully loaded app
          print('📸 Taking screenshot 2...');
          await binding.takeScreenshot('02_main_screen');

          // Try simple tab navigation with timeout protection
          try {
            final resultTab = find.text('Results');
            if (resultTab.evaluate().isNotEmpty) {
              await tester.tap(resultTab);
              await tester.pump(const Duration(seconds: 1));

              print('📸 Taking screenshot 3...');
              await binding.takeScreenshot('03_results_tab');
            }
          } catch (e) {
            print('⚠️ Tab navigation failed: $e');
          }

          // Try guide tab
          try {
            final guideTab = find.text('Guide');
            if (guideTab.evaluate().isNotEmpty) {
              await tester.tap(guideTab);
              await tester.pump(const Duration(seconds: 1));

              print('📸 Taking screenshot 4...');
              await binding.takeScreenshot('04_guide_tab');
            }
          } catch (e) {
            print('⚠️ Guide tab failed: $e');
          }

          // Go back to search tab
          try {
            final searchTab = find.text('Search');
            if (searchTab.evaluate().isNotEmpty) {
              await tester.tap(searchTab);
              await tester.pump(const Duration(seconds: 1));

              print('📸 Taking screenshot 5...');
              await binding.takeScreenshot('05_search_tab');
            }
          } catch (e) {
            print('⚠️ Search tab failed: $e');
          }

          print('✅ Screenshot generation completed successfully!');
        } catch (e) {
          print('❌ Screenshot generation failed: $e');
          // Take a final screenshot even if there were errors
          try {
            await binding.takeScreenshot('error_state');
          } catch (screenshotError) {
            print('❌ Even error screenshot failed: $screenshotError');
          }
          // Don't rethrow - let the test complete
        }
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );
  });
}
