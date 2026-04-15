import 'dart:math';
import 'ore_location.dart';
import 'game_random.dart';
import 'java_random.dart';
import 'legacy_density_function.dart';
import 'noise.dart';

class OreFinder {
  late DensityFunction _densityFunction;
  LegacyDensityFunction? _legacyDensityFunction;

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
  /// Uses multi-noise sampling (temperature + humidity) for spatially coherent
  /// biome regions instead of a single random value per 64-block cell.
  String _getBiomeType(int x, int z, int worldSeed) {
    PerlinNoise tempNoise = _getOrCreateNoise(worldSeed + 1000, rng: _gameRandom);
    PerlinNoise humidNoise = _getOrCreateNoise(worldSeed + 2000, rng: _gameRandom);

    double scale = 0.005; // ~200 block biome regions
    double temperature =
        tempNoise.octaveNoise3D(x * scale, 0, z * scale, 3, 0.5, 1.0);
    double humidity =
        humidNoise.octaveNoise3D(x * scale, 0, z * scale, 3, 0.5, 1.0);

    if (temperature < -0.5) {
      return humidity < 0 ? 'taiga' : 'swamp';
    } else if (temperature < -0.1) {
      if (humidity < -0.3) return 'mountains';
      return humidity < 0.3 ? 'forest' : 'jungle';
    } else if (temperature < 0.3) {
      if (humidity < -0.3) return 'plains';
      return humidity < 0.3 ? 'savanna' : 'ocean';
    } else {
      return humidity < 0 ? 'desert' : 'badlands';
    }
  }

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
        return y >= 0 && y <= 192;
      case OreType.lapis:
        return y >= -64 && y <= 64;
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

    // Use legacy or modern density function based on current mode
    double baseDensity;
    if (_isLegacy && _legacyDensityFunction != null) {
      baseDensity = _legacyDensityFunction!.getOreDensity(
          x.toDouble(), y.toDouble(), z.toDouble(), oreTypeStr);
    } else {
      baseDensity = _densityFunction.getOreDensity(
          x.toDouble(), y.toDouble(), z.toDouble(), oreTypeStr);
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
      default:
        scale = 0.05;
    }

    int cacheKey = worldSeed + oreType.index;
    PerlinNoise veinNoise = _getOrCreateNoise(cacheKey, rng: _gameRandom);

    double veinValue = veinNoise.octaveNoise3D(
        x * scale, y * scale * 2, z * scale, 3, 0.5, 1.0);

    return 0.5 + (veinValue + 1.0) * 0.5;
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
    }
  }

  /// Find ore locations in a given area
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
      case OreType.gold:
        minProbability = 0.3;
        break;
      case OreType.redstone:
        minProbability = 0.35;
        break;
      case OreType.iron:
        minProbability = 0.4;
        break;
      case OreType.coal:
        minProbability = 0.45;
        break;
    }

    List<OreLocation> locations = [];
    int step = _getOptimalStepSize(oreType, radius);

    for (int x = centerX - radius; x <= centerX + radius; x += step) {
      for (int z = centerZ - radius; z <= centerZ + radius; z += step) {
        String biome = _getBiomeType(x, z, worldSeed);

        var yRange = _getYRange(oreType, biome, legacy: _isLegacy);
        int yMin = yRange['min']!;
        int yMax = yRange['max']!;
        int yStep = yRange['step']!;

        for (int y = yMin; y <= yMax; y += yStep) {
          double probability = _calculateOreProbability(
              x, y, z, oreType, worldSeed,
              includeNether: includeNether,
              rng: GameRandom.forEdition(edition, worldSeed));

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

    locations.sort((a, b) => b.probability.compareTo(a.probability));
    return locations;
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
      case OreType.gold:
      case OreType.redstone:
        return radius < 300 ? 8 : 12;
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
        return {'min': 0, 'max': 192, 'step': 6};
      case OreType.lapis:
        return {'min': -64, 'max': 64, 'step': 2};
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

  /// Comprehensive search for all netherite (Ancient Debris)
  Future<List<OreLocation>> findAllNetherite({
    required String seed,
    required int centerX,
    required int centerZ,
    int searchRadius = 1000,
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

    List<OreLocation> locations = [];
    int step = 16;
    int processedBlocks = 0;

    for (int x = centerX - searchRadius;
        x <= centerX + searchRadius;
        x += step) {
      for (int z = centerZ - searchRadius;
          z <= centerZ + searchRadius;
          z += step) {
        // Priority Y levels for ancient debris (peak at Y=15)
        List<int> priorityYLevels = [15, 13, 17, 11, 19, 9, 21];

        for (int y in priorityYLevels) {
          if (y >= 8 && y <= 22) {
            double probability =
                _calculateOreProbability(x, y, z, OreType.netherite, worldSeed,
                    rng: GameRandom.forEdition(edition, worldSeed));

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
        }

        processedBlocks++;
        if (processedBlocks % 50 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }
    }

    locations.sort((a, b) => b.probability.compareTo(a.probability));
    return locations.take(200).toList();
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
          double probability =
              _calculateOreProbability(x, y, z, OreType.netherite, worldSeed,
                  rng: GameRandom.forEdition(edition, worldSeed));
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
