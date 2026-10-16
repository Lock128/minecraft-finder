// Bedrock-track correctness property test (spec task 19.3).
//
// Property 18: Bedrock uses MT19937 and matches the reference (Req 11.1).
//   Runs >= 100 iterations over random seeds and asserts:
//     * the Bedrock RNG is the MT19937 BedrockRandom (same stream the backend
//       uses) and is deterministic for a given seed;
//     * the BedrockBackend reproduces the shared BedrockPlacement reference
//       (region-grid structures and ore loops) exactly;
//     * the backend never silently falls back to the Java LCG (a Bedrock
//       strategy reports usesMt19937 == true).
//
// Tagged with the exact property text it validates.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/bedrock_random.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/bedrock_backend.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/bedrock_placement.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/bedrock_version_strategy.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/java_placement.dart'
    show JavaPlacement;
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';

const int _iterations = 150;

void main() {
  final strategy = BedrockVersionStrategy.bedrock121();
  const backend = BedrockBackend();

  test('Bedrock strategy reports MT19937 (Property 18 precondition)', () {
    expect(strategy.rngParams.usesMt19937, isTrue);
  });

  group('Property 18: Bedrock uses MT19937 and matches the reference', () {
    test('>=100 iters: MT19937 BedrockRandom is deterministic per seed',
        () async {
      final r = Random(1801);
      for (int i = 0; i < _iterations; i++) {
        final seed = r.nextInt(0xFFFFFFFF);
        final a = BedrockRandom(seed);
        final b = BedrockRandom(seed);
        // Same seed -> identical MT19937 stream.
        for (int k = 0; k < 8; k++) {
          expect(a.nextInt(1 << 20), b.nextInt(1 << 20));
        }
      }
    });

    test('>=100 iters: backend structures reproduce the MT19937 reference',
        () async {
      final r = Random(1802);
      for (int i = 0; i < _iterations; i++) {
        final seed = r.nextInt(0xFFFFFFFF);
        final placement = strategy.placementFor(StructureType.shipwreck);
        // Reference = pure BedrockPlacement (MT19937) math.
        final refChunks = BedrockPlacement.regionStructuresInRange(
          worldSeed: seed,
          centerBlockX: 0,
          centerBlockZ: 0,
          radius: 2000,
          placement: placement,
        );
        final out = await backend.computeStructures(
          StructureQuery(
            seed: seed.toString(),
            centerX: 0,
            centerZ: 0,
            radius: 2000,
            structureTypes: {StructureType.shipwreck},
            maxResults: 256,
            edition: MinecraftEdition.bedrock,
            version: MinecraftVersion('bedrock-1.21'),
          ),
          strategy,
        );
        // Shipwreck is not biome-gated here, so every reference chunk appears.
        final outKeys = out.map((e) => '${e.chunkX},${e.chunkZ}').toSet();
        for (final c in refChunks) {
          expect(outKeys.contains('${c.x},${c.z}'), isTrue,
              reason: 'backend dropped MT19937 reference chunk ${c.x},${c.z}');
        }
      }
    });

    test('>=100 iters: backend ores reproduce the MT19937 reference',
        () async {
      final r = Random(1803);
      final ores = [OreType.diamond, OreType.iron, OreType.gold];
      int total = 0;
      for (int i = 0; i < _iterations; i++) {
        final seed = r.nextInt(0xFFFFFFFF);
        final ore = ores[i % ores.length];
        final feature = strategy.oreFeatureFor(ore);
        final ref = BedrockPlacement.veinsInRange(
          worldSeed: seed,
          centerX: 0,
          centerZ: 0,
          radius: 48,
          feature: feature,
          featureIndex: ore.index,
        );
        final out = await backend.computeOres(
          OreQuery(
            seed: seed.toString(),
            centerX: 0,
            centerY: 0,
            centerZ: 0,
            radius: 48,
            oreType: ore,
            includeNether: false,
            edition: MinecraftEdition.bedrock,
            version: MinecraftVersion('bedrock-1.21'),
            maxResults: 1024,
          ),
          strategy,
        );
        expect(out.length, ref.length);
        for (int k = 0; k < ref.length; k++) {
          expect(out[k].x, ref[k].x);
          expect(out[k].y, ref[k].y);
          expect(out[k].z, ref[k].z);
          expect(out[k].estimatedVeinSize, ref[k].size);
          expect(out[k].estimatedVeinSize, greaterThanOrEqualTo(1));
          total++;
        }
      }
      expect(total, greaterThan(0));
    });

    test('>=100 iters: ore veins stay inside the feature Y band', () async {
      final r = Random(1804);
      for (int i = 0; i < _iterations; i++) {
        final seed = r.nextInt(0xFFFFFFFF);
        final feature = strategy.oreFeatureFor(OreType.diamond);
        final chunkX = r.nextInt(2000) - 1000;
        final chunkZ = r.nextInt(2000) - 1000;
        final veins = BedrockPlacement.veinsInChunk(
          worldSeed: seed,
          chunkX: chunkX,
          chunkZ: chunkZ,
          feature: feature,
          featureIndex: OreType.diamond.index,
        );
        expect(veins.length, feature.countPerChunk);
        for (final v in veins) {
          expect(v.y, inInclusiveRange(feature.minY, feature.maxY));
          expect(JavaPlacement.blockToChunk(v.x), chunkX);
          expect(JavaPlacement.blockToChunk(v.z), chunkZ);
          expect(v.size, inInclusiveRange(1, feature.maxVeinSize));
        }
      }
    });
  });
}
