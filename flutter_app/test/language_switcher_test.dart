// Feature: multi-language-support
// Widget test verifying language switcher presence and menu contents
//
// Verifies the language switcher (Icons.language) is present in the AppBar
// and tapping it shows a popup menu with all 5 languages.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/l10n/app_localizations.dart';
import 'package:gem_ore_struct_finder_mc/main.dart';
import 'package:gem_ore_struct_finder_mc/providers/favorites_provider.dart';
import 'package:gem_ore_struct_finder_mc/providers/monetization_config.dart';
import 'package:gem_ore_struct_finder_mc/providers/pro_status_provider.dart';
import 'package:gem_ore_struct_finder_mc/providers/search_history_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps [OreFinderScreen] in the same providers the app supplies in main.dart
/// so that widgets depending on MonetizationConfig / ProStatusProvider build
/// without throwing ProviderNotFoundException.
Widget _wrapOreFinderScreen({
  required ValueChanged<Locale> onLocaleChanged,
}) {
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
        isDarkMode: false,
        onLocaleChanged: onLocaleChanged,
        currentLocale: const Locale('en'),
      ),
    ),
  );
}

void main() {
  group('Language switcher widget tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('language switcher icon is present in AppBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapOreFinderScreen(onLocaleChanged: (_) {}),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('tapping language icon shows popup menu with all 5 languages',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapOreFinderScreen(onLocaleChanged: (_) {}),
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
        _wrapOreFinderScreen(onLocaleChanged: (_) {}),
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
        _wrapOreFinderScreen(
          onLocaleChanged: (locale) {
            changedLocale = locale;
          },
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
