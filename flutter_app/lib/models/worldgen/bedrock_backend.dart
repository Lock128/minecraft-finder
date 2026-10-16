import '../game_random.dart';
import '../ore_location.dart';
import '../structure_location.dart';
import 'bedrock_placement.dart';
import 'java_biome.dart';
import 'java_placement.dart' show ChunkPos, JavaPlacement;
import 'version_strategy.dart';
import 'worldgen_backend.dart';
import 'worldgen_engine.dart';

import 'package:fixnum/fixnum.dart';

/// Pure-Dart Bedrock Edition backend. Reproduces Bedrock placement with the
/// MT19937 RNG ([BedrockPlacement], which wraps the web-safe [BedrockRandom]),
/// so the same code runs on both the web and native targets (MT19937 is already
/// 32-bit masked and does not need a separate C port for the RNG itself).
///
/// Biome gating reuses the shared [JavaBiome] climate computation (deterministic
/// and version-agnostic); the Bedrock strategy supplies its own `noiseSalt` so
/// the Bedrock biome field is independent from the Java fields.
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
class BedrockBackend implements WorldGenBackend {
  const BedrockBackend();

  static const int _buriedTreasureSalt = 10387320;
  static const double _buriedTreasureProbability = 0.01;

  static const Map<StructureType, Set<String>> _allowedBiomes = {
    StructureType.village: {
      'plains',
      'desert',
      'savanna',
      'taiga',
      'snowy_plains',
      'snowy_taiga',
    },
    StructureType.desertTemple: {'desert'},
    StructureType.jungleTemple: {'jungle'},
    StructureType.pillagerOutpost: {
      'plains',
      'desert',
      'savanna',
      'taiga',
      'snowy_plains',
    },
    StructureType.oceanMonument: {
      'ocean',
      'warm_ocean',
      'frozen_ocean',
    },
    StructureType.woodlandMansion: {'dark_forest'},
  };

  /// This backend runs any Bedrock strategy (MT19937 math is web-safe).
  @override
  bool canRun(VersionStrategy strategy) =>
      strategy.edition == MinecraftEdition.bedrock;

  @override
  Future<List<StructureLocation>> computeStructures(
      StructureQuery query, VersionStrategy strategy) async {
    final int seed = _seedOf(query.seed);
    final results = <StructureLocation>[];

    for (final type in query.structureTypes) {
      switch (type) {
        case StructureType.buriedTreasure:
          _addBuriedTreasure(seed, query, strategy, results);
          break;
        case StructureType.stronghold:
          // Bedrock strongholds use the same concentric-ring model as Java;
          // reuse the Java ring walk (LCG ring positions are shared), gated to
          // the search window.
          _addStrongholds(seed, query, strategy, results);
          break;
        default:
          _addRegionStructures(seed, type, query, strategy, results);
      }
      if (results.length >= query.maxResults) break;
    }

    if (results.length > query.maxResults) {
      return results.sublist(0, query.maxResults);
    }
    return results;
  }

  void _addRegionStructures(
    int seed,
    StructureType type,
    StructureQuery query,
    VersionStrategy strategy,
    List<StructureLocation> out,
  ) {
    final placement = strategy.placementFor(type);
    final chunks = BedrockPlacement.regionStructuresInRange(
      worldSeed: seed,
      centerBlockX: query.centerX,
      centerBlockZ: query.centerZ,
      radius: query.radius,
      placement: placement,
    );
    final allowed = _allowedBiomes[type];
    for (final c in chunks) {
      final int blockX = JavaPlacement.chunkToBlock(c.x) + 8;
      final int blockZ = JavaPlacement.chunkToBlock(c.z) + 8;
      final biome = JavaBiome.computeBiome(
        worldSeed: Int64(seed),
        x: blockX,
        z: blockZ,
        params: strategy.biomeParams,
      );
      if (allowed != null && !allowed.contains(biome)) continue;
      out.add(StructureLocation(
        x: blockX,
        y: 0,
        z: blockZ,
        chunkX: c.x,
        chunkZ: c.z,
        probability: 1.0,
        structureType: type,
        biome: biome,
      ));
      if (out.length >= query.maxResults) return;
    }
  }

  void _addStrongholds(
    int seed,
    StructureQuery query,
    VersionStrategy strategy,
    List<StructureLocation> out,
  ) {
    final chunks = JavaPlacement.strongholdChunks(
      worldSeed: Int64(seed),
      config: strategy.strongholdRings,
    );
    final sorted = [...chunks];
    sorted.sort((a, b) {
      final da = _chunkDistSq(a, query.centerX, query.centerZ);
      final db = _chunkDistSq(b, query.centerX, query.centerZ);
      return da.compareTo(db);
    });
    for (final c in sorted) {
      final int blockX = JavaPlacement.chunkToBlock(c.x) + 8;
      final int blockZ = JavaPlacement.chunkToBlock(c.z) + 8;
      if ((blockX - query.centerX).abs() > query.radius) continue;
      if ((blockZ - query.centerZ).abs() > query.radius) continue;
      final biome = JavaBiome.computeBiome(
        worldSeed: Int64(seed),
        x: blockX,
        z: blockZ,
        params: strategy.biomeParams,
      );
      out.add(StructureLocation(
        x: blockX,
        y: 0,
        z: blockZ,
        chunkX: c.x,
        chunkZ: c.z,
        probability: 1.0,
        structureType: StructureType.stronghold,
        biome: biome,
      ));
      if (out.length >= query.maxResults) return;
    }
  }

