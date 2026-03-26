// Feature: multi-language-support, Property 5: Error message localization
// Validates: Requirements 8.1, 8.2, 8.3
//
// For any supported locale and for any error condition, the displayed error
// message should be a non-empty string from the active locale's translations,
// not a hardcoded English string.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Property 5: Error message localization', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    const supportedLocales = ['en', 'de', 'es', 'ja', 'fr'];

    // Expected non-English error messages to verify locale-specific content
    const expectedErrorEmptySeed = {
      'en': 'Please enter a world seed',
      'de': 'Bitte gib einen Welt-Seed ein',
      'es': 'Por favor ingresa una semilla del mundo',
      'ja': 'ワールドシードを入力してください',
      'fr': 'Veuillez entrer une graine de monde',
    };

    const expectedErrorEnableSearchType = {
      'en': 'Please enable at least one search type (Ores or Structures)',
      'de': 'Bitte aktiviere mindestens einen Suchtyp (Erze oder Strukturen)',
      'es': 'Por favor activa al menos un tipo de búsqueda (Minerales o Estructuras)',
      'ja': '少なくとも1つの検索タイプ（鉱石または構造物）を有効にしてください',
      'fr': 'Veuillez activer au moins un type de recherche (Minerais ou Structures)',
    };

    const expectedErrorSelectStructure = {
      'en': 'Please select at least one structure type to search for',
      'de': 'Bitte wähle mindestens einen Strukturtyp zum Suchen aus',
      'es': 'Por favor selecciona al menos un tipo de estructura para buscar',
      'ja': '少なくとも1つの構造物タイプを選択してください',
      'fr': 'Veuillez sélectionner au moins un type de structure à rechercher',
    };

    const expectedErrorSelectOre = {
      'en': 'Please select at least one ore type to search for',
      'de': 'Bitte wähle mindestens einen Erztyp zum Suchen aus',
      'es': 'Por favor selecciona al menos un tipo de mineral para buscar',
      'ja': '少なくとも1つの鉱石タイプを選択してください',
      'fr': 'Veuillez sélectionner au moins un type de minerai à rechercher',
    };

    for (final localeCode in supportedLocales) {
      testWidgets(
        'error messages are non-empty and locale-specific for "$localeCode"',
        (WidgetTester tester) async {
          late AppLocalizations l10n;

          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale(localeCode),
              home: Builder(
                builder: (context) {
                  l10n = AppLocalizations.of(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
          await tester.pumpAndSettle();

          // errorEmptySeed
          expect(l10n.errorEmptySeed, isNotEmpty,
              reason:
                  'errorEmptySeed should be non-empty for locale "$localeCode"');
          expect(l10n.errorEmptySeed,
              equals(expectedErrorEmptySeed[localeCode]),
              reason:
                  'errorEmptySeed should match expected translation for "$localeCode"');

          // errorEnableSearchType
          expect(l10n.errorEnableSearchType, isNotEmpty,
              reason:
                  'errorEnableSearchType should be non-empty for locale "$localeCode"');
          expect(l10n.errorEnableSearchType,
              equals(expectedErrorEnableSearchType[localeCode]),
              reason:
                  'errorEnableSearchType should match expected translation for "$localeCode"');

          // errorSelectStructure
          expect(l10n.errorSelectStructure, isNotEmpty,
              reason:
                  'errorSelectStructure should be non-empty for locale "$localeCode"');
          expect(l10n.errorSelectStructure,
              equals(expectedErrorSelectStructure[localeCode]),
              reason:
                  'errorSelectStructure should match expected translation for "$localeCode"');

          // errorSelectOre
          expect(l10n.errorSelectOre, isNotEmpty,
              reason:
                  'errorSelectOre should be non-empty for locale "$localeCode"');
          expect(l10n.errorSelectOre,
              equals(expectedErrorSelectOre[localeCode]),
              reason:
                  'errorSelectOre should match expected translation for "$localeCode"');
        },
      );
    }

    testWidgets(
      'non-English error messages differ from English translations',
      (WidgetTester tester) async {
        late AppLocalizations enL10n;
        late AppLocalizations deL10n;
        late AppLocalizations esL10n;
        late AppLocalizations jaL10n;
        late AppLocalizations frL10n;

        // Build widgets for each locale to get their localizations
        for (final entry in {
          'en': (AppLocalizations l) => enL10n = l,
          'de': (AppLocalizations l) => deL10n = l,
          'es': (AppLocalizations l) => esL10n = l,
          'ja': (AppLocalizations l) => jaL10n = l,
          'fr': (AppLocalizations l) => frL10n = l,
        }.entries) {
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale(entry.key),
              home: Builder(
                builder: (context) {
                  entry.value(AppLocalizations.of(context));
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        // Non-English locales should have different error messages than English
        for (final l10n in [deL10n, esL10n, jaL10n, frL10n]) {
          expect(l10n.errorEmptySeed, isNot(equals(enL10n.errorEmptySeed)),
              reason:
                  'Non-English errorEmptySeed should differ from English');
          expect(l10n.errorEnableSearchType,
              isNot(equals(enL10n.errorEnableSearchType)),
              reason:
                  'Non-English errorEnableSearchType should differ from English');
          expect(l10n.errorSelectStructure,
              isNot(equals(enL10n.errorSelectStructure)),
              reason:
                  'Non-English errorSelectStructure should differ from English');
          expect(l10n.errorSelectOre, isNot(equals(enL10n.errorSelectOre)),
              reason:
                  'Non-English errorSelectOre should differ from English');
        }
      },
    );
  });
}
