// Feature: multi-language-support, Property 3: UI locale reactivity
// Validates: Requirements 3.1, 3.2, 3.3, 7.1, 7.2, 7.3
//
// For any supported locale, when the user selects that locale from the
// language switcher, all visible user-facing strings (tab labels) should
// update to the translations for that locale without requiring a restart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/l10n/app_localizations.dart';
import 'package:gem_ore_struct_finder_mc/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Property 3: UI locale reactivity', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // Expected tab labels per locale
    const expectedTabLabels = <String, List<String>>{
      'en': ['Search', 'Results', 'Favorites', 'User Guide', 'Bedwars'],
      'de': ['Suche', 'Ergebnisse', 'Favorites', 'Anleitung', 'Bedwars'],
      'es': ['Buscar', 'Resultados', 'Favorites', 'Guía', 'Bedwars'],
      'ja': ['検索', '結果', 'Favorites', 'ガイド', 'ベッドウォーズ'],
      'fr': ['Recherche', 'Résultats', 'Favorites', 'Guide', 'Bedwars'],
    };

    for (final entry in expectedTabLabels.entries) {
      final localeCode = entry.key;
      final labels = entry.value;

      testWidgets(
        'setting locale to "$localeCode" updates tab labels correctly',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale(localeCode),
              home: OreFinderScreen(
                onThemeToggle: () {},
                isDarkMode: false,
                onLocaleChanged: (_) {},
                currentLocale: Locale(localeCode),
              ),
            ),
          );
          await tester.pumpAndSettle();

          for (final label in labels) {
            expect(
              find.text(label),
              findsWidgets,
              reason:
                  'Tab label "$label" should be visible for locale "$localeCode"',
            );
          }
        },
      );
    }

    testWidgets(
      'switching locale dynamically updates tab labels without restart',
      (WidgetTester tester) async {
        Locale currentLocale = const Locale('en');

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                localizationsDelegates:
                    AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: currentLocale,
                home: OreFinderScreen(
                  onThemeToggle: () {},
                  isDarkMode: false,
                  onLocaleChanged: (locale) {
                    setState(() => currentLocale = locale);
                  },
                  currentLocale: currentLocale,
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        // Verify English tab labels
        expect(find.text('Search'), findsWidgets);
        expect(find.text('Results'), findsWidgets);

        // Switch to German via the language menu
        await tester.tap(find.byIcon(Icons.language));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Deutsch'));
        await tester.pumpAndSettle();

        // Verify German tab labels
        expect(find.text('Suche'), findsWidgets);
        expect(find.text('Ergebnisse'), findsWidgets);

        // Switch to Spanish
        await tester.tap(find.byIcon(Icons.language));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Español'));
        await tester.pumpAndSettle();

        // Verify Spanish tab labels
        expect(find.text('Buscar'), findsWidgets);
        expect(find.text('Resultados'), findsWidgets);
      },
    );
  });
}
