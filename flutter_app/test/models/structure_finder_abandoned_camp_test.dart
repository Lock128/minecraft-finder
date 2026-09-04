// Feature: Third Drop 2026 – Abandoned Camp structure + Dappled Forest biome.
//
// Verifies that the new StructureType.abandonedCamp is present, is the last
// enum value (index stability for RNG seed mixing), that findStructures can
// discover Abandoned Camps for a fixed seed, and that an existing structure
// (village) still generates for the same seed (regression guard against any
// enum index shift).

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_finder.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';

void main() {
  group('Third Drop 2026: Abandoned Camp structure', () {
    test('StructureType enum contains abandonedCamp as the last value', () {
      expect(StructureType.values.contains(StructureType.abandonedCamp), isTrue);
      expect(StructureType.values.last, StructureType.abandonedCamp);
    });

    test('findStructures can return abandonedCamp locations for a fixed seed',
        () async {
      final finder = StructureFinder();

      // Scan a set of deterministic seeds; over a wide radius at least one is
      // expected to contain the new biome + structure. This keeps the test
      // deterministic while tolerating the noise-driven biome distribution.
      List<StructureLocation> found = [];
      String? matchingSeed;
      for (final seed in ['1', '42', '123', '2026', '777', '9999']) {
        final locations = await finder.findStructures(
          seed: seed,
          centerX: 0,
          centerZ: 0,
          radius: 2000,
          structureTypes: {StructureType.abandonedCamp},
          minProbability: 0.01,
        );
        if (locations.isNotEmpty) {
          found = locations;
          matchingSeed = seed;
          break;
        }
      }

      expect(matchingSeed, isNotNull,
          reason:
              'Expected at least one seed to produce an Abandoned Camp within radius');
      expect(found, isNotEmpty);
      for (final loc in found) {
        expect(loc.structureType, StructureType.abandonedCamp);
        expect(loc.biome, isNotNull);
        expect(['dappled_forest', 'cherry_grove'].contains(loc.biome), isTrue,
            reason:
                'Abandoned Camp should only appear in dappled_forest or cherry_grove');
      }
    });

    test('existing structures (village) still generate for a fixed seed '
        '(index-shift regression guard)', () async {
      final finder = StructureFinder();

      // A village is common; over a moderate radius at least one seed should
      // produce results. If the enum index had shifted, RNG seed mixing would
      // change and this could regress, so we guard it explicitly.
      List<StructureLocation> villages = [];
      for (final seed in ['1', '42', '123', '2026', '777', '9999']) {
        final locations = await finder.findStructures(
          seed: seed,
          centerX: 0,
          centerZ: 0,
          radius: 2000,
          structureTypes: {StructureType.village},
          minProbability: 0.01,
        );
        if (locations.isNotEmpty) {
          villages = locations;
          break;
        }
      }

      expect(villages, isNotEmpty,
          reason: 'Villages should still generate after appending abandonedCamp');
      for (final loc in villages) {
        expect(loc.structureType, StructureType.village);
      }
    });

    test('woodland mansions still generate after the forest band was '
        'subdivided for the new biomes (spawn-area regression guard)', () async {
      final finder = StructureFinder();

      // Subdividing the cool-temperate 'forest' band to introduce
      // 'dappled_forest'/'cherry_grove' would have halved the mansion-eligible
      // area if woodlandMansion still only accepted 'forest'. We extended its
      // eligibility to the wooded slices, so mansions must still generate for
      // at least one fixed seed over a wide radius.
      List<StructureLocation> mansions = [];
      for (final seed in ['1', '42', '123', '2026', '777', '9999']) {
        final locations = await finder.findStructures(
          seed: seed,
          centerX: 0,
          centerZ: 0,
          radius: 5000,
          structureTypes: {StructureType.woodlandMansion},
          minProbability: 0.01,
        );
        if (locations.isNotEmpty) {
          mansions = locations;
          break;
        }
      }

      expect(mansions, isNotEmpty,
          reason:
              'Woodland mansions should still generate after the forest band was subdivided');
      for (final loc in mansions) {
        expect(loc.structureType, StructureType.woodlandMansion);
        expect(
            ['forest', 'dappled_forest', 'cherry_grove'].contains(loc.biome),
            isTrue,
            reason:
                'Woodland mansions should appear in the wooded biome slices');
      }
    });
  });
}
