import 'dart:math';
import 'structure_location.dart';

class StructureFinder {
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

  /// Generate structure-specific random number
  int _getStructureRandom(int chunkX, int chunkZ, StructureType structureType, int worldSeed) {
    int structureSeed = worldSeed ^ (chunkX * 341873128712 + chunkZ * 132897987541 + structureType.index * 1000000);
    return _lcg(structureSeed.abs());
  }

  /// Determine biome type based on coordinates (simplified)
  String _getBiomeType(int x, int z, int worldSeed) {
    double biomeRandom = _getStructureRandom((x / 64).floor(), (z / 64).floor(), StructureType.village, worldSeed) / 0xFFFFFFFF;
    
    if (biomeRandom < 0.15) return 'desert';
    if (biomeRandom < 0.25) return 'jungle';
    if (biomeRandom < 0.35) return 'ocean';
    if (biomeRandom < 0.45) return 'swamp';
    if (biomeRandom < 0.55) return 'taiga';
    if (biomeRandom < 0.65) return 'savanna';
    if (biomeRandom < 0.75) return 'badlands';
    if (biomeRandom < 0.85) return 'forest';
    return 'plains';
  }

  /// Check if structure can spawn in given biome
  bool _canStructureSpawnInBiome(StructureType structureType, String biome) {
    switch (structureType) {
      case StructureType.village:
        return ['plains', 'desert', 'savanna', 'taiga'].contains(biome);
      case StructureType.stronghold:
        return true; // Can spawn anywhere
      case StructureType.endCity:
        return biome == 'end'; // Special case
      case StructureType.netherFortress:
        return biome == 'nether'; // Special case
      case StructureType.bastionRemnant:
        return biome == 'nether'; // Special case
      case StructureType.ancientCity:
        return true; // Deep dark, but we'll simulate
      case StructureType.oceanMonument:
        return biome == 'ocean';
      case StructureType.woodlandMansion:
        return biome == 'forest';
      case StructureType.pillagerOutpost:
        return ['plains', 'desert', 'savanna', 'taiga'].contains(biome);
      case StructureType.ruinedPortal:
        return true; // Can spawn anywhere
      case StructureType.shipwreck:
        return biome == 'ocean';
      case StructureType.buriedTreasure:
        return biome == 'ocean';
      case StructureType.desertTemple:
        return biome == 'desert';
      case StructureType.jungleTemple:
        return biome == 'jungle';
      case StructureType.witchHut:
        return biome == 'swamp';
    }
  }

  /// Get structure generation Y level
  int _getStructureY(StructureType structureType, int x, int z, int worldSeed) {
    switch (structureType) {
      case StructureType.village:
      case StructureType.pillagerOutpost:
      case StructureType.desertTemple:
      case StructureType.jungleTemple:
      case StructureType.witchHut:
        return 64; // Surface level
      case StructureType.stronghold:
        return -20; // Underground
      case StructureType.endCity:
        return 60; // End dimension
      case StructureType.netherFortress:
      case StructureType.bastionRemnant:
        return 64; // Nether level
      case StructureType.ancientCity:
        return -52; // Deep dark
      case StructureType.oceanMonument:
        return 40; // Ocean floor
      case StructureType.woodlandMansion:
        return 80; // High surface
      case StructureType.ruinedPortal:
        return 64; // Surface
      case StructureType.shipwreck:
        return 50; // Ocean surface
      case StructureType.buriedTreasure:
        return 55; // Shallow buried
    }
  }

