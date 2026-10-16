// Parameterized golden-fixture suite for the Bedrock accurate backend
// (spec tasks 19.1, 19.2; Req 11.1, 11.2, 10.3).
//
// For every discovered bedrock-* fixture directory this asserts the
// BedrockBackend (MT19937 via BedrockRandom) reproduces the fixture's structure
// positions, biome samples, and ore placements EXACTLY. The Bedrock fixtures
// are algorithm-derived (the Bedrock placement constants are not published the
// way Java's data-driven StructureSets are), so these fixtures are the agreed
// self-consistent reference; the Bedrock version stays Supported-but-NOT-
// Verified until an authoritative Bedrock source confirms the constants.

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/bedrock_backend.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/bedrock_version_strategy.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';

import 'fixture_loader.dart';
import 'java_fixture_support.dart';

void main() {
  const backend = BedrockBackend();
  final fixtures =
      FixtureLoader.loadAll().where((f) => f.edition == 'bedrock').toList();

  test('bedrock fixtures are discovered', () {
    expect(fixtures, isNotEmpty);
    expect(fixtures.map((f) => f.directoryName), contains('bedrock-1.21'));
  });

  for (final fixture in fixtures) {
    final strategy = BedrockVersionStrategy.bedrock121();
    final version = MinecraftVersion(fixture.directoryName);

    group('golden ${fixture.directoryName}', () {
      // --- Structures (Req 11.2). ---
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
              edition: MinecraftEdition.bedrock,
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

      // --- Biome samples (Req 10.3). ---
      for (final b in fixture.biomeSamples) {
        test('biome at (${b.x}, ${b.z}) matches fixture', () async {
          final biome = await backend.computeBiome(
              int.parse(fixture.seed), b.x, b.z, strategy);
          expect(biome, b.biome);
        });
      }

      // --- Ores (Req 11.2). ---
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
              edition: MinecraftEdition.bedrock,
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
          expect(match.estimatedVeinSize, greaterThanOrEqualTo(1));
        });
      }
    });
  }
}
