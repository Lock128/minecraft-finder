import 'dart:math';
import 'ore_location.dart';

class OreFinder {
  /// Convert string seed to numeric seed
  int _stringToSeed(String seedStr) {
    int hash = 0;
    for (int i = 0; i < seedStr.length; i++) {
      int char = seedStr.codeUnitAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & 0xFFFFFFFF; // Convert to 32-bit integer
    }
    return hash;
  }

  /// Simple LCG (Linear Congruential Generator) for predictable randomness
  int _lcg(int seed) {
    return (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
  }

  /// Generate chunk-based random number
  int _getChunkRandom(int chunkX, int chunkZ, int layer, int worldSeed) {
    int chunkSeed =
        worldSeed ^ (chunkX * 341873128712 + chunkZ * 132897987541 + layer);
    return _lcg(chunkSeed.abs());
  }

  /// Determine biome type based on coordinates (simplified)
  String _getBiomeType(int x, int z, int worldSeed) {
    double biomeRandom =
        _getChunkRandom((x / 64).floor(), (z / 64).floor(), 0, worldSeed) /
            0xFFFFFFFF;

    // Simulate badlands biome (mesa) - roughly 5% of overworld
    if (biomeRandom > 0.95) {
      return 'badlands';
    }

    return 'overworld';
  }

  /// Check if ore can spawn at given coordinates
  bool _isValidOreLayer(int y, OreType oreType, String biome) {
    switch (oreType) {
      case OreType.diamond:
        return y >= -64 && y <= 16;
      case OreType.gold:
        switch (biome) {
          case 'overworld':
            return y >= -64 && y <= 32;
          case 'badlands':
            return y >= -64 && y <= 256;
          case 'nether':
            return y >= 10 && y <= 117;
          default:
            return false;
        }
      case OreType.netherite:
        return biome == 'nether' &&
            y >= 8 &&
            y <= 22; // Ancient debris spawns in nether Y 8-22
      case OreType.redstone:
        return y >= -64 &&
            y <= 15; // Redstone spawns Y -64 to 15, most common at Y -59
      case OreType.iron:
        return y >= -64 &&
            y <=
                256; // Iron spawns throughout the world, peaks at Y 15 and Y 232
      case OreType.coal:
        return y >= 0 &&
            y <= 256; // Coal spawns Y 0 to 256, most common at Y 96
    }
  }

  /// Calculate ore probability for a specific location
  double _calculateOreProbability(
      int x, int y, int z, OreType oreType, int worldSeed,
      {bool includeNether = false}) {
    String biome = _getBiomeType(x, z, worldSeed);

    // Handle nether inclusion or netherite search
    if ((includeNether && oreType == OreType.gold) ||
        oreType == OreType.netherite) {
      // For netherite, always treat as nether biome
      if (oreType == OreType.netherite) {
        biome = 'nether';
      } else {
        // For gold with nether inclusion, randomly assign some areas as nether
        double netherRandom = _getChunkRandom(
                (x / 128).floor(), (z / 128).floor(), 1, worldSeed) /
            0xFFFFFFFF;
        if (netherRandom > 0.8) {
          biome = 'nether';
        }
      }
    }

    if (!_isValidOreLayer(y, oreType, biome)) return 0.0;

    int chunkX = (x / 16).floor();
    int chunkZ = (z / 16).floor();

    double probability = 0.0;

    // Ore-specific probability calculation
    switch (oreType) {
      case OreType.diamond:
        if (y >= -64 && y <= -54) {
          probability += 0.8; // Peak diamond layer
        } else if (y >= -53 && y <= -48) {
          probability += 0.6;
        } else if (y >= -47 && y <= -32) {
          probability += 0.4;
        } else {
          probability += 0.2;
        }
        break;

      case OreType.gold:
        switch (biome) {
          case 'overworld':
            if (y >= -64 && y <= -48) {
              probability += 0.4;
            } else if (y >= -47 && y <= -16) {
              probability += 0.6; // Peak gold layer
            } else if (y >= -15 && y <= 32) {
              probability += 0.3;
            }
            break;

          case 'badlands':
            if (y >= 32 && y <= 80) {
              probability += 0.9; // Excellent gold generation
            } else if (y >= -64 && y <= 31) {
              probability += 0.7;
            } else if (y >= 81 && y <= 256) {
              probability += 0.5;
            }
            break;

          case 'nether':
            if (y >= 10 && y <= 117) {
              probability += 0.8;
            }
            break;
        }
        break;

      case OreType.netherite:
        // Ancient debris (netherite) spawns in nether Y 8-22, most common at Y 15
        if (y >= 13 && y <= 17) {
          probability += 0.9; // Peak ancient debris layer
        } else if (y >= 10 && y <= 19) {
          probability += 0.7; // Good ancient debris layers
        } else if (y >= 8 && y <= 22) {
          probability += 0.5; // Decent ancient debris layers
        }
        // Make netherite more findable for testing
        probability *= 0.8; // Increased multiplier
        break;

      case OreType.redstone:
        if (y >= -64 && y <= -59) {
          probability += 0.9; // Peak redstone layer
        } else if (y >= -58 && y <= -48) {
          probability += 0.7; // Good redstone layers
        } else if (y >= -47 && y <= -32) {
          probability += 0.5; // Decent redstone layers
        } else if (y >= -31 && y <= 15) {
          probability += 0.3; // Lower redstone layers
        }
        break;

      case OreType.iron:
        if (y >= 128 && y <= 256) {
          // Mountain iron generation (peaks around Y 232)
          double mountainFactor = 1.0 - ((y - 232).abs() / 104.0);
          probability += 0.8 * mountainFactor;
        } else if (y >= -24 && y <= 56) {
          // Underground iron generation (peaks around Y 15)
          double undergroundFactor = 1.0 - ((y - 15).abs() / 40.0);
          probability += 0.9 * undergroundFactor;
        } else if (y >= -64 && y <= 72) {
          // General iron availability
          probability += 0.4;
        }
        break;

      case OreType.coal:
        if (y >= 80 && y <= 136) {
          // Peak coal generation around Y 96
          double coalFactor = 1.0 - ((y - 96).abs() / 40.0);
          probability += 0.9 * coalFactor;
        } else if (y >= 0 && y <= 256) {
          // General coal availability
          probability += 0.6;
        }
        break;
    }

    // Add randomness based on chunk and coordinates
    double random1 = _getChunkRandom(chunkX, chunkZ, y, worldSeed) / 0xFFFFFFFF;
    double random2 =
        _getChunkRandom(chunkX + x % 16, chunkZ + z % 16, y, worldSeed) /
            0xFFFFFFFF;

    // Simulate ore vein generation patterns
    double veinFactor = sin(x * 0.1) * cos(z * 0.1) * sin(y * 0.2);
    probability *=
        (0.5 + random1 * 0.3 + random2 * 0.2 + veinFactor.abs() * 0.3);

    return min(probability, 1.0);
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
  }) async {
    // Lower minimum probability for netherite since it's much rarer
    if (oreType == OreType.netherite) {
      minProbability = 0.15; // Even lower threshold
      print('Searching for netherite with minProbability: $minProbability');
    }
    int worldSeed = int.tryParse(seed) ?? _stringToSeed(seed);
    List<OreLocation> locations = [];
    int step = 8; // Check every 8 blocks for performance

    for (int x = centerX - radius; x <= centerX + radius; x += step) {
      for (int z = centerZ - radius; z <= centerZ + radius; z += step) {
        String biome = _getBiomeType(x, z, worldSeed);

        // Handle nether inclusion
        if (includeNether && oreType == OreType.gold) {
          double netherRandom = _getChunkRandom(
                  (x / 128).floor(), (z / 128).floor(), 1, worldSeed) /
              0xFFFFFFFF;
          if (netherRandom > 0.8) {
            biome = 'nether';
          }
        }

        // Determine Y range based on ore type and biome
        int yMin = -64, yMax = 32, yStep = 4;

        switch (oreType) {
          case OreType.diamond:
            yMax = 16;
            break;
          case OreType.gold:
            if (biome == 'badlands') {
              yMax = 256;
              yStep = 8;
            } else if (biome == 'nether') {
              yMin = 10;
              yMax = 117;
            }
            break;
          case OreType.netherite:
            yMin = 8;
            yMax = 22;
            yStep =
                1; // Very small steps for rare netherite to ensure we don't miss spots
            break;
          case OreType.redstone:
            yMin = -64;
            yMax = 15;
            yStep = 4;
            break;
          case OreType.iron:
            yMin = -64;
            yMax = 256;
            yStep = 8; // Larger steps since iron is common
            break;
          case OreType.coal:
            yMin = 0;
            yMax = 256;
            yStep = 8; // Larger steps since coal is very common
            break;
        }

        for (int y = yMin; y <= yMax; y += yStep) {
          double probability = _calculateOreProbability(
              x, y, z, oreType, worldSeed,
              includeNether: includeNether);

          // Debug logging for netherite
          if (oreType == OreType.netherite && probability > 0) {
            print(
                'Netherite found at ($x, $y, $z) with probability: $probability');
          }

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

      // Add small delay to prevent UI blocking
      if (x % 64 == 0) {
        await Future.delayed(const Duration(microseconds: 1));
      }
    }

    // Sort by probability (highest first)
    locations.sort((a, b) => b.probability.compareTo(a.probability));

    // Debug logging
    if (oreType == OreType.netherite) {
      print('Netherite search complete. Found ${locations.length} locations');
      if (locations.isNotEmpty) {
        print(
            'Top netherite location: (${locations.first.x}, ${locations.first.y}, ${locations.first.z}) - ${locations.first.probability}');
      }
    }

    return locations;
  }

  /// Comprehensive search for all netherite (Ancient Debris) in a world seed
  Future<List<OreLocation>> findAllNetherite({
    required String seed,
    required int centerX,
    required int centerZ,
    int searchRadius = 2000,
  }) async {
    int worldSeed = int.tryParse(seed) ?? _stringToSeed(seed);
    List<OreLocation> locations = [];

    // Use smaller step size for comprehensive search
    int step = 16; // Search every chunk (16 blocks)
    int totalChunks = ((searchRadius * 2) / step).ceil();
    int processedChunks = 0;

    print('Starting comprehensive netherite search...');
    print(
        'Searching ${totalChunks * totalChunks} chunks in a ${searchRadius * 2}x${searchRadius * 2} area');

    for (int x = centerX - searchRadius;
        x <= centerX + searchRadius;
        x += step) {
      for (int z = centerZ - searchRadius;
          z <= centerZ + searchRadius;
          z += step) {
        // Ancient debris spawns in nether, Y 8-22
        for (int y = 8; y <= 22; y++) {
          double probability =
              _calculateOreProbability(x, y, z, OreType.netherite, worldSeed);

          // Use very low threshold for comprehensive search to find more locations
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

        processedChunks++;

        // Add progress updates and prevent UI blocking
        if (processedChunks % 100 == 0) {
          double progress =
              (processedChunks / (totalChunks * totalChunks)) * 100;
          print(
              'Progress: ${progress.toStringAsFixed(1)}% - Found ${locations.length} netherite locations');
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }
    }

    // Sort by probability (highest first)
    locations.sort((a, b) => b.probability.compareTo(a.probability));

    print(
        'Comprehensive search complete! Found ${locations.length} netherite locations');

    // Return more results for comprehensive search
    return locations.take(300).toList();
  }

  /// Get netherite statistics for a seed
  Future<Map<String, dynamic>> getNetheriteStats({
    required String seed,
    int sampleRadius = 1000,
  }) async {
    int worldSeed = int.tryParse(seed) ?? _stringToSeed(seed);
    int totalLocations = 0;
    double avgProbability = 0.0;
    List<double> probabilities = [];

    // Sample a smaller area for statistics
    for (int x = -sampleRadius; x <= sampleRadius; x += 32) {
      for (int z = -sampleRadius; z <= sampleRadius; z += 32) {
        for (int y = 8; y <= 22; y += 2) {
          double probability =
              _calculateOreProbability(x, y, z, OreType.netherite, worldSeed);
          if (probability >= 0.1) {
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
    };
  }
}
