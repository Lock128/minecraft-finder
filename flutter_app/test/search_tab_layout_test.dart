import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/l10n/app_localizations.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/providers/favorites_provider.dart';
import 'package:gem_ore_struct_finder_mc/providers/monetization_config.dart';
import 'package:gem_ore_struct_finder_mc/providers/pro_status_provider.dart';
import 'package:gem_ore_struct_finder_mc/providers/search_history_provider.dart';
import 'package:gem_ore_struct_finder_mc/providers/search_state.dart';
import 'package:gem_ore_struct_finder_mc/widgets/ore_finder_screen.dart';
import 'package:gem_ore_struct_finder_mc/widgets/results_tab.dart';
import 'package:gem_ore_struct_finder_mc/widgets/search_tab.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chip labels drop the emoji that the localized filter names start with.
String _plain(String label) =>
    label.replaceFirst(RegExp(r'^[^\p{L}\p{N}]+', unicode: true), '');

final _l10n = lookupAppLocalizations(const Locale('en'));

Widget _app({bool dark = false}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ChangeNotifierProvider(create: (_) => SearchHistoryProvider()),
      ChangeNotifierProvider(create: (_) => MonetizationConfig()),
      ChangeNotifierProxyProvider<MonetizationConfig, ProStatusProvider>(
        create: (context) => ProStatusProvider(
          monetizationEnabled: context.read<MonetizationConfig>().isEnabled,
        ),
        update: (_, monetization, proStatus) {
          proStatus!.updateMonetization(monetization.isEnabled);
          return proStatus;
        },
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: OreFinderScreen(
        onThemeToggle: () {},
        isDarkMode: dark,
        onLocaleChanged: (_) {},
        currentLocale: const Locale('en'),
      ),
    ),
  );
}

SearchState _state(WidgetTester tester) =>
    tester.element(find.byType(SearchTab)).read<SearchState>();

/// Phone-sized surface so the form is not clipped by the default 800x600.
void _usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Search tab layout', () {
    testWidgets('shows seed and what-to-find, hides advanced fields', (
      tester,
    ) async {
      _usePhone(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text(_l10n.worldSeedLabel), findsOneWidget);
      expect(find.text(_l10n.whatToFindTitle), findsOneWidget);
      expect(find.text(_l10n.advancedOptionsTitle), findsOneWidget);
      expect(find.text(_l10n.searchRadiusLabel), findsNothing);

      await _tap(tester, find.text(_l10n.advancedOptionsTitle));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.searchRadiusLabel), findsOneWidget);
    });

    testWidgets('ore chips drive includeOres without a separate toggle', (
      tester,
    ) async {
      _usePhone(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      final state = _state(tester);
      expect(state.includeOres, isTrue);
      expect(state.selectedOreTypes, {OreType.diamond});

      await _tap(tester, find.text(_plain(_l10n.filterGold)));
      await tester.pumpAndSettle();
      expect(state.selectedOreTypes, {OreType.diamond, OreType.gold});

      await _tap(tester, find.text(_plain(_l10n.filterDiamonds)));
      await _tap(tester, find.text(_plain(_l10n.filterGold)));
      await tester.pumpAndSettle();
      expect(state.includeOres, isFalse);

      // Picking an ore again turns ore search back on with only that ore.
      await _tap(tester, find.text(_plain(_l10n.filterIron)));
      await tester.pumpAndSettle();
      expect(state.includeOres, isTrue);
      expect(state.selectedOreTypes, {OreType.iron});
    });

    testWidgets('invalid collapsed field opens Advanced options on Find', (
      tester,
    ) async {
      _usePhone(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      final state = _state(tester);
      state.seedController.text = '12345';
      state.radiusController.text = '0';

      expect(find.text(_l10n.errorRadiusPositive), findsNothing);
      await _tap(tester, find.text(_l10n.findButton));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.errorRadiusPositive), findsOneWidget);
    });
  });

  group('Responsive navigation', () {
    testWidgets('narrow screens use a bottom navigation bar', (tester) async {
      _usePhone(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('wide screens show search and results side by side', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(dark: true));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(SearchTab), findsOneWidget);
      expect(find.byType(ResultsTab), findsOneWidget);
    });
  });
}
