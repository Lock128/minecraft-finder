import 'package:fixnum/fixnum.dart';

import '../game_random.dart';
import '../ore_location.dart';
import '../structure_location.dart';
import 'java_biome.dart';
import 'java_ore.dart';
import 'java_placement.dart';
import 'version_strategy.dart';
import 'worldgen_engine.dart';

/// Target platform abstraction used for backend selection.
///
/// Injected rather than read from `dart:io`/global state so `selectBackend`
/// stays a pure, testable function and so web builds never pull `dart:ffi`
/// into the bundle.
enum Platform {
  web,
  android,
  ios,
  macos,
  windows,
  linux,
  fuchsia,
}

/// Internal contract both accurate backends implement. The only difference
/// between them is *how* they execute a [VersionStrategy]: native C via
/// `dart:ffi` vs pure Int64 Dart.
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
abstract interface class WorldGenBackend {
  /// Whether this backend can run [strategy] for the given query.
  bool canRun(VersionStrategy strategy);

  Future<List<StructureLocation>> computeStructures(
    StructureQuery query,
    VersionStrategy strategy,
  );

  Future<List<OreLocation>> computeOres(
    OreQuery query,
    VersionStrategy strategy,
  );

  /// Compute the biome id at a world coordinate for the given seed.
  Future<String> computeBiome(
    int seed,
    int x,
    int z,
    VersionStrategy strategy,
  );
}

/// Pure selector: web -> [DartWebBackend], everything else ->
/// [NativeFfiBackend]. Platform detection is injected via [p].
///
/// When a [bedrockBackend] is supplied, the chosen Java backend is wrapped in a
/// [CompositeBackend] so a single returned [WorldGenBackend] can run both the
/// Java and the Bedrock track (the composite dispatches by the strategy's
/// edition). The Bedrock path reuses the web-safe MT19937 [BedrockRandom] on
/// every platform, so the same instance serves web and native.
WorldGenBackend selectBackend(
  Platform p, {
  required WorldGenBackend dartWebBackend,
  required WorldGenBackend nativeFfiBackend,
  WorldGenBackend? bedrockBackend,
}) {
  final WorldGenBackend javaBackend =
      p == Platform.web ? dartWebBackend : nativeFfiBackend;
  if (bedrockBackend == null) return javaBackend;
  return CompositeBackend(
    javaBackend: javaBackend,
    bedrockBackend: bedrockBackend,
  );
}

/// Routes a query to the backend that can run the request's edition. The Java
/// backend handles [MinecraftEdition.java] strategies; the Bedrock backend
/// handles [MinecraftEdition.bedrock] strategies. [canRun] is the union of the
/// two so the [AccurateEngine] only degrades when neither can run.
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
class CompositeBackend implements WorldGenBackend {
  const CompositeBackend({
    required this.javaBackend,
    required this.bedrockBackend,
  });

  final WorldGenBackend javaBackend;
  final WorldGenBackend bedrockBackend;

  WorldGenBackend _pick(VersionStrategy strategy) =>
      strategy.edition == MinecraftEdition.bedrock
          ? bedrockBackend
          : javaBackend;

  @override
  bool canRun(VersionStrategy strategy) => _pick(strategy).canRun(strategy);

  @override
  Future<List<StructureLocation>> computeStructures(
          StructureQuery query, VersionStrategy strategy) =>
      _pick(strategy).computeStructures(query, strategy);

  @override
  Future<List<OreLocation>> computeOres(
          OreQuery query, VersionStrategy strategy) =>
      _pick(strategy).computeOres(query, strategy);

  @override
  Future<String> computeBiome(
          int seed, int x, int z, VersionStrategy strategy) =>
      _pick(strategy).computeBiome(seed, x, z, strategy);
}

/// Function type for the backend selector so it can be injected into the
/// [AccurateEngine].
typedef BackendSelector = WorldGenBackend Function(Platform platform);

/// Pure-Dart web backend. Reproduces the real Minecraft Java placement
/// algorithms (region-grid structures, stronghold rings, buried treasure,
/// multi-noise climate biomes, and `count x tries` ore feature loops) with
/// [JavaRandomInt64] so every bit of 64-bit arithmetic survives on the web (JS)
/// target. The native backend reproduces the same math in C, and the two paths
/// are held in lock-step by the cross-path parity properties.
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
class DartWebBackend implements WorldGenBackend {
  const DartWebBackend();

