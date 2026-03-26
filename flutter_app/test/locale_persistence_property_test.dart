// Feature: multi-language-support, Property 2: Locale persistence round-trip
// Validates: Requirements 4.1, 4.2, 4.4
//
// For any supported locale code (en, de, es, ja, fr), saving it via
// PreferencesService.saveLocale and then loading it via
// PreferencesService.getLocale should return the same locale code.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gem_ore_struct_finder_mc/utils/preferences_service.dart';

void main() {
  group('Property 2: Locale persistence round-trip', () {
    const supportedLocales = ['en', 'de', 'es', 'ja', 'fr'];

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // Deterministic: test each locale explicitly
    for (final locale in supportedLocales) {
      test('save then load returns "$locale"', () async {
        await PreferencesService.saveLocale(locale);
        final loaded = await PreferencesService.getLocale();
        expect(loaded, equals(locale));
      });
    }

    // Property-based: 100 random iterations picking from supported locales
    test('100 random iterations: save then load returns same locale', () async {
      final random = Random(42); // fixed seed for reproducibility
      for (int i = 0; i < 100; i++) {
        // Reset preferences each iteration
        SharedPreferences.setMockInitialValues({});

        final locale = supportedLocales[random.nextInt(supportedLocales.length)];
        await PreferencesService.saveLocale(locale);
        final loaded = await PreferencesService.getLocale();
        expect(loaded, equals(locale),
            reason: 'Iteration $i: saved "$locale" but loaded "$loaded"');
      }
    });

    // Additional property: consecutive saves preserve only the last value
    test('consecutive saves: last locale wins', () async {
      final random = Random(99);
      for (int i = 0; i < 50; i++) {
        final first = supportedLocales[random.nextInt(supportedLocales.length)];
        final second = supportedLocales[random.nextInt(supportedLocales.length)];

        await PreferencesService.saveLocale(first);
        await PreferencesService.saveLocale(second);
        final loaded = await PreferencesService.getLocale();
        expect(loaded, equals(second),
            reason:
                'Iteration $i: saved "$first" then "$second", '
                'but loaded "$loaded"');
      }
    });
  });
}
