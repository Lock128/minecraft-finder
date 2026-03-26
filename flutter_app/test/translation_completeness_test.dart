// Feature: multi-language-support, Property 1: Translation completeness
// Validates: Requirements 1.1, 5.4
//
// For any translation key defined in the English template and for any
// supported locale (en, de, es, ja, fr), the ARB file should contain
// a non-null, non-empty string value.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Property 1: Translation completeness', () {
    late Map<String, dynamic> englishArb;
    late List<String> translationKeys;
    late Map<String, Map<String, dynamic>> allArbs;

    const locales = ['en', 'de', 'es', 'ja', 'fr'];
    const arbDir = 'lib/l10n';

    setUpAll(() {
      // Load all ARB files
      allArbs = {};
      for (final locale in locales) {
        final file = File('$arbDir/app_$locale.arb');
        expect(file.existsSync(), isTrue,
            reason: 'ARB file for locale "$locale" must exist');
        final content = file.readAsStringSync();
        allArbs[locale] = json.decode(content) as Map<String, dynamic>;
      }

      // Extract translation keys from English template
      // (keys that don't start with '@' or '@@')
      englishArb = allArbs['en']!;
      translationKeys = englishArb.keys
          .where((key) => !key.startsWith('@'))
          .toList();

      // Sanity check: we should have a meaningful number of keys
      expect(translationKeys.length, greaterThan(10),
          reason: 'English template should have many translation keys');
    });

    for (final locale in locales) {
      test('all English keys exist and are non-empty in "$locale" ARB', () {
        final arb = allArbs[locale]!;
        final missingKeys = <String>[];
        final emptyKeys = <String>[];

        for (final key in translationKeys) {
          if (!arb.containsKey(key)) {
            missingKeys.add(key);
          } else if (arb[key] is! String || (arb[key] as String).isEmpty) {
            emptyKeys.add(key);
          }
        }

        expect(missingKeys, isEmpty,
            reason:
                'Locale "$locale" is missing ${missingKeys.length} keys: '
                '${missingKeys.take(10).join(", ")}');
        expect(emptyKeys, isEmpty,
            reason:
                'Locale "$locale" has ${emptyKeys.length} empty values: '
                '${emptyKeys.take(10).join(", ")}');
      });
    }

    test('every key × locale combination yields a non-empty string', () {
      // Property-style: iterate all combinations
      int checked = 0;
      for (final key in translationKeys) {
        for (final locale in locales) {
          final arb = allArbs[locale]!;
          final value = arb[key];
          expect(value, isNotNull,
              reason: 'Key "$key" missing in locale "$locale"');
          expect(value, isA<String>(),
              reason: 'Key "$key" in locale "$locale" should be a String');
          expect((value as String).isNotEmpty, isTrue,
              reason: 'Key "$key" in locale "$locale" should be non-empty');
          checked++;
        }
      }
      // Ensure we checked a meaningful number of combinations
      expect(checked, greaterThanOrEqualTo(translationKeys.length * locales.length));
    });
  });
}
