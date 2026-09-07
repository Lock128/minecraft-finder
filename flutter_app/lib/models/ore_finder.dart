import 'dart:math';
import 'bounded_top_results.dart';
import 'ore_location.dart';
import 'game_random.dart';
import 'java_random.dart';
import 'legacy_density_function.dart';
import 'noise.dart';
import 'biome_classifier.dart';

class OreFinder {
  late DensityFunction _densityFunction;
  LegacyDensityFunction? _legacyDensityFunction;

  /// Shared biome classifier (source of truth in biome_classifier.dart).
  /// StructureFinder uses the same class so biome assignments stay identical.
  final BiomeClassifier _biomeClassifier = BiomeClassifier();

  /// The active GameRandom instance for the current search.
  GameRandom? _gameRandom;

  /// Whether the current search is using legacy mode.
  bool _isLegacy = false;

  /// Cached vein noise instances per ore type to avoid re-creating permutation
  /// tables on every coordinate evaluation.
  final Map<int, PerlinNoise> _veinNoiseCache = {};

  OreFinder() {
    _densityFunction = DensityFunction(0);
  }

  /// Determine biome type based on coordinates.
  ///
  /// Delegates to the shared [BiomeClassifier] (source of truth in
  /// biome_classifier.dart) so ore and structure searches classify the same
  /// (x, z, seed) identically. See that class for the threshold map.
  String _getBiomeType(int x, int z, int worldSeed) {
    return _biomeClassifier.classify(x, z, worldSeed);
  }

  /// Test hook: expose the biome classification for a coordinate/seed so tests
  /// can assert OreFinder and StructureFinder stay in lockstep. Not used by
  /// production code.
  String biomeAt(int x, int z, int worldSeed) => _getBiomeType(x, z, worldSeed);

  /// Check if ore can spawn at given coordinates.
  ///
  /// When [legacy] is true, uses the pre-1.18 Y ranges from
  /// [LegacyDensityFunction.oreYRanges] and world height 0–256.
  bool _isValidOreLayer(int y, OreType oreType, String biome, {bool legacy = false}) {
    if (legacy) {
      // Legacy world height: 0–256
      if (y < 0 || y > 256) return false;
      final range = LegacyDensityFunction.oreYRanges[_oreTypeToString(oreType)];
      if (range == null) {
        // Netherite doesn't exist in legacy; use modern range
        if (oreType == OreType.netherite) return y >= 8 && y <= 22;
        return false;
      }
      return y >= range[0] && y <= range[1];
    }
    switch (oreType) {
      case OreType.diamond:
        return y >= -64 && y <= 16;
      case OreType.gold:
        if (biome == 'badlands') {
          return y >= -64 && y <= 256;
        } else if (biome == 'nether') {
          return y >= 10 && y <= 117;
        } else {
          return y >= -64 && y <= 32;
        }
      case OreType.netherite:
        return y >= 8 && y <= 22;
      case OreType.redstone:
        return y >= -64 && y <= 15;
      case OreType.iron:
        return y >= -64 && y <= 320;
      case OreType.coal:
        return y >= 0 && y <= 320;
      case OreType.lapis:
        return y >= -64 && y <= 64;
      case OreType.copper:
        return y >= -16 && y <= 112;
      case OreType.emerald:
        // Emerald only in mountains, but Y range is valid anywhere for the check
        return y >= -16 && y <= 320;
    }
  }

