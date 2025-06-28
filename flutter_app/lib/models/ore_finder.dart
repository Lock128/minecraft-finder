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
    int chunkSeed = worldSeed ^ (chunkX * 341873128712 + chunkZ * 132897987541 + layer);
    return _lcg(chunkSeed.abs());
  }

  /// Determine biome type based on coordinates (simplified)
  String _getBiomeType(int x, int z, int worldSeed) {
    double biomeRandom = _getChunkRandom((x / 64).floor(), (z / 64).floor(), 0, worldSeed) / 0xFFFFFFFF;
    
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
    }
  }

  /// Calculate ore probability for a specific location
  double _calculateOreProbability(int x, int y, int z, OreType oreType, int worldSeed, {bool includeNether = false}) {
    String biome = _getBiomeType(x, z, worldSeed);
    
    // Handle nether inclusion
    if (includeNether && oreType == OreType.gold) {
      // Randomly assign some areas as nether for demonstration
      double netherRandom = _getChunkRandom((x / 128).floor(), (z / 128).floor(), 1, worldSeed) / 0xFFFFFFFF;
      if (netherRandom > 0.8) {
        biome = 'nether';
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
    }

    // Add randomness based on chunk and coordinates
    double random1 = _getChunkRandom(chunkX, chunkZ, y, worldSeed) / 0xFFFFFFFF;
    double random2 = _getChunkRandom(chunkX + x % 16, chunkZ + z % 16, y, worldSeed) / 0xFFFFFFFF;
    
    // Simulate ore vein generation patterns
    double veinFactor = sin(x * 0.1) * cos(z * 0.1) * sin(y * 0.2);
    probability *= (0.5 + random1 * 0.3 + random2 * 0.2 + veinFactor.abs() * 0.3);

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
    int worldSeed = int.tryParse(seed) ?? _stringToSeed(seed);
    List<OreLocation> locations = [];
    int step = 8; // Check every 8 blocks for performance

    for (int x = centerX - radius; x <= centerX + radius; x += step) {
      for (int z = centerZ - radius; z <= centerZ + radius; z += step) {
        String biome = _getBiomeType(x, z, worldSeed);
        
        // Handle nether inclusion
        if (includeNether && oreType == OreType.gold) {
          double netherRandom = _getChunkRandom((x / 128).floor(), (z / 128).floor(), 1, worldSeed) / 0xFFFFFFFF;
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
        }
        
        for (int y = yMin; y <= yMax; y += yStep) {
          double probability = _calculateOreProbability(x, y, z, oreType, worldSeed, includeNether: includeNether);
          
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
    
    return locations;
  }
}