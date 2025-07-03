import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gem_ore_struct_finder_mc/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Screenshot Tests', () {
    testWidgets('Main App Screenshot', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const GemOreStructFinderApp());
      await tester.pumpAndSettle();

      // Basic verification that app loaded
      expect(find.text('Gem, Ore & Struct Finder'), findsOneWidget);
    });
  });
}
