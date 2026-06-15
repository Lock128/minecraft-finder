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

    // Rather than hardcoding expected labels, we verify that the app
    // renders localized tab labels matching AppLocalizations for each locale.
    // This makes the test resilient to translation updates.
    final supportedLocales = ['en', 'de', 'es', 'ja', 'fr'];

    for (final localeCode in supportedLocales) {
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

          // Look up the expected localized strings via AppLocalizations
          final l10n = await AppLocalizations.delegate.load(Locale(localeCode));
          final expectedLabels = [
            l10n.searchTab,
            l10n.resultsTab,
            l10n.favoritesTab,
            l10n.guideTab,
            l10n.bedwarsTab,
          ];

          for (final label in expectedLabels) {
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

        // Verify English tab labels using localized lookup
        final enL10n = await AppLocalizations.delegate.load(const Locale('en'));
        expect(find.text(enL10n.searchTab), findsWidgets);
        expect(find.text(enL10n.resultsTab), findsWidgets);

        // Switch to German via the language menu
        await tester.tap(find.byIcon(Icons.language));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Deutsch'));
        await tester.pumpAndSettle();

        // Verify German tab labels using localized lookup
        final deL10n = await AppLocalizations.delegate.load(const Locale('de'));
        expect(find.text(deL10n.searchTab), findsWidgets);
        expect(find.text(deL10n.resultsTab), findsWidgets);

        // Switch to Spanish
        await tester.tap(find.byIcon(Icons.language));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Espa\u00F1ol'));
        await tester.pumpAndSettle();

        // Verify Spanish tab labels using localized lookup
        final esL10n = await AppLocalizations.delegate.load(const Locale('es'));
        expect(find.text(esL10n.searchTab), findsWidgets);
        expect(find.text(esL10n.resultsTab), findsWidgets);
      },
    );
  });
}