  /// Calculate ore probability using improved density functions
  double _calculateOreProbability(
      int x, int y, int z, OreType oreType, int worldSeed,
      {bool includeNether = false, GameRandom? rng}) {
    String biome = _getBiomeType(x, z, worldSeed);

    if ((includeNether && oreType == OreType.gold) ||
        oreType == OreType.netherite) {
      if (oreType == OreType.netherite) {
        biome = 'nether';
      } else {
        // Use edition-aware RNG for nether biome check
        GameRandom netherRandom;
        if (rng != null) {
          int chunkX = (x / 128).floor();
          int chunkZ = (z / 128).floor();
          int netherSeed = worldSeed ^ (chunkX * 341873128 + chunkZ * 132897987);
          rng.setSeed(netherSeed);
          netherRandom = rng;
        } else {
          netherRandom = MinecraftRandom.createChunkRandom(
              worldSeed, (x / 128).floor(), (z / 128).floor());
        }
        if (netherRandom.nextDouble() > 0.8) {
          biome = 'nether';
        }
      }
    }

    if (!_isValidOreLayer(y, oreType, biome, legacy: _isLegacy)) return 0.0;

    String oreTypeStr = _oreTypeToString(oreType);
    bool isNetherDimension = biome == 'nether';

    // Use legacy or modern density function based on current mode
    double baseDensity;
    if (_isLegacy && _legacyDensityFunction != null) {
      baseDensity = _legacyDensityFunction!.getOreDensity(
          x.toDouble(), y.toDouble(), z.toDouble(), oreTypeStr);
    } else {
      baseDensity = _densityFunction.getOreDensity(
          x.toDouble(), y.toDouble(), z.toDouble(), oreTypeStr,
          isNether: isNetherDimension);
    }

    if (baseDensity <= 0.0) return 0.0;

    double biomeModifier = _getBiomeModifier(oreType, biome, y);
    double probability = baseDensity * biomeModifier;

    // Use the provided GameRandom (edition-aware) or fall back to JavaRandom
    GameRandom oreRandom;
    if (rng != null) {
      int oreSalt = oreTypeStr.hashCode;
      int oreSeed =
          worldSeed ^ (x * 341873128 + z * 132897987 + y * 268582165 + oreSalt);
      rng.setSeed(oreSeed);
      oreRandom = rng;
    } else {
      oreRandom =
          MinecraftRandom.createOreRandom(worldSeed, x, y, z, oreTypeStr);
    }
    double randomFactor = 0.7 + (oreRandom.nextDouble() * 0.6);
    probability *= randomFactor;

    double veinFactor = _calculateVeinFactor(x, y, z, oreType, worldSeed);
    probability *= veinFactor;

    return min(probability, 1.0);
  }

  /// Biome-specific modifier for ore generation
  double _getBiomeModifier(OreType oreType, String biome, int y) {
    switch (oreType) {
      case OreType.gold:
        if (biome == 'badlands' && y >= 32 && y <= 256) {
          return 3.0; // Badlands extra uniform placement
        } else if (biome == 'nether') {
          return 1.8;
        }
        return 1.0;
      case OreType.iron:
        if (biome == 'mountains' && y >= 128) return 1.5;
        return 1.0;
      case OreType.coal:
        if (biome == 'mountains') return 1.2;
        return 1.0;
      case OreType.emerald:
        // Emerald ONLY spawns in mountain biomes
        if (biome == 'mountains') return 1.0;
        return 0.0; // Zero elsewhere
      case OreType.copper:
        // Copper generates in larger veins in dripstone caves, slight boost for variety
        return 1.0;
      default:
        return 1.0;
    }
  }

  /// Calculate vein clustering factor (cached noise instances)
  double _calculateVeinFactor(
      int x, int y, int z, OreType oreType, int worldSeed) {
    double scale = 0.05;
    switch (oreType) {
      case OreType.diamond:
        scale = 0.03;
        break;
      case OreType.netherite:
        scale = 0.02;
        break;
      case OreType.coal:
        scale = 0.08;
        break;
      case OreType.iron:
        scale = 0.06;
        break;
      case OreType.lapis:
        scale = 0.04;
        break;
      case OreType.copper:
        scale = 0.07; // Large veins
        break;
      case OreType.emerald:
        scale = 0.03; // Small, scattered
        break;
      default:
        scale = 0.05;
    }

    int cacheKey = worldSeed + oreType.index;
    PerlinNoise veinNoise = _getOrCreateNoise(cacheKey, rng: _gameRandom);

    double veinValue = veinNoise.octaveNoise3D(
        x * scale, y * scale * 2, z * scale, 3, 0.5, 1.0);

    // Map Perlin [-1, 1] → [0, 1] so that low-density noise areas genuinely
    // suppress ore probability rather than always contributing at least 0.5.
    return (veinValue + 1.0) * 0.5;
  }

