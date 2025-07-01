import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minecraft_finder/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Take basic screenshots', (WidgetTester tester) async {
    print('🚀 Starting integration test...');

    // Launch the app
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    print('📱 App launched, taking first screenshot...');

    // Take screenshot 1: Main screen
    await binding.takeScreenshot('01_main_screen');
    print('✅ Screenshot 1 taken');

    // Wait and take another screenshot
    await tester.pump(const Duration(seconds: 2));
    await binding.takeScreenshot('02_loaded_screen');
    print('✅ Screenshot 2 taken');

    // Try to find and tap Results tab
    try {
      final resultsTab = find.text('Results');
      if (resultsTab.evaluate().isNotEmpty) {
        await tester.tap(resultsTab);
        await tester.pump(const Duration(seconds: 2));
        await binding.takeScreenshot('03_results_tab');
        print('✅ Screenshot 3 taken');
      }
    } catch (e) {
      print('⚠️ Results tab failed: $e');
    }

    // Try to find and tap Guide tab
    try {
      final guideTab = find.text('Guide');
      if (guideTab.evaluate().isNotEmpty) {
        await tester.tap(guideTab);
        await tester.pump(const Duration(seconds: 2));
        await binding.takeScreenshot('04_guide_tab');
        print('✅ Screenshot 4 taken');
      }
    } catch (e) {
      print('⚠️ Guide tab failed: $e');
    }

    print('✅ Integration test completed successfully!');
  });
}
