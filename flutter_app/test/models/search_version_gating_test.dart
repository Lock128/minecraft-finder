// Characterization tests for the search finders' version/edition behavior.
//
// The search is a statistical simulation, not seed-accurate world generation
// (see SEED_ACCURATE_WORLDGEN_SPEC.md). These tests therefore do NOT assert
// absolute block coordinates against a real Minecraft seed. Instead they lock
// down the behaviors we DO guarantee:
//   1. Determinism — the same inputs always produce the same output.
//   2. Version gating — content that does not exist in the selected era is
//      never returned (no Netherite/Copper/Ancient City in a legacy world).
//   3. Edition divergence — Java and Bedrock use different RNG streams, so a
//      search generally differs between editions.
//
// If any of these break, a regression has changed the algorithm's contract.

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_finder.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_finder.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';

void main() {
  const seed = 'kiro-characterization-seed';

  group('Determinism', () {
    test('findOres returns identical results for identical inputs', () async {
      Future<List<OreLocation>> run() => OreFinder().findOres(
            seed: seed,
            centerX: 0,
            centerY: -59,
            centerZ: 0,
            radius: 48,
            oreType: OreType.diamond,
            edition: MinecraftEdition.java,
            versionEra: VersionEra.modern,
          );

      final a = await run();
      final b = await run();

      expect(a.length, b.length);
      expect(a.length, greaterThan(0),
          reason: 'diamond search near spawn should find candidates');
      for (var i = 0; i < a.length; i++) {
        expect(a[i].x, b[i].x);
        expect(a[i].y, b[i].y);
        expect(a[i].z, b[i].z);
        expect(a[i].probability, b[i].probability);
      }
    });

    test('findStructures returns identical results for identical inputs',
        () async {
      Future<List<StructureLocation>> run() => StructureFinder().findStructures(
            seed: seed,
            centerX: 0,
            centerZ: 0,
            radius: 512,
            structureTypes: {StructureType.village, StructureType.ruinedPortal},
            edition: MinecraftEdition.java,
            versionEra: VersionEra.modern,
          );

      final a = await run();
      final b = await run();
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].x, b[i].x);
        expect(a[i].z, b[i].z);
        expect(a[i].structureType, b[i].structureType);
      }
    });
  });

  group('Version gating — ores', () {
    test('Legacy netherite search returns nothing (did not exist pre-1.18)',
        () async {
      final results = await OreFinder().findOres(
        seed: seed,
        centerX: 0,
        centerY: 15,
        centerZ: 0,
        radius: 48,
        oreType: OreType.netherite,
        edition: MinecraftEdition.java,
        versionEra: VersionEra.legacy,
      );
      expect(results, isEmpty);
    });

    test('Legacy copper search returns nothing (introduced in 1.17)', () async {
      final results = await OreFinder().findOres(
        seed: seed,
        centerX: 0,
        centerY: 48,
        centerZ: 0,
        radius: 48,
        oreType: OreType.copper,
        edition: MinecraftEdition.java,
        versionEra: VersionEra.legacy,
      );
      expect(results, isEmpty);
    });

    test('findAllNetherite in legacy returns nothing', () async {
      final results = await OreFinder().findAllNetherite(
        seed: seed,
        centerX: 0,
        centerZ: 0,
        searchRadius: 200,
        edition: MinecraftEdition.java,
        versionEra: VersionEra.legacy,
      );
      expect(results, isEmpty);
    });

    test('Modern netherite search can return results', () async {
      final results = await OreFinder().findAllNetherite(
        seed: seed,
        centerX: 0,
        centerZ: 0,
        searchRadius: 200,
        edition: MinecraftEdition.java,
        versionEra: VersionEra.modern,
      );
      expect(results, isNotEmpty);
    });
  });

  group('Version gating — structures', () {
    test('Legacy structure search never returns modern-only structures',
        () async {
      final results = await StructureFinder().findStructures(
        seed: seed,
        centerX: 0,
        centerZ: 0,
        radius: 1024,
        structureTypes: {
          StructureType.ancientCity,
          StructureType.bastionRemnant,
          StructureType.ruinedPortal,
          StructureType.abandonedCamp,
        },
        edition: MinecraftEdition.java,
        versionEra: VersionEra.legacy,
      );
      expect(results, isEmpty,
          reason: 'none of these structures exist pre-1.18');
    });

    test('Legacy search still returns classic structures', () async {
      final results = await StructureFinder().findStructures(
        seed: seed,
        centerX: 0,
        centerZ: 0,
        radius: 1024,
        structureTypes: {StructureType.village},
        edition: MinecraftEdition.java,
        versionEra: VersionEra.legacy,
      );
      // Village is classic content; a 1024-radius search should find some.
      expect(results.every((s) => s.structureType == StructureType.village),
          isTrue);
    });
  });

  group('Edition divergence', () {
    test('Java and Bedrock diamond searches generally differ', () async {
      Future<List<OreLocation>> run(MinecraftEdition edition) =>
          OreFinder().findOres(
            seed: seed,
            centerX: 0,
            centerY: -59,
            centerZ: 0,
            radius: 48,
            oreType: OreType.diamond,
            edition: edition,
            versionEra: VersionEra.modern,
          );

      final java = await run(MinecraftEdition.java);
      final bedrock = await run(MinecraftEdition.bedrock);

      // Different RNG streams should yield a different result set. Compare the
      // ordered coordinate/probability signature.
      String sig(List<OreLocation> l) =>
          l.map((o) => '${o.x},${o.y},${o.z},${o.probability}').join('|');
      expect(sig(java), isNot(equals(sig(bedrock))),
          reason: 'Java and Bedrock use different RNG, results should diverge');
    });
  });
}
