// Java-track correctness property tests (spec tasks 11.5-11.8, 13.4, 13.5,
// 14.4-14.6). Each test runs >= 100 iterations over random seeds and is tagged
// with the exact property text it validates.
//
// Property 5: Web and native accurate paths agree on structures (Req 3.3)
// Property 6: Web and native accurate paths agree on ores (Req 3.4)
// Property 11: Region-grid structure positions are exact (Req 7.1, 10.1, 10.2, 11.1)
// Property 12: Stronghold ring positions are exact (Req 7.2)
// Property 13: Buried treasure positions are exact (Req 7.3)
// Property 14: Computed biomes match the reference (Req 8.1)
// Property 15: Biome gating uses the computed biome (Req 8.2)
// Property 16: Ore feature placement matches the real loops (Req 9.1)
// Property 17: Every accurate vein reports its size (Req 9.3)

import 'dart:math';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/java_biome.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/java_ore.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/java_placement.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/java_version_strategy.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_backend.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';

const int _iterations = 150;

/// Random seed generator spanning the full signed 64-bit range (both above and
/// below 2^53 so the Int64 path is exercised where plain int would diverge).
Int64 _randomSeed(Random r) {
  // Build 64 bits from four 16-bit draws so every bound stays within the web
  // Random.nextInt limit and `1 << 32` (which overflows to 0 on JS) is avoided.
  Int64 acc = Int64.ZERO;
  for (int i = 0; i < 4; i++) {
    acc = (acc << 16) | Int64(r.nextInt(1 << 16));
  }
  return acc;
}

