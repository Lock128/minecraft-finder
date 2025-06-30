import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:your_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('take screenshot', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Take screenshot of the home screen
    await binding.takeScreenshot('home_screen');

    // Optional: Navigate and take more screenshots
    // await tester.tap(find.text('Next'));
    // await tester.pumpAndSettle();
    // await binding.takeScreenshot('next_screen');
  });
}
