import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_finder.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/legacy_density_function.dart';
import 'package:gem_ore_struct_finder_mc/utils/preferences_service.dart';

/// Integration tests for edition/version selection end-to-end flows.
///
/// **Validates: Requirements 8.4, 8.5, 6.3**
void main() {
  group('Integration: Bedrock + Legacy search', () {
    test('all results have Y within legacy range and 0-256', () async {
      final oreFinder = OreFinder();

      final results = await oreFinder.findOres(
        seed: 'test_seed_123',
        centerX: 0,
        centerY: 10,
        centerZ: 0,
        radius: 20,
        oreType: OreType.diamond,
        minProbability: 0.01,
        edition: MinecraftEdition.bedrock,
        versionEra: VersionEra.legacy,
      );

      // Legacy diamond range: Y 1-15
      final legacyRange = LegacyDensityFunction.oreYRanges['diamond']!;

      for (final loc in results) {
        expect(loc.y, greaterThanOrEqualTo(0),
            reason: 'Legacy world height min is 0, got Y=${loc.y}');
        expect(loc.y, lessThanOrEqualTo(256),
            reason: 'Legacy world height max is 256, got Y=${loc.y}');
        expect(loc.y, greaterThanOrEqualTo(legacyRange[0]),
            reason: 'Diamond legacy min Y is ${legacyRange[0]}, got Y=${loc.y}');
        expect(loc.y, lessThanOrEqualTo(legacyRange[1]),
            reason: 'Diamond legacy max Y is ${legacyRange[1]}, got Y=${loc.y}');
      }
    });

    test('iron results respect legacy Y range 1-63', () async {
      final oreFinder = OreFinder();

      final results = await oreFinder.findOres(
        seed: 'iron_legacy_test',
        centerX: 0,
        centerY: 30,
        centerZ: 0,
        radius: 25,
        oreType: OreType.iron,
        minProbability: 0.01,
        edition: MinecraftEdition.bedrock,
        versionEra: VersionEra.legacy,
      );

      final legacyRange = LegacyDensityFunction.oreYRanges['iron']!;

      for (final loc in results) {
        expect(loc.y, greaterThanOrEqualTo(0));
        expect(loc.y, lessThanOrEqualTo(256));
        expect(loc.y, greaterThanOrEqualTo(legacyRange[0]),
            reason: 'Iron legacy min Y is ${legacyRange[0]}, got Y=${loc.y}');
        expect(loc.y, lessThanOrEqualTo(legacyRange[1]),
            reason: 'Iron legacy max Y is ${legacyRange[1]}, got Y=${loc.y}');
      }
    });
  });

  group('Integration: Java + Modern search (default behavior)', () {
    test('results can have Y in modern range (-64 to 320)', () async {
      final oreFinder = OreFinder();

      final results = await oreFinder.findOres(
        seed: 'modern_test_seed',
        centerX: 0,
        centerY: -50,
        centerZ: 0,
        radius: 25,
        oreType: OreType.iron,
        minProbability: 0.01,
        edition: MinecraftEdition.java,
        versionEra: VersionEra.modern,
      );

      for (final loc in results) {
        expect(loc.y, greaterThanOrEqualTo(-64),
            reason: 'Modern world min Y is -64, got Y=${loc.y}');
        expect(loc.y, lessThanOrEqualTo(320),
            reason: 'Modern world max Y is 320, got Y=${loc.y}');
      }
    });

    test('diamond results use modern Y range -64 to 16', () async {
      final oreFinder = OreFinder();

      final results = await oreFinder.findOres(
        seed: 'diamond_modern',
        centerX: 0,
        centerY: -20,
        centerZ: 0,
        radius: 20,
        oreType: OreType.diamond,
        minProbability: 0.01,
        edition: MinecraftEdition.java,
        versionEra: VersionEra.modern,
      );

      for (final loc in results) {
        expect(loc.y, greaterThanOrEqualTo(-64),
            reason: 'Modern diamond min Y is -64, got Y=${loc.y}');
        expect(loc.y, lessThanOrEqualTo(16),
            reason: 'Modern diamond max Y is 16, got Y=${loc.y}');
      }
    });
  });

  group('Integration: Preference persistence across simulated restart', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('edition and versionEra persist and reload correctly', () async {
      // Save preferences
      await PreferencesService.saveEdition(MinecraftEdition.bedrock);
      await PreferencesService.saveVersionEra(VersionEra.legacy);

      // Verify saved values
      final edition = await PreferencesService.getEdition();
      final era = await PreferencesService.getVersionEra();
      expect(edition, MinecraftEdition.bedrock);
      expect(era, VersionEra.legacy);

      // Simulate restart: re-read from the same SharedPreferences store
      final editionAfterRestart = await PreferencesService.getEdition();
      final eraAfterRestart = await PreferencesService.getVersionEra();
      expect(editionAfterRestart, MinecraftEdition.bedrock);
      expect(eraAfterRestart, VersionEra.legacy);
    });

    test('preferences survive clear-and-reload cycle', () async {
      // Save initial preferences
      await PreferencesService.saveEdition(MinecraftEdition.bedrock);
      await PreferencesService.saveVersionEra(VersionEra.legacy);

      // Simulate restart by getting a fresh SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Verify data is still in the store
      final rawEdition = prefs.getString('minecraft_edition');
      final rawEra = prefs.getString('version_era');
      expect(rawEdition, 'bedrock');
      expect(rawEra, 'legacy');

      // Load via PreferencesService (simulating app init)
      final edition = await PreferencesService.getEdition();
      final era = await PreferencesService.getVersionEra();
      expect(edition, MinecraftEdition.bedrock);
      expect(era, VersionEra.legacy);
    });

    test('defaults returned when preferences are cleared', () async {
      // Save then clear
      await PreferencesService.saveEdition(MinecraftEdition.bedrock);
      await PreferencesService.saveVersionEra(VersionEra.legacy);

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // After clear, defaults should be returned
      final edition = await PreferencesService.getEdition();
      final era = await PreferencesService.getVersionEra();
      expect(edition, MinecraftEdition.java);
      expect(era, VersionEra.modern);
    });
  });
}
