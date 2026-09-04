// Feature: quick-start-usability (FEAT-002)
// Widget tests for QuickStartCard
//
// Validates that activating the "Diamonds near spawn" preset populates the
// shared controllers and selection state via the existing setters, and that
// the new localized helper text renders.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/l10n/app_localizations.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/widgets/quick_start_card.dart';

/// English localizations used to assert on the localized labels.
final AppLocalizations enL10n = lookupAppLocalizations(const Locale('en'));

void main() {
  late TextEditingController xController;
  late TextEditingController yController;
  late TextEditingController zController;
  late TextEditingController radiusController;

  setUp(() {
    // Start from non-default values to prove the preset overwrites them.
    xController = TextEditingController(text: '123');
    yController = TextEditingController(text: '-59');
    zController = TextEditingController(text: '456');
    radiusController = TextEditingController(text: '50');
  });

  tearDown(() {
    xController.dispose();
    yController.dispose();
    zController.dispose();
    radiusController.dispose();
  });

  Widget buildTestWidget({
    Function(bool)? onIncludeOresChanged,
    Function(Set<OreType>)? onOreTypesChanged,
    bool isDarkMode = false,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: QuickStartCard(
            xController: xController,
            yController: yController,
            zController: zController,
            radiusController: radiusController,
            onIncludeOresChanged: onIncludeOresChanged ?? (_) {},
            onOreTypesChanged: onOreTypesChanged ?? (_) {},
            isDarkMode: isDarkMode,
          ),
        ),
      ),
    );
  }

  group('QuickStartCard - rendering', () {
    testWidgets('renders header, preset chip and helper text',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text(enL10n.quickStartTitle), findsOneWidget);
      expect(find.text(enL10n.quickStartHint), findsOneWidget);
      expect(
          find.text(enL10n.quickStartDiamondsNearSpawn), findsOneWidget);
      expect(find.text(enL10n.quickStartSeedTip), findsOneWidget);
      expect(find.text(enL10n.quickStartSpawnTip), findsOneWidget);
    });

    testWidgets('renders in dark mode without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(isDarkMode: true));
      await tester.pumpAndSettle();

      expect(find.text(enL10n.quickStartTitle), findsOneWidget);
      expect(
          find.text(enL10n.quickStartDiamondsNearSpawn), findsOneWidget);
    });
  });

  group('QuickStartCard - Diamonds near spawn preset', () {
    testWidgets('prefills controllers with spawn-centered defaults',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text(enL10n.quickStartDiamondsNearSpawn));
      await tester.pumpAndSettle();

      expect(xController.text, '0');
      expect(zController.text, '0');
      expect(yController.text, ''); // Y cleared / optional
      expect(radiusController.text, '1000');
    });

    testWidgets('enables ores and selects diamond via setters',
        (WidgetTester tester) async {
      bool? includeOres;
      Set<OreType>? selectedOres;

      await tester.pumpWidget(buildTestWidget(
        onIncludeOresChanged: (v) => includeOres = v,
        onOreTypesChanged: (v) => selectedOres = v,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text(enL10n.quickStartDiamondsNearSpawn));
      await tester.pumpAndSettle();

      expect(includeOres, isTrue);
      expect(selectedOres, {OreType.diamond});
    });
  });
}
