import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gem_ore_struct_finder_mc/utils/preferences_service.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';

/// **Validates: Requirements 6.1, 6.2**
///
/// Property 4: Edition and version era preference round-trip
/// For any MinecraftEdition value, save then load returns the same value;
/// same for VersionEra.
void main() {
  group('Property 4: Edition and version era preference round-trip', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // --- MinecraftEdition round-trip ---

    group('MinecraftEdition round-trip', () {
      for (final edition in MinecraftEdition.values) {
        test('save then load returns $edition', () async {
          await PreferencesService.saveEdition(edition);
          final loaded = await PreferencesService.getEdition();
          expect(loaded, edition);
        });
      }

      test('overwrite: saving bedrock then java returns java', () async {
        await PreferencesService.saveEdition(MinecraftEdition.bedrock);
        await PreferencesService.saveEdition(MinecraftEdition.java);
        final loaded = await PreferencesService.getEdition();
        expect(loaded, MinecraftEdition.java);
      });

      test('overwrite: saving java then bedrock returns bedrock', () async {
        await PreferencesService.saveEdition(MinecraftEdition.java);
        await PreferencesService.saveEdition(MinecraftEdition.bedrock);
        final loaded = await PreferencesService.getEdition();
        expect(loaded, MinecraftEdition.bedrock);
      });

      test('multiple sequential round-trips all succeed', () async {
        for (var i = 0; i < 5; i++) {
          for (final edition in MinecraftEdition.values) {
            await PreferencesService.saveEdition(edition);
            final loaded = await PreferencesService.getEdition();
            expect(loaded, edition,
                reason: 'Round-trip $i failed for $edition');
          }
        }
      });
    });

    // --- VersionEra round-trip ---

    group('VersionEra round-trip', () {
      for (final era in VersionEra.values) {
        test('save then load returns $era', () async {
          await PreferencesService.saveVersionEra(era);
          final loaded = await PreferencesService.getVersionEra();
          expect(loaded, era);
        });
      }

      test('overwrite: saving legacy then modern returns modern', () async {
        await PreferencesService.saveVersionEra(VersionEra.legacy);
        await PreferencesService.saveVersionEra(VersionEra.modern);
        final loaded = await PreferencesService.getVersionEra();
        expect(loaded, VersionEra.modern);
      });

      test('overwrite: saving modern then legacy returns legacy', () async {
        await PreferencesService.saveVersionEra(VersionEra.modern);
        await PreferencesService.saveVersionEra(VersionEra.legacy);
        final loaded = await PreferencesService.getVersionEra();
        expect(loaded, VersionEra.legacy);
      });

      test('multiple sequential round-trips all succeed', () async {
        for (var i = 0; i < 5; i++) {
          for (final era in VersionEra.values) {
            await PreferencesService.saveVersionEra(era);
            final loaded = await PreferencesService.getVersionEra();
            expect(loaded, era, reason: 'Round-trip $i failed for $era');
          }
        }
      });
    });

    // --- Default values when no preference stored ---

    group('Defaults when no preference is stored', () {
      test('getEdition returns java by default', () async {
        final edition = await PreferencesService.getEdition();
        expect(edition, MinecraftEdition.java);
      });

      test('getVersionEra returns modern by default', () async {
        final era = await PreferencesService.getVersionEra();
        expect(era, VersionEra.modern);
      });
    });

    // --- Cross-preference independence ---

    group('Edition and VersionEra are independent', () {
      test('saving edition does not affect version era', () async {
        await PreferencesService.saveVersionEra(VersionEra.legacy);
        await PreferencesService.saveEdition(MinecraftEdition.bedrock);
        final era = await PreferencesService.getVersionEra();
        expect(era, VersionEra.legacy);
      });

      test('saving version era does not affect edition', () async {
        await PreferencesService.saveEdition(MinecraftEdition.bedrock);
        await PreferencesService.saveVersionEra(VersionEra.legacy);
        final edition = await PreferencesService.getEdition();
        expect(edition, MinecraftEdition.bedrock);
      });
    });
  });
}
