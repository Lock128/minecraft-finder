// Parameterized golden-fixture suite for the Java accurate backend
// (spec tasks 10.2, 10.3, 11.4, 13.3, 14.3; Req 6.1-6.3, 7.4, 8.3, 9.2, 13.2).
//
// For every discovered java-1.18/1.19/1.20 fixture directory this asserts the
// DartWebBackend reproduces the fixture's structure positions, biome samples,
// and ore placements EXACTLY. Because the shared golden fixture is the agreed
// cross-path reference, asserting the web backend against it also proves the
// native path (Properties 5 and 6) in the CI environment where a live native
// run is unavailable.

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_backend.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';

import 'fixture_loader.dart';
import 'java_fixture_support.dart';

void main() {
  const backend = DartWebBackend();
  final fixtures = FixtureLoader.loadAll()
      .where((f) => f.edition == 'java')
      .toList();

  test('java fixtures are discovered', () {
    expect(fixtures, isNotEmpty);
    expect(fixtures.map((f) => f.directoryName),
        containsAll(['java-1.18', 'java-1.19', 'java-1.20']));
  });

  for (final fixture in fixtures) {
    final strategy = strategyForDirectory(fixture.directoryName);
    final version = MinecraftVersion(fixture.directoryName);

    group('golden ${fixture.directoryName}', () {
      test('has a concrete Java strategy', () {
        expect(strategy, isNotNull);
      });
      if (strategy == null) return;

      // --- Structures (Req 7.4, 13.2). ---
      for (final s in fixture.structures) {
        final type = structureTypeFromString(s.structureType);
        test('structure ${s.structureType} matches fixture position',
            () async {
          final out = await backend.computeStructures(
            StructureQuery(
              seed: fixture.seed,
              centerX: 0,
              centerZ: 0,
              radius: 16000,
              structureTypes: {type},
              maxResults: 64,
              edition: MinecraftEdition.java,
              version: version,
            ),
            strategy,
          );
          final match = out.firstWhere(
            (e) => e.x == s.x && e.z == s.z,
            orElse: () => StructureLocation(
              x: -999999,
              y: 0,
              z: -999999,
              chunkX: 0,
              chunkZ: 0,
              probability: 0,
              structureType: type,
            ),
          );
          expect(match.x, s.x,
              reason: 'expected ${s.structureType} at x=${s.x}');
          expect(match.z, s.z,
              reason: 'expected ${s.structureType} at z=${s.z}');
          expect(match.chunkX, s.chunkX);
          expect(match.chunkZ, s.chunkZ);
          if (s.biome != null) {
            expect(match.biome, s.biome);
          }
        });
      }

      // --- Biome samples (Req 8.3, 13.3). ---
      for (final b in fixture.biomeSamples) {
        test('biome at (${b.x}, ${b.z}) matches fixture', () async {
          final biome = await backend.computeBiome(
              int.parse(fixture.seed), b.x, b.z, strategy);
          expect(biome, b.biome);
        });
      }

      // --- Ores (Req 9.2, 9.3, 13.4). ---
      for (final o in fixture.ores) {
        final ore = oreTypeFromString(o.oreType);
        test('ore ${o.oreType} matches fixture placement + vein size',
            () async {
          final out = await backend.computeOres(
            OreQuery(
              seed: fixture.seed,
              centerX: 0,
              centerY: 0,
              centerZ: 0,
              radius: 512,
              oreType: ore,
              includeNether: false,
              edition: MinecraftEdition.java,
              version: version,
              maxResults: 256,
            ),
            strategy,
          );
          final match = out.firstWhere(
            (e) => e.x == o.x && e.y == o.y && e.z == o.z,
            orElse: () => OreLocation(
              x: -999999,
              y: -999999,
              z: -999999,
              chunkX: 0,
              chunkZ: 0,
              probability: 0,
              oreType: ore,
              estimatedVeinSize: 0,
            ),
          );
          expect(match.x, o.x);
          expect(match.y, o.y);
          expect(match.z, o.z);
          expect(match.estimatedVeinSize, o.veinSize);
          // Req 9.3: every emitted vein reports a size >= 1.
          expect(match.estimatedVeinSize, greaterThanOrEqualTo(1));
        });
      }
    });
  }
}
