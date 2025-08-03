import 'dart:math';
import 'ore_location.dart';
import 'java_random.dart';
import 'noise.dart';

class OreFinder {
  late DensityFunction _densityFunction;

  OreFinder() {
    // Initialize with a default seed, will be updated per search
    _densityFunction = DensityFunction(0);
  }

  /// Determine biome type based on coordinates (improved biome generation)
  String _getBiomeType(int x, int z, int worldSeed) {
    JavaRandom biomeRandom = MinecraftRandom.createChunkRandom(
        worldSeed, (x / 64).floor(), (z / 64).floor());

    double biomeValue = biomeRandom.nextDouble();

    // More realistic biome distribution
    if (biomeValue < 0.05) return 'badlands';
    if (biomeValue < 0.15) return 'desert';
    if (biomeValue < 0.25) return 'mountains';
    if (biomeValue < 0.35) return 'forest';
    if (biomeValue < 0.45) return 'taiga';
    if (biomeValue < 0.55) return 'swamp';
    if (biomeValue < 0.65) return 'savanna';
    if (biomeValue < 0.75) return 'jungle';
    if (biomeValue < 0.85) return 'ocean';
    return 'plains';
  }

  /// Check if ore can spawn at given coordinates (more accurate ranges)
  bool _isValidOreLayer(int y, OreType oreType, String biome) {
    switch (oreType) {
      case OreType.diamond:
        return y >= -64 && y <= 16;
      case OreType.gold:
        if (biome == 'badlands') {
          return y >= -64 && y <= 256; // Badlands have gold at all levels
        } else if (biome == 'nether') {
          return y >= 10 && y <= 117;
        } else {
          return y >= -64 && y <= 32; // Normal overworld
        }
      case OreType.netherite:
        return y >= 8 && y <= 22; // Ancient debris in nether only
      case OreType.redstone:
        return y >= -64 && y <= 15;
      case OreType.iron:
        return y >= -64 && y <= 256;
      case OreType.coal:
        return y >= 0 && y <= 256;
    }
  }

  /// Calculate ore probability using improved density functions and Java-compatible RNG
  double _calculateOreProbability(
      int x, int y, int z, OreType oreType, int worldSeed,
      {bool includeNether = false}) {
    String biome = _getBiomeType(x, z, worldSeed);

    // Handle nether inclusion or netherite search
    if ((includeNether && oreType == OreType.gold) ||
        oreType == OreType.netherite) {
      if (oreType == OreType.netherite) {
        biome = 'nether';
      } else {
        // For gold with nether inclusion, use Java-compatible random
        JavaRandom netherRandom = MinecraftRandom.createChunkRandom(
            worldSeed, (x / 128).floor(), (z / 128).floor());
        if (netherRandom.nextDouble() > 0.8) {
          biome = 'nether';
        }
      }
    }

    if (!_isValidOreLayer(y, oreType, biome)) return 0.0;

    // Use density function for base probability
    String oreTypeStr = _oreTypeToString(oreType);
    double baseDensity = _densityFunction.getOreDensity(
        x.toDouble(), y.toDouble(), z.toDouble(), oreTypeStr);

    if (baseDensity <= 0.0) return 0.0;

    // Apply biome-specific modifiers
    double biomeModifier = _getBiomeModifier(oreType, biome, y);
    double probability = baseDensity * biomeModifier;

    // Add Java-compatible randomness for ore placement
    JavaRandom oreRandom =
        MinecraftRandom.createOreRandom(worldSeed, x, y, z, oreTypeStr);
    double randomFactor =
        0.7 + (oreRandom.nextDouble() * 0.6); // 0.7 to 1.3 multiplier

    probability *= randomFactor;

    // Simulate ore vein clustering
    double veinFactor = _calculateVeinFactor(x, y, z, oreType, worldSeed);
    probability *= veinFactor;

    return min(probability, 1.0);
  }

  /// Get biome-specific modifier for ore generation
  double _getBiomeModifier(OreType oreType, String biome, int y) {
    switch (oreType) {
      case OreType.gold:
        if (biome == 'badlands' && y >= 32 && y <= 80) {
          return 2.5; // Badlands have much more gold at surface levels
        } else if (biome == 'nether') {
          return 1.8; // Nether gold is more common
        }
        return 1.0;
      case OreType.iron:
        if (biome == 'mountains' && y >= 128) {
          return 1.5; // More iron in mountains
        }
        return 1.0;
      case OreType.coal:
        if (biome == 'mountains') {
          return 1.2; // Slightly more coal in mountains
        }
        return 1.0;
      default:
        return 1.0;
    }
  }

  /// Calculate vein clustering factor
  double _calculateVeinFactor(
      int x, int y, int z, OreType oreType, int worldSeed) {
    // Use different scales for different ore types
    double scale = 0.05;
    switch (oreType) {
      case OreType.diamond:
        scale = 0.03; // Smaller, rarer veins
        break;
      case OreType.netherite:
        scale = 0.02; // Very small, rare veins
        break;
      case OreType.coal:
        scale = 0.08; // Larger, more common veins
        break;
      case OreType.iron:
        scale = 0.06; // Medium-sized veins
        break;
      default:
        scale = 0.05;
    }

    // Create vein-like patterns using multiple noise octaves
    PerlinNoise veinNoise = PerlinNoise(worldSeed + oreType.index);
    double veinValue = veinNoise.octaveNoise3D(
        x * scale, y * scale * 2, z * scale, 3, 0.5, 1.0);

    // Convert to 0.5 to 1.5 range for multiplicative factor
    return 0.5 + (veinValue + 1.0) * 0.5;
  }

