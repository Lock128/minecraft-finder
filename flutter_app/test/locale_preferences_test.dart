import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gem_ore_struct_finder_mc/utils/preferences_service.dart';

void main() {
  group('Locale preferences', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getLocale returns null when no locale has been saved', () async {
      final locale = await PreferencesService.getLocale();
      expect(locale, isNull);
    });

    for (final code in ['en', 'de', 'es', 'ja', 'fr']) {
      test('save/load round-trip returns "$code"', () async {
        await PreferencesService.saveLocale(code);
        final loaded = await PreferencesService.getLocale();
        expect(loaded, code);
      });
    }

    test('saving a new locale overwrites the previous one', () async {
      await PreferencesService.saveLocale('de');
      expect(await PreferencesService.getLocale(), 'de');

      await PreferencesService.saveLocale('ja');
      expect(await PreferencesService.getLocale(), 'ja');
    });
  });
}