  /// Buried-treasure salt (vanilla `minecraft:buried_treasures`).
  static const int _buriedTreasureSalt = 10387320;
  static const double _buriedTreasureProbability = 0.01;

  /// Per-structure allowed biome sets used for biome gating (Req 8.2). A null
  /// entry means the structure is not biome-gated by this backend.
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

  /// The web backend can run any Java strategy (the Int64 math is version
  /// agnostic; version-specific behaviour comes from the strategy tables).
  @override
  bool canRun(VersionStrategy strategy) =>
      strategy.edition == MinecraftEdition.java;

  @override
  Future<List<StructureLocation>> computeStructures(
      StructureQuery query, VersionStrategy strategy) async {
    final Int64 seed = _seedOf(query.seed);
    final results = <StructureLocation>[];

    for (final type in query.structureTypes) {
      switch (type) {
        case StructureType.stronghold:
          _addStrongholds(seed, query, strategy, results);
          break;
        case StructureType.buriedTreasure:
          _addBuriedTreasure(seed, query, strategy, results);
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
    Int64 seed,
    StructureType type,
    StructureQuery query,
    VersionStrategy strategy,
    List<StructureLocation> out,
  ) {
    final placement = strategy.placementFor(type);
    final chunks = JavaPlacement.regionStructuresInRange(
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
        worldSeed: seed,
        x: blockX,
        z: blockZ,
        params: strategy.biomeParams,
      );
      // Biome gating (Req 8.2): emit iff the computed biome is allowed.
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
    Int64 seed,
    StructureQuery query,
    VersionStrategy strategy,
    List<StructureLocation> out,
  ) {
    final chunks = JavaPlacement.strongholdChunks(
      worldSeed: seed,
      config: strategy.strongholdRings,
    );
    final sorted = [...chunks];
    sorted.sort((a, b) {
      int da = _chunkDistSq(a, query.centerX, query.centerZ);
      int db = _chunkDistSq(b, query.centerX, query.centerZ);
      return da.compareTo(db);
    });
    for (final c in sorted) {
      final int blockX = JavaPlacement.chunkToBlock(c.x) + 8;
      final int blockZ = JavaPlacement.chunkToBlock(c.z) + 8;
      if ((blockX - query.centerX).abs() > query.radius) continue;
      if ((blockZ - query.centerZ).abs() > query.radius) continue;
      final biome = JavaBiome.computeBiome(
        worldSeed: seed,
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
    Int64 seed,
    StructureQuery query,
    VersionStrategy strategy,
    List<StructureLocation> out,
  ) {
    final int minChunkX = JavaPlacement.blockToChunk(query.centerX - query.radius);
    final int maxChunkX = JavaPlacement.blockToChunk(query.centerX + query.radius);
    final int minChunkZ = JavaPlacement.blockToChunk(query.centerZ - query.radius);
    final int maxChunkZ = JavaPlacement.blockToChunk(query.centerZ + query.radius);
    final hits = <StructureLocation>[];
    for (int cx = minChunkX; cx <= maxChunkX; cx++) {
      for (int cz = minChunkZ; cz <= maxChunkZ; cz++) {
        final present = JavaPlacement.buriedTreasureInChunk(
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
          worldSeed: seed,
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
    final Int64 seed = _seedOf(query.seed);
    final feature = strategy.oreFeatureFor(query.oreType);
    final veins = JavaOre.veinsInRange(
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

  /// Parse a seed string the same way the legacy finders / native backend do:
  /// a numeric seed is used directly; otherwise the string's `hashCode`.
  ///
  /// Parsing goes through [Int64] (not `int.tryParse`) so a full 64-bit decimal
  /// seed survives on the web (JS) target, where a Dart `int` would silently
  /// truncate above 2^53.
  static Int64 _seedOf(String seed) {
    final trimmed = seed.trim();
    try {
      return Int64.parseInt(trimmed);
    } on FormatException {
      return Int64(trimmed.hashCode);
    }
  }
}

// The native FFI backend now lives in `native_ffi_backend.dart` (with a
// conditional import so no `dart:ffi` enters the web bundle). `selectBackend`
// takes it as an injected argument, keeping this file free of `dart:ffi`.
