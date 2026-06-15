import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/search_history_entry.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';

void main() {
  group('SearchHistoryEntry', () {
    test('fromJson/toJson roundtrip preserves all fields', () {
      final original = SearchHistoryEntry(
        seed: '8674308105921866736',
        centerX: 100,
        centerY: -59,
        centerZ: -200,
        radius: 75,
        oreTypes: {OreType.diamond, OreType.gold},
        structures: {StructureType.village, StructureType.stronghold},
        edition: MinecraftEdition.java,
        versionEra: VersionEra.modern,
        timestamp: DateTime(2024, 6, 15, 12, 30),
        resultCount: 42,
        includeOres: true,
        includeStructures: true,
      );

      final json = original.toJson();
      final restored = SearchHistoryEntry.fromJson(json);

      expect(restored.seed, '8674308105921866736');
      expect(restored.centerX, 100);
      expect(restored.centerY, -59);
      expect(restored.centerZ, -200);
      expect(restored.radius, 75);
      expect(restored.oreTypes, contains(OreType.diamond));
      expect(restored.oreTypes, contains(OreType.gold));
      expect(restored.structures, contains(StructureType.village));
      expect(restored.structures, contains(StructureType.stronghold));
      expect(restored.edition, MinecraftEdition.java);
      expect(restored.versionEra, VersionEra.modern);
      expect(restored.timestamp.year, 2024);
      expect(restored.resultCount, 42);
      expect(restored.includeOres, true);
      expect(restored.includeStructures, true);
    });

    test('fromJson handles bedrock edition', () {
      final json = {
        'seed': 'test',
        'centerX': 0,
        'centerY': 0,
        'centerZ': 0,
        'radius': 50,
        'oreTypes': ['diamond'],
        'structures': [],
        'edition': 'bedrock',
        'versionEra': 'legacy',
        'timestamp': '2024-01-01T00:00:00.000',
        'resultCount': 5,
        'includeOres': true,
        'includeStructures': false,
      };

      final entry = SearchHistoryEntry.fromJson(json);
      expect(entry.edition, MinecraftEdition.bedrock);
      expect(entry.versionEra, VersionEra.legacy);
    });

    test('fromJson defaults includeOres to true and includeStructures to false',
        () {
      final json = {
        'seed': 'test',
        'centerX': 0,
        'centerY': 0,
        'centerZ': 0,
        'radius': 50,
        'oreTypes': ['diamond'],
        'structures': [],
        'edition': 'java',
        'versionEra': 'modern',
        'timestamp': '2024-01-01T00:00:00.000',
        'resultCount': 5,
      };

      final entry = SearchHistoryEntry.fromJson(json);
      expect(entry.includeOres, true);
      expect(entry.includeStructures, false);
    });

    test('fromJson handles unknown ore type with fallback to diamond', () {
      final json = {
        'seed': 'test',
        'centerX': 0,
        'centerY': 0,
        'centerZ': 0,
        'radius': 50,
        'oreTypes': ['unknown_ore', 'gold'],
        'structures': [],
        'edition': 'java',
        'versionEra': 'modern',
        'timestamp': '2024-01-01T00:00:00.000',
        'resultCount': 0,
        'includeOres': true,
        'includeStructures': false,
      };

      final entry = SearchHistoryEntry.fromJson(json);
      expect(entry.oreTypes, contains(OreType.diamond)); // fallback
      expect(entry.oreTypes, contains(OreType.gold));
    });

    test('toJson serializes ore types as strings', () {
      final entry = SearchHistoryEntry(
        seed: 'test',
        centerX: 0,
        centerY: 0,
        centerZ: 0,
        radius: 50,
        oreTypes: {OreType.diamond, OreType.netherite},
        structures: {StructureType.endCity},
        edition: MinecraftEdition.java,
        versionEra: VersionEra.modern,
        timestamp: DateTime.now(),
        resultCount: 0,
        includeOres: true,
        includeStructures: true,
      );

      final json = entry.toJson();
      final oreTypesList = json['oreTypes'] as List;
      expect(oreTypesList, contains('diamond'));
      expect(oreTypesList, contains('netherite'));

      final structuresList = json['structures'] as List;
      expect(structuresList, contains('endCity'));
    });

    test('toJson serializes timestamp as ISO 8601', () {
      final timestamp = DateTime(2024, 6, 15, 12, 30, 45);
      final entry = SearchHistoryEntry(
        seed: 'test',
        centerX: 0,
        centerY: 0,
        centerZ: 0,
        radius: 50,
        oreTypes: {OreType.diamond},
        structures: <StructureType>{},
        edition: MinecraftEdition.java,
        versionEra: VersionEra.modern,
        timestamp: timestamp,
        resultCount: 0,
        includeOres: true,
        includeStructures: false,
      );

      final json = entry.toJson();
      expect(json['timestamp'], timestamp.toIso8601String());
    });
  });
}