  /// Get or create a cached PerlinNoise instance for the given seed.
  PerlinNoise _getOrCreateNoise(int seed, {GameRandom? rng}) {
    return _veinNoiseCache.putIfAbsent(seed, () => PerlinNoise(seed, rng: rng));
  }

  String _oreTypeToString(OreType oreType) {
    switch (oreType) {
      case OreType.diamond:
        return 'diamond';
      case OreType.gold:
        return 'gold';
      case OreType.netherite:
        return 'netherite';
      case OreType.redstone:
        return 'redstone';
      case OreType.iron:
        return 'iron';
      case OreType.coal:
        return 'coal';
      case OreType.lapis:
        return 'lapis';
      case OreType.copper:
        return 'copper';
      case OreType.emerald:
        return 'emerald';
    }
  }

  /// Find ore locations in a given area.
  ///
  /// At most [maxResults] locations (the highest-probability ones) are ever
  /// retained in memory, so peak memory stays bounded regardless of [radius].
  Future<List<OreLocation>> findOres({
    required String seed,
    required int centerX,
    required int centerY,
    required int centerZ,
    required int radius,
    required OreType oreType,
    bool includeNether = false,
    double minProbability = 0.5,
    MinecraftEdition edition = MinecraftEdition.java,
    VersionEra versionEra = VersionEra.modern,
    int maxResults = 500,
    void Function(int)? onTotalFound,
  }) async {
    int worldSeed = MinecraftRandom.stringToSeed(seed);

    // Create edition-aware RNG
    GameRandom rng = GameRandom.forEdition(edition, worldSeed);
    _gameRandom = rng;
    _isLegacy = versionEra == VersionEra.legacy;

    // Select density function based on version era
    if (_isLegacy) {
      _legacyDensityFunction = LegacyDensityFunction(worldSeed);
      _densityFunction = DensityFunction(worldSeed, rng: rng);
    } else {
      _legacyDensityFunction = null;
      _densityFunction = DensityFunction(worldSeed, rng: rng);
    }
    _veinNoiseCache.clear();

    // Adjust minimum probability based on ore rarity
    switch (oreType) {
      case OreType.netherite:
        minProbability = 0.08;
        break;
      case OreType.diamond:
        minProbability = 0.25;
        break;
      case OreType.lapis:
        minProbability = 0.28;
        break;
      case OreType.emerald:
        minProbability = 0.15; // Rare, mountain-only
        break;
      case OreType.gold:
        minProbability = 0.3;
        break;
      case OreType.redstone:
        minProbability = 0.35;
        break;
      case OreType.iron:
        minProbability = 0.4;
        break;
      case OreType.copper:
        minProbability = 0.4; // Common
        break;
      case OreType.coal:
        minProbability = 0.45;
        break;
    }

    final locations =
        BoundedTopResults<OreLocation>(maxResults, (o) => o.probability);
    int step = _getOptimalStepSize(oreType, radius);

    for (int x = centerX - radius; x <= centerX + radius; x += step) {
      for (int z = centerZ - radius; z <= centerZ + radius; z += step) {
        String biome = _getBiomeType(x, z, worldSeed);

        var yRange = _getYRange(oreType, biome, legacy: _isLegacy);
        int yMin = yRange['min']!;
        int yMax = yRange['max']!;
        int yStep = yRange['step']!;

        for (int y = yMin; y <= yMax; y += yStep) {
          // Reuse the RNG instance created at the start of findOres
          // instead of allocating a new one per coordinate
          double probability = _calculateOreProbability(
              x, y, z, oreType, worldSeed,
              includeNether: includeNether,
              rng: rng);

          if (probability >= minProbability) {
            locations.add(OreLocation(
              x: x,
              y: y,
              z: z,
              chunkX: (x / 16).floor(),
              chunkZ: (z / 16).floor(),
              probability: (probability * 100).round() / 100,
              oreType: oreType,
              biome: biome,
            ));
          }
        }
      }

      if (x % (step * 4) == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    // Report the total number of qualifying candidates (before the display
    // cap) so callers can show an accurate "top N of X" label.
    onTotalFound?.call(locations.totalOffered);

    // Already sorted descending by probability inside the bounded collector.
    return locations.toList();
  }

  /// Get optimal step size based on ore type and search radius
  int _getOptimalStepSize(OreType oreType, int radius) {
    switch (oreType) {
      case OreType.netherite:
        return radius < 100 ? 4 : 8;
      case OreType.diamond:
        return radius < 200 ? 6 : 10;
      case OreType.lapis:
        return radius < 200 ? 6 : 10;
      case OreType.emerald:
        return radius < 200 ? 6 : 10; // Rare, similar to diamond
      case OreType.gold:
      case OreType.redstone:
        return radius < 300 ? 8 : 12;
      case OreType.copper:
        return radius < 400 ? 10 : 16; // Common, large veins
      case OreType.iron:
        return radius < 400 ? 10 : 16;
      case OreType.coal:
        return radius < 500 ? 12 : 20;
    }
  }

  /// Get Y range and step size for ore type and biome.
  ///
  /// When [legacy] is true, returns the pre-1.18 Y ranges clamped to
  /// world height 0–256.
  Map<String, int> _getYRange(OreType oreType, String biome, {bool legacy = false}) {
    if (legacy) {
      return _getLegacyYRange(oreType, biome);
    }
    switch (oreType) {
      case OreType.diamond:
        return {'min': -64, 'max': 16, 'step': 2};
      case OreType.gold:
        if (biome == 'badlands') {
          return {'min': -64, 'max': 256, 'step': 6};
        } else if (biome == 'nether') {
          return {'min': 10, 'max': 117, 'step': 4};
        } else {
          return {'min': -64, 'max': 32, 'step': 3};
        }
      case OreType.netherite:
        return {'min': 8, 'max': 22, 'step': 1};
      case OreType.redstone:
        return {'min': -64, 'max': 15, 'step': 2};
      case OreType.iron:
        return {'min': -64, 'max': 320, 'step': 4};
      case OreType.coal:
        return {'min': 0, 'max': 320, 'step': 6};
      case OreType.lapis:
        return {'min': -64, 'max': 64, 'step': 2};
      case OreType.copper:
        return {'min': -16, 'max': 112, 'step': 4};
      case OreType.emerald:
        return {'min': -16, 'max': 320, 'step': 6};
    }
  }

  /// Get legacy (pre-1.18) Y range and step size for ore type.
  ///
  /// Uses [LegacyDensityFunction.oreYRanges] for known ores and
  /// falls back to modern ranges for netherite (which didn't exist
  /// in pre-1.18 but is still searchable).
  Map<String, int> _getLegacyYRange(OreType oreType, String biome) {
    final oreStr = _oreTypeToString(oreType);
    final range = LegacyDensityFunction.oreYRanges[oreStr];
    if (range != null) {
      int span = range[1] - range[0];
      int step = max(1, span ~/ 20); // reasonable step
      return {'min': range[0], 'max': range[1], 'step': step};
    }
    // Netherite: same range in both eras
    if (oreType == OreType.netherite) {
      return {'min': 8, 'max': 22, 'step': 1};
    }
    return {'min': 0, 'max': 256, 'step': 4};
  }

  /// Comprehensive search for all netherite (Ancient Debris).
  ///
  /// At most [maxResults] highest-probability locations are retained, keeping
  /// peak memory bounded on large-radius searches.
  Future<List<OreLocation>> findAllNetherite({
    required String seed,
    required int centerX,
    required int centerZ,
    int searchRadius = 1000,
    MinecraftEdition edition = MinecraftEdition.java,
    VersionEra versionEra = VersionEra.modern,
    int maxResults = 200,
    void Function(int)? onTotalFound,
  }) async {
    int worldSeed = MinecraftRandom.stringToSeed(seed);

    // Create edition-aware RNG
    GameRandom rng = GameRandom.forEdition(edition, worldSeed);
    _gameRandom = rng;
    _isLegacy = versionEra == VersionEra.legacy;

    if (_isLegacy) {
      _legacyDensityFunction = LegacyDensityFunction(worldSeed);
      _densityFunction = DensityFunction(worldSeed, rng: rng);
    } else {
      _legacyDensityFunction = null;
      _densityFunction = DensityFunction(worldSeed, rng: rng);
    }
    _veinNoiseCache.clear();

    final locations =
        BoundedTopResults<OreLocation>(maxResults, (o) => o.probability);
    // Ancient Debris veins are only 1–3 blocks wide; step=16 skips most of
    // them. Use step=4 (matching _getOptimalStepSize for netherite) so that
    // every vein falls within one step of a sampled point.
    const int step = 4;
    int processedColumns = 0;

    for (int x = centerX - searchRadius;
        x <= centerX + searchRadius;
        x += step) {
      for (int z = centerZ - searchRadius;
          z <= centerZ + searchRadius;
          z += step) {
        // Scan every Y in the ancient-debris range rather than a sparse list,
        // since the range is only 15 levels (8–22) and step=1 is cheap here.
        for (int y = 8; y <= 22; y++) {
          // Reuse the RNG instance created at the start of findAllNetherite
          double probability =
              _calculateOreProbability(x, y, z, OreType.netherite, worldSeed,
                  rng: rng);

          if (probability >= 0.05) {
            locations.add(OreLocation(
              x: x,
              y: y,
              z: z,
              chunkX: (x / 16).floor(),
              chunkZ: (z / 16).floor(),
              probability: (probability * 100).round() / 100,
              oreType: OreType.netherite,
              biome: 'nether',
            ));
          }
        }

        processedColumns++;
        // Yield every 200 columns (~800 ms worth at 4-block step) so the UI
        // stays responsive during large searches.
        if (processedColumns % 200 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }
    }

    onTotalFound?.call(locations.totalOffered);

    // Already sorted descending and capped by the bounded collector.
    return locations.toList();
  }

  /// Get netherite statistics for a seed
  Future<Map<String, dynamic>> getNetheriteStats({
    required String seed,
    int sampleRadius = 1000,
    MinecraftEdition edition = MinecraftEdition.java,
    VersionEra versionEra = VersionEra.modern,
  }) async {
    int worldSeed = MinecraftRandom.stringToSeed(seed);

    // Create edition-aware RNG
    GameRandom rng = GameRandom.forEdition(edition, worldSeed);
    _gameRandom = rng;
    _isLegacy = versionEra == VersionEra.legacy;

    if (_isLegacy) {
      _legacyDensityFunction = LegacyDensityFunction(worldSeed);
      _densityFunction = DensityFunction(worldSeed, rng: rng);
    } else {
      _legacyDensityFunction = null;
      _densityFunction = DensityFunction(worldSeed, rng: rng);
    }
    _veinNoiseCache.clear();

    int totalLocations = 0;
    double avgProbability = 0.0;
    List<double> probabilities = [];

    for (int x = -sampleRadius; x <= sampleRadius; x += 24) {
      for (int z = -sampleRadius; z <= sampleRadius; z += 24) {
        for (int y = 8; y <= 22; y++) {
          // Reuse the RNG instance created at the start of getNetheriteStats
          double probability =
              _calculateOreProbability(x, y, z, OreType.netherite, worldSeed,
                  rng: rng);
          if (probability >= 0.05) {
            totalLocations++;
            probabilities.add(probability);
          }
        }
      }
    }

    if (probabilities.isNotEmpty) {
      avgProbability =
          probabilities.reduce((a, b) => a + b) / probabilities.length;
    }

    return {
      'totalLocations': totalLocations,
      'averageProbability': avgProbability,
      'maxProbability': probabilities.isNotEmpty
          ? probabilities.reduce((a, b) => a > b ? a : b)
          : 0.0,
      'searchArea': '${sampleRadius * 2}x${sampleRadius * 2} blocks',
      'algorithmVersion': 'v3.0 - Accurate 1.18+ distributions',
    };
  }
}