  /// Calculate structure probability for a specific location
  double _calculateStructureProbability(int x, int z, StructureType structureType, int worldSeed) {
    String biome = _getBiomeType(x, z, worldSeed);
    
    // Handle special dimensions
    if (structureType == StructureType.endCity) {
      biome = 'end';
    } else if (structureType == StructureType.netherFortress || structureType == StructureType.bastionRemnant) {
      biome = 'nether';
    }
    
    if (!_canStructureSpawnInBiome(structureType, biome)) return 0.0;

    int chunkX = (x / 16).floor();
    int chunkZ = (z / 16).floor();
    
    double probability = 0.0;
    
    // Structure-specific base probabilities
    switch (structureType) {
      case StructureType.village:
        probability = 0.8; // Common
        break;
      case StructureType.stronghold:
        probability = 0.3; // Rare, only 128 per world
        break;
      case StructureType.endCity:
        probability = 0.4; // Rare
        break;
      case StructureType.netherFortress:
        probability = 0.6; // Uncommon
        break;
      case StructureType.bastionRemnant:
        probability = 0.5; // Uncommon
        break;
      case StructureType.ancientCity:
        probability = 0.2; // Very rare
        break;
      case StructureType.oceanMonument:
        probability = 0.4; // Rare
        break;
      case StructureType.woodlandMansion:
        probability = 0.1; // Very rare
        break;
      case StructureType.pillagerOutpost:
        probability = 0.7; // Common
        break;
      case StructureType.ruinedPortal:
        probability = 0.9; // Very common
        break;
      case StructureType.shipwreck:
        probability = 0.8; // Common in ocean
        break;
      case StructureType.buriedTreasure:
        probability = 0.6; // Uncommon
        break;
      case StructureType.desertTemple:
        probability = 0.5; // Uncommon
        break;
      case StructureType.jungleTemple:
        probability = 0.4; // Rare
        break;
      case StructureType.witchHut:
        probability = 0.3; // Rare
        break;
    }

    // Add randomness based on chunk and structure type
    double random1 = _getStructureRandom(chunkX, chunkZ, structureType, worldSeed) / 0xFFFFFFFF;
    double random2 = _getStructureRandom(chunkX + 1, chunkZ + 1, structureType, worldSeed) / 0xFFFFFFFF;
    
    // Simulate structure generation patterns
    double structureFactor = sin(chunkX * 0.1) * cos(chunkZ * 0.1);
    probability *= (0.3 + random1 * 0.4 + random2 * 0.3 + structureFactor.abs() * 0.2);

    return min(probability, 1.0);
  }

  /// Find structure locations in a given area
  Future<List<StructureLocation>> findStructures({
    required String seed,
    required int centerX,
    required int centerZ,
    required int radius,
    required Set<StructureType> structureTypes,
    double minProbability = 0.3,
  }) async {
    int worldSeed = int.tryParse(seed) ?? _stringToSeed(seed);
    List<StructureLocation> locations = [];
    int step = 64; // Check every 4 chunks for structures

    for (int x = centerX - radius; x <= centerX + radius; x += step) {
      for (int z = centerZ - radius; z <= centerZ + radius; z += step) {
        for (StructureType structureType in structureTypes) {
          double probability = _calculateStructureProbability(x, z, structureType, worldSeed);
          
          if (probability >= minProbability) {
            int y = _getStructureY(structureType, x, z, worldSeed);
            String biome = _getBiomeType(x, z, worldSeed);
            
            // Handle special dimensions
            if (structureType == StructureType.endCity) {
              biome = 'end';
            } else if (structureType == StructureType.netherFortress || structureType == StructureType.bastionRemnant) {
              biome = 'nether';
            }
            
            locations.add(StructureLocation(
              x: x,
              y: y,
              z: z,
              chunkX: (x / 16).floor(),
              chunkZ: (z / 16).floor(),
              probability: (probability * 100).round() / 100,
              structureType: structureType,
              biome: biome,
            ));
          }
        }
      }
      
      // Add small delay to prevent UI blocking
      if (x % 256 == 0) {
        await Future.delayed(const Duration(microseconds: 1));
      }
    }

    // Sort by probability (highest first)
    locations.sort((a, b) => b.probability.compareTo(a.probability));
    
    return locations;
  }
}