  /// Convert ore type to string for density function
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
    }
  }

  /// Find ore locations in a given area using improved algorithms
  Future<List<OreLocation>> findOres({
    required String seed,
    required int centerX,
    required int centerY,
    required int centerZ,
    required int radius,
    required OreType oreType,
    bool includeNether = false,
    double minProbability = 0.5,
  }) async {
    // Use Java-compatible seed conversion
    int worldSeed = MinecraftRandom.stringToSeed(seed);

    // Initialize density function with world seed
    _densityFunction = DensityFunction(worldSeed);

    // Adjust minimum probability based on ore rarity
    switch (oreType) {
      case OreType.netherite:
        minProbability = 0.08; // Very rare
        break;
      case OreType.diamond:
        minProbability = 0.25; // Rare
        break;
      case OreType.gold:
        minProbability = 0.3; // Uncommon
        break;
      case OreType.redstone:
        minProbability = 0.35; // Uncommon
        break;
      case OreType.iron:
        minProbability = 0.4; // Common
        break;
      case OreType.coal:
        minProbability = 0.45; // Very common
        break;
    }

    List<OreLocation> locations = [];
    // Adaptive step size based on ore rarity and search area
    int step = _getOptimalStepSize(oreType, radius);

    for (int x = centerX - radius; x <= centerX + radius; x += step) {
      for (int z = centerZ - radius; z <= centerZ + radius; z += step) {
        String biome = _getBiomeType(x, z, worldSeed);

        // Determine Y range and step based on ore type
        var yRange = _getYRange(oreType, biome);
        int yMin = yRange['min']!;
        int yMax = yRange['max']!;
        int yStep = yRange['step']!;

        for (int y = yMin; y <= yMax; y += yStep) {
          double probability = _calculateOreProbability(
              x, y, z, oreType, worldSeed,
              includeNether: includeNether);

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

      // Yield control back to the UI thread periodically
      if (x % (step * 4) == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    // Sort by probability (highest first)
    locations.sort((a, b) => b.probability.compareTo(a.probability));

    return locations;
  }

  /// Get optimal step size based on ore type and search radius
  int _getOptimalStepSize(OreType oreType, int radius) {
    // Smaller steps for rarer ores and smaller search areas
    switch (oreType) {
      case OreType.netherite:
        return radius < 100 ? 4 : 8; // Very fine search for netherite
      case OreType.diamond:
        return radius < 200 ? 6 : 10;
      case OreType.gold:
      case OreType.redstone:
        return radius < 300 ? 8 : 12;
      case OreType.iron:
        return radius < 400 ? 10 : 16;
      case OreType.coal:
        return radius < 500 ? 12 : 20; // Coarser search for common coal
    }
  }

  /// Get Y range and step size for ore type and biome
  Map<String, int> _getYRange(OreType oreType, String biome) {
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
        return {
          'min': 8,
          'max': 22,
          'step': 1
        }; // Very precise for rare netherite
      case OreType.redstone:
        return {'min': -64, 'max': 15, 'step': 2};
      case OreType.iron:
        return {'min': -64, 'max': 256, 'step': 4};
      case OreType.coal:
        return {'min': 0, 'max': 256, 'step': 6};
    }
  }

  /// Comprehensive search for all netherite (Ancient Debris) using improved algorithms
  Future<List<OreLocation>> findAllNetherite({
    required String seed,
    required int centerX,
    required int centerZ,
    int searchRadius = 1000, // Reduced default radius
  }) async {
    // Use Java-compatible seed conversion
    int worldSeed = MinecraftRandom.stringToSeed(seed);

    // Initialize density function with world seed
    _densityFunction = DensityFunction(worldSeed);

    List<OreLocation> locations = [];

    // Optimized search parameters
    int step = 16; // Larger step for faster search
    int yStep = 2; // Skip some Y levels for speed
    int processedBlocks = 0;
    int totalBlocks = ((searchRadius * 2) ~/ step) *
        ((searchRadius * 2) ~/ step) *
        ((22 - 8) ~/ yStep);

    for (int x = centerX - searchRadius;
        x <= centerX + searchRadius;
        x += step) {
      for (int z = centerZ - searchRadius;
          z <= centerZ + searchRadius;
          z += step) {
        // Search key Y levels for ancient debris (most common at Y=15)
        List<int> priorityYLevels = [15, 13, 17, 11, 19, 9, 21];

        for (int y in priorityYLevels) {
          if (y >= 8 && y <= 22) {
            double probability =
                _calculateOreProbability(x, y, z, OreType.netherite, worldSeed);

            // Use higher threshold for faster filtering
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

        // More frequent UI updates with progress info
        if (processedBlocks % 50 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }
    }

    // Sort by probability (highest first)
    locations.sort((a, b) => b.probability.compareTo(a.probability));

    // Return top results for comprehensive search
    return locations.take(200).toList();
  }

  /// Get netherite statistics for a seed using improved algorithms
  Future<Map<String, dynamic>> getNetheriteStats({
    required String seed,
    int sampleRadius = 1000,
  }) async {
    // Use Java-compatible seed conversion
    int worldSeed = MinecraftRandom.stringToSeed(seed);

    // Initialize density function with world seed
    _densityFunction = DensityFunction(worldSeed);

    int totalLocations = 0;
    double avgProbability = 0.0;
    List<double> probabilities = [];

    // Sample with finer resolution for better statistics
    for (int x = -sampleRadius; x <= sampleRadius; x += 24) {
      for (int z = -sampleRadius; z <= sampleRadius; z += 24) {
        for (int y = 8; y <= 22; y++) {
          double probability =
              _calculateOreProbability(x, y, z, OreType.netherite, worldSeed);
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
      'algorithmVersion': 'Improved v2.0 - Java-compatible',
    };
  }
}
