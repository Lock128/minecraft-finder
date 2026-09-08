// Feature: Algorithm currency (round 2) — shared biome classifier + modern
// ocean/beach categories.
//
// Guards three properties:
//  (a) OreFinder and StructureFinder classify a grid of sample coordinates
//      IDENTICALLY for a fixed seed (both delegate to the shared
//      BiomeClassifier, so this fails loudly if they ever drift apart again).
//  (b) oceanMonument, shipwreck and buriedTreasure still generate for fixed
//      seeds over a wide radius — a regression guard proving that subdividing
//      the old single 'ocean' band into ocean/deep_ocean/beach did not remove
//      their spawns.
//  (c) abandonedCamp still only appears in dappled_forest / cherry_grove.

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/biome_classifier.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_finder.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_finder.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/java_random.dart';

void main() {
  group('Round 2: shared biome classifier', () {
    test(
        'OreFinder and StructureFinder classify a coordinate grid '
        'identically for a fixed seed (drift guard)', () {
      final ore = OreFinder();
      final structure = StructureFinder();

      for (final seed in ['1', '42', '2026', 'hello', '-987654321']) {
        final worldSeed = MinecraftRandom.stringToSeed(seed);
        for (int x = -2000; x <= 2000; x += 250) {
          for (int z = -2000; z <= 2000; z += 250) {
            expect(
              ore.biomeAt(x, z, worldSeed),
              structure.biomeAt(x, z, worldSeed),
              reason:
                  'OreFinder and StructureFinder must agree at ($x,$z) seed=$seed',
            );
          }
        }
      }
    });

    test('BiomeClassifier is deterministic across independent instances', () {
      final a = BiomeClassifier();
      final b = BiomeClassifier();
      for (int x = -1000; x <= 1000; x += 100) {
        for (int z = -1000; z <= 1000; z += 100) {
          expect(a.classify(x, z, 12345), b.classify(x, z, 12345));
        }
      }
    });

    test(
        'classifier emits only known biome strings and produces the new '
        'water categories (ocean, deep_ocean, beach) plus the round-1 biomes',
        () {
      const knownBiomes = {
        'taiga',
        'swamp',
        'mountains',
        'forest',
        'dappled_forest',
        'cherry_grove',
        'jungle',
        'plains',
        'savanna',
        'beach',
        'ocean',
        'deep_ocean',
        'desert',
        'badlands',
      };

      final classifier = BiomeClassifier();
      final seen = <String>{};
      // Scan several seeds so the multi-noise distribution is well covered.
      for (final worldSeed in [1, 42, 2026, 777, 9999, 123456]) {
        for (int x = -6000; x <= 6000; x += 60) {
          for (int z = -6000; z <= 6000; z += 60) {
            seen.add(classifier.classify(x, z, worldSeed));
          }
        }
      }

      // The classifier must never emit an unexpected biome string.
      expect(seen.difference(knownBiomes), isEmpty,
          reason:
              'Unexpected biome string(s): ${seen.difference(knownBiomes)}');

      // Round-1 biomes must still be reachable.
      expect(seen.contains('dappled_forest'), isTrue);
      expect(seen.contains('cherry_grove'), isTrue);
      // Round-2 modern water categories must all be reachable (proves the
      // 'ocean' band was actually subdivided, not just renamed).
      expect(seen.contains('ocean'), isTrue);
      expect(seen.contains('deep_ocean'), isTrue);
      expect(seen.contains('beach'), isTrue);
    });
  });

  group('Round 2: ocean-dependent structures survive the water split', () {
    Future<List<StructureLocation>> findAcrossSeeds(
        StructureType type, int radius) async {
      final finder = StructureFinder();
      for (final seed in ['1', '42', '123', '2026', '777', '9999']) {
        final locations = await finder.findStructures(
          seed: seed,
          centerX: 0,
          centerZ: 0,
          radius: radius,
          structureTypes: {type},
          minProbability: 0.01,
        );
        if (locations.isNotEmpty) return locations;
      }
      return [];
    }

    test('oceanMonument still generates and only in ocean/deep_ocean',
        () async {
      final results = await findAcrossSeeds(StructureType.oceanMonument, 5000);
      expect(results, isNotEmpty,
          reason: 'Ocean monuments should still generate after the split');
      for (final loc in results) {
        expect(['ocean', 'deep_ocean'].contains(loc.biome), isTrue,
            reason: 'Ocean monument biome was ${loc.biome}');
      }
    });

    test('shipwreck still generates and only in ocean/deep_ocean/beach',
        () async {
      final results = await findAcrossSeeds(StructureType.shipwreck, 5000);
      expect(results, isNotEmpty,
          reason: 'Shipwrecks should still generate after the split');
      for (final loc in results) {
        expect(['ocean', 'deep_ocean', 'beach'].contains(loc.biome), isTrue,
            reason: 'Shipwreck biome was ${loc.biome}');
      }
    });

    test('buriedTreasure still generates and only in beach/ocean/deep_ocean',
        () async {
      final results = await findAcrossSeeds(StructureType.buriedTreasure, 5000);
      expect(results, isNotEmpty,
          reason: 'Buried treasure should still generate after the split');
      for (final loc in results) {
        expect(['beach', 'ocean', 'deep_ocean'].contains(loc.biome), isTrue,
            reason: 'Buried treasure biome was ${loc.biome}');
      }
    });

    test('abandonedCamp still only appears in dappled_forest/cherry_grove',
        () async {
      final results = await findAcrossSeeds(StructureType.abandonedCamp, 5000);
      expect(results, isNotEmpty,
          reason: 'Abandoned camps should still generate');
      for (final loc in results) {
        expect(['dappled_forest', 'cherry_grove'].contains(loc.biome), isTrue,
            reason: 'Abandoned camp biome was ${loc.biome}');
      }
    });
  });
}