  void _addBuriedTreasure(
    int seed,
    StructureQuery query,
    VersionStrategy strategy,
    List<StructureLocation> out,
  ) {
    final int minChunkX =
        JavaPlacement.blockToChunk(query.centerX - query.radius);
    final int maxChunkX =
        JavaPlacement.blockToChunk(query.centerX + query.radius);
    final int minChunkZ =
        JavaPlacement.blockToChunk(query.centerZ - query.radius);
    final int maxChunkZ =
        JavaPlacement.blockToChunk(query.centerZ + query.radius);
    final hits = <StructureLocation>[];
    for (int cx = minChunkX; cx <= maxChunkX; cx++) {
      for (int cz = minChunkZ; cz <= maxChunkZ; cz++) {
        final present = BedrockPlacement.buriedTreasureInChunk(
          worldSeed: seed,
          chunkX: cx,
          chunkZ: cz,
          salt: _buriedTreasureSalt,
          probability: _buriedTreasureProbability,
        );
        if (!present) continue;
        final int blockX = JavaPlacement.chunkToBlock(cx) + 9;
        final int blockZ = JavaPlacement.chunkToBlock(cz) + 9;
        if ((blockX - query.centerX).abs() > query.radius) continue;
        if ((blockZ - query.centerZ).abs() > query.radius) continue;
        final biome = JavaBiome.computeBiome(
          worldSeed: Int64(seed),
          x: blockX,
          z: blockZ,
          params: strategy.biomeParams,
        );
        hits.add(StructureLocation(
          x: blockX,
          y: 0,
          z: blockZ,
          chunkX: cx,
          chunkZ: cz,
          probability: 1.0,
          structureType: StructureType.buriedTreasure,
          biome: biome,
        ));
      }
    }
    hits.sort((a, b) {
      final da = (a.x - query.centerX) * (a.x - query.centerX) +
          (a.z - query.centerZ) * (a.z - query.centerZ);
      final db = (b.x - query.centerX) * (b.x - query.centerX) +
          (b.z - query.centerZ) * (b.z - query.centerZ);
      return da.compareTo(db);
    });
    for (final h in hits) {
      out.add(h);
      if (out.length >= query.maxResults) return;
    }
  }

  static int _chunkDistSq(ChunkPos p, int centerX, int centerZ) {
    final int bx = JavaPlacement.chunkToBlock(p.x) + 8;
    final int bz = JavaPlacement.chunkToBlock(p.z) + 8;
    return (bx - centerX) * (bx - centerX) + (bz - centerZ) * (bz - centerZ);
  }

  @override
  Future<List<OreLocation>> computeOres(
      OreQuery query, VersionStrategy strategy) async {
    final int seed = _seedOf(query.seed);
    final feature = strategy.oreFeatureFor(query.oreType);
    final veins = BedrockPlacement.veinsInRange(
      worldSeed: seed,
      centerX: query.centerX,
      centerZ: query.centerZ,
      radius: query.radius,
      feature: feature,
      featureIndex: query.oreType.index,
    );
    final out = <OreLocation>[];
    for (final v in veins) {
      out.add(OreLocation(
        x: v.x,
        y: v.y,
        z: v.z,
        chunkX: JavaPlacement.blockToChunk(v.x),
        chunkZ: JavaPlacement.blockToChunk(v.z),
        probability: 1.0,
        oreType: query.oreType,
        estimatedVeinSize: v.size,
      ));
      if (out.length >= query.maxResults) break;
    }
    return out;
  }

  @override
  Future<String> computeBiome(
      int seed, int x, int z, VersionStrategy strategy) async {
    return JavaBiome.computeBiome(
      worldSeed: Int64(seed),
      x: x,
      z: z,
      params: strategy.biomeParams,
    );
  }

  /// Parse a seed string for Bedrock. Bedrock seeds are 32-bit; a numeric seed
  /// is masked to 32 bits, otherwise the string's `hashCode` is used.
  static int _seedOf(String seed) {
    final trimmed = seed.trim();
    final parsed = int.tryParse(trimmed);
    if (parsed != null) return parsed & 0xFFFFFFFF;
    return trimmed.hashCode & 0xFFFFFFFF;
  }
}