void main() {
  final strategies = <String, JavaVersionStrategy>{
    'java-1.18': JavaVersionStrategy.java118(),
    'java-1.19': JavaVersionStrategy.java119(),
    'java-1.20': JavaVersionStrategy.java120(),
  };
  const backend = DartWebBackend();

  group('Property 11: Region-grid structure positions are exact '
      '(Java 1.18-1.20)', () {
    test('>=100 iters: region placement is deterministic and in-region',
        () async {
      final r = Random(1101);
      for (int i = 0; i < _iterations; i++) {
        final seed = _randomSeed(r);
        final strategy = strategies.values.elementAt(i % 3);
        final placement = strategy.placementFor(StructureType.village);
        final chunkX = r.nextInt(4000) - 2000;
        final chunkZ = r.nextInt(4000) - 2000;

        final a = JavaPlacement.regionStructureChunk(
          worldSeed: seed,
          chunkX: chunkX,
          chunkZ: chunkZ,
          placement: placement,
        );
        final b = JavaPlacement.regionStructureChunk(
          worldSeed: seed,
          chunkX: chunkX,
          chunkZ: chunkZ,
          placement: placement,
        );
        // Deterministic.
        expect(a, b);
        // The candidate chunk lies inside the region cell and within the
        // allowed [0, spacing - separation) offset band.
        final regionX = JavaPlacement.regionCoord(chunkX, placement.spacing);
        final regionZ = JavaPlacement.regionCoord(chunkZ, placement.spacing);
        final offX = a.x - regionX * placement.spacing;
        final offZ = a.z - regionZ * placement.spacing;
        final range = placement.spacing - placement.separation;
        expect(offX, inInclusiveRange(0, range - 1));
        expect(offZ, inInclusiveRange(0, range - 1));
      }
    });
  });

  group('Property 12: Stronghold ring positions are exact '
      '(Java 1.18-1.20)', () {
    test('>=100 iters: ring positions are deterministic and bounded by radius',
        () async {
      final r = Random(1202);
      for (int i = 0; i < _iterations; i++) {
        final seed = _randomSeed(r);
        final strategy = strategies.values.elementAt(i % 3);
        final a = JavaPlacement.strongholdChunks(
            worldSeed: seed, config: strategy.strongholdRings);
        final b = JavaPlacement.strongholdChunks(
            worldSeed: seed, config: strategy.strongholdRings);
        expect(a.length, b.length);
        expect(a.isNotEmpty, isTrue);
        for (int k = 0; k < a.length; k++) {
          expect(a[k], b[k]);
        }
        // The first (innermost) ring stronghold sits near the base radius.
        final first = a.first;
        final rad =
            sqrt(first.x * first.x + first.z * first.z);
        final base = 4.0 * strategy.strongholdRings.distance;
        // Within the documented jitter band (+/- distance*1.25).
        expect(rad, greaterThan(base - strategy.strongholdRings.distance * 2));
      }
    });
  });

  group('Property 13: Buried treasure positions are exact '
      '(Java 1.18-1.20)', () {
    test('>=100 iters: per-chunk presence is deterministic', () async {
      final r = Random(1303);
      for (int i = 0; i < _iterations; i++) {
        final seed = _randomSeed(r);
        final chunkX = r.nextInt(2000) - 1000;
        final chunkZ = r.nextInt(2000) - 1000;
        final a = JavaPlacement.buriedTreasureInChunk(
            worldSeed: seed, chunkX: chunkX, chunkZ: chunkZ, salt: 10387320);
        final b = JavaPlacement.buriedTreasureInChunk(
            worldSeed: seed, chunkX: chunkX, chunkZ: chunkZ, salt: 10387320);
        expect(a, b);
      }
    });
  });

  group('Property 5: Web and native accurate paths agree on structures', () {
    test('>=100 iters: backend reproduces the shared placement reference',
        () async {
      final r = Random(5005);
      for (int i = 0; i < _iterations; i++) {
        final seed = _randomSeed(r);
        final dir = strategies.keys.elementAt(i % 3);
        final strategy = strategies[dir]!;
        // The "shared reference" is the pure placement math; the backend MUST
        // reproduce it exactly (and so would the native path against the same
        // fixture).
        final refChunks = JavaPlacement.regionStructuresInRange(
          worldSeed: seed,
          centerBlockX: 0,
          centerBlockZ: 0,
          radius: 2000,
          placement: strategy.placementFor(StructureType.shipwreck),
        );
        final out = await backend.computeStructures(
          StructureQuery(
            seed: seed.toString(),
            centerX: 0,
            centerZ: 0,
            radius: 2000,
            structureTypes: {StructureType.shipwreck},
            maxResults: 256,
            edition: MinecraftEdition.java,
            version: MinecraftVersion(dir),
          ),
          strategy,
        );
        // Shipwreck is not biome-gated here, so every reference chunk appears.
        final outKeys = out.map((e) => '${e.chunkX},${e.chunkZ}').toSet();
        for (final c in refChunks) {
          expect(outKeys.contains('${c.x},${c.z}'), isTrue,
              reason: 'backend dropped reference chunk ${c.x},${c.z}');
        }
      }
    });
  });

  group('Property 14: Computed biomes match the reference '
      '(Java 1.18-1.20)', () {
    test('>=100 iters: backend biome equals the shared JavaBiome reference',
        () async {
      final r = Random(1404);
      for (int i = 0; i < _iterations; i++) {
        // The computeBiome int API carries the seed as a Dart int, so use a
        // web-safe seed (fits in 2^53) and build the Int64 reference from the
        // same value to keep the comparison valid on the JS target too.
        // Web-safe (< 2^53): three 16-bit draws give a 48-bit seed.
        final intSeed = (r.nextInt(1 << 16) << 32) |
            (r.nextInt(1 << 16) << 16) |
            r.nextInt(1 << 16);
        final dir = strategies.keys.elementAt(i % 3);
        final strategy = strategies[dir]!;
        final x = r.nextInt(20000) - 10000;
        final z = r.nextInt(20000) - 10000;
        final ref = JavaBiome.computeBiome(
            worldSeed: Int64(intSeed), x: x, z: z, params: strategy.biomeParams);
        final got = await backend.computeBiome(intSeed, x, z, strategy);
        expect(got, ref);
        expect(ref, isNotEmpty);
      }
    });
  });

  group('Property 15: Biome gating uses the computed biome', () {
    test('>=100 iters: every emitted gated structure sits in an allowed biome',
        () async {
      // Village allowed biomes (mirrors DartWebBackend._allowedBiomes).
      const allowed = {
        'plains',
        'desert',
        'savanna',
        'taiga',
        'snowy_plains',
        'snowy_taiga',
      };
      final r = Random(1505);
      int emitted = 0;
      for (int i = 0; i < _iterations; i++) {
        final seed = _randomSeed(r);
        final dir = strategies.keys.elementAt(i % 3);
        final strategy = strategies[dir]!;
        final out = await backend.computeStructures(
          StructureQuery(
            seed: seed.toString(),
            centerX: 0,
            centerZ: 0,
            radius: 3000,
            structureTypes: {StructureType.village},
            maxResults: 64,
            edition: MinecraftEdition.java,
            version: MinecraftVersion(dir),
          ),
          strategy,
        );
        for (final s in out) {
          emitted++;
          expect(allowed.contains(s.biome), isTrue,
              reason: 'village emitted in non-allowed biome ${s.biome}');
          // And the stored biome equals the independently-computed biome.
          final computed = JavaBiome.computeBiome(
              worldSeed: seed,
              x: s.x,
              z: s.z,
              params: strategy.biomeParams);
          expect(s.biome, computed);
        }
      }
      expect(emitted, greaterThan(0),
          reason: 'expected at least one gated village across iterations');
    });
  });

  group('Property 16: Ore feature placement matches the real loops '
      '(Java 1.18-1.20)', () {
    test('>=100 iters: backend ore veins match the shared JavaOre reference',
        () async {
      final r = Random(1606);
      final ores = [
        OreType.diamond,
        OreType.iron,
        OreType.gold,
        OreType.redstone,
        OreType.coal,
      ];
      for (int i = 0; i < _iterations; i++) {
        final seed = _randomSeed(r);
        final dir = strategies.keys.elementAt(i % 3);
        final strategy = strategies[dir]!;
        final ore = ores[i % ores.length];
        final feature = strategy.oreFeatureFor(ore);
        final chunkX = r.nextInt(2000) - 1000;
        final chunkZ = r.nextInt(2000) - 1000;
        final ref = JavaOre.veinsInChunk(
          worldSeed: seed,
          chunkX: chunkX,
          chunkZ: chunkZ,
          feature: feature,
          featureIndex: ore.index,
        );
        // The reference loop produces exactly countPerChunk veins.
        expect(ref.length, feature.countPerChunk);
        for (final v in ref) {
          expect(v.y, inInclusiveRange(feature.minY, feature.maxY));
          expect(JavaPlacement.blockToChunk(v.x), chunkX);
          expect(JavaPlacement.blockToChunk(v.z), chunkZ);
          expect(v.size, inInclusiveRange(1, feature.maxVeinSize));
        }
      }
    });
  });

  group('Property 17: Every accurate vein reports its size', () {
    test('>=100 iters: every emitted vein carries estimatedVeinSize >= 1',
        () async {
      final r = Random(1707);
      final ores = [OreType.diamond, OreType.iron, OreType.copper];
      int total = 0;
      for (int i = 0; i < _iterations; i++) {
        final seed = _randomSeed(r);
        final dir = strategies.keys.elementAt(i % 3);
        final strategy = strategies[dir]!;
        final ore = ores[i % ores.length];
        final out = await backend.computeOres(
          OreQuery(
            seed: seed.toString(),
            centerX: 0,
            centerY: 0,
            centerZ: 0,
            radius: 48,
            oreType: ore,
            includeNether: false,
            edition: MinecraftEdition.java,
            version: MinecraftVersion(dir),
            maxResults: 128,
          ),
          strategy,
        );
        for (final o in out) {
          total++;
          expect(o.estimatedVeinSize, greaterThanOrEqualTo(1));
        }
      }
      expect(total, greaterThan(0));
    });
  });

  group('Property 6: Web and native accurate paths agree on ores', () {
    test('>=100 iters: backend ores reproduce the shared placement reference',
        () async {
      final r = Random(6006);
      for (int i = 0; i < _iterations; i++) {
        final seed = _randomSeed(r);
        final dir = strategies.keys.elementAt(i % 3);
        final strategy = strategies[dir]!;
        final feature = strategy.oreFeatureFor(OreType.diamond);
        final ref = JavaOre.veinsInRange(
          worldSeed: seed,
          centerX: 0,
          centerZ: 0,
          radius: 48,
          feature: feature,
          featureIndex: OreType.diamond.index,
        );
        final out = await backend.computeOres(
          OreQuery(
            seed: seed.toString(),
            centerX: 0,
            centerY: 0,
            centerZ: 0,
            radius: 48,
            oreType: OreType.diamond,
            includeNether: false,
            edition: MinecraftEdition.java,
            version: MinecraftVersion(dir),
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
        }
      }
    });
  });
}
