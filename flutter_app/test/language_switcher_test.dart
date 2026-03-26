// Feature: multi-language-support
// Widget test verifying language switcher presence and menu contents
//
// Verifies the language switcher (Icons.language) is present in the AppBar
// and tapping it shows a popup menu with all 5 languages.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/l10n/app_localizations.dart';
import 'package:gem_ore_struct_finder_mc/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Language switcher widget tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('language switcher icon is present in AppBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: OreFinderScreen(
            onThemeToggle: () {},
            isDarkMode: false,
            onLocaleChanged: (_) {},
            currentLocale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('tapping language icon shows popup menu with all 5 languages',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: OreFinderScreen(
            onThemeToggle: () {},
            isDarkMode: false,
            onLocaleChanged: (_) {},
            currentLocale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the language icon to open the popup menu
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      // Verify all 5 language names are shown
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
    });

    testWidgets('current locale shows check mark in menu',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: OreFinderScreen(
            onThemeToggle: () {},
            isDarkMode: false,
            onLocaleChanged: (_) {},
            currentLocale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the language menu
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      // The active locale should have a check icon in the popup menu
      expect(find.byIcon(Icons.check), findsAtLeastNWidgets(1));
    });

    testWidgets('selecting a language from menu triggers onLocaleChanged',
        (WidgetTester tester) async {
      Locale? changedLocale;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: OreFinderScreen(
            onThemeToggle: () {},
            isDarkMode: false,
            onLocaleChanged: (locale) {
              changedLocale = locale;
            },
            currentLocale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the language menu
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      // Select Deutsch
      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();

      expect(changedLocale, isNotNull);
      expect(changedLocale!.languageCode, equals('de'));
    });
  });
}
