import 'dart:math';
import 'structure_location.dart';
import 'java_random.dart';

class StructureFinder {
  /// Generate structure-specific random using Java-compatible RNG
  JavaRandom _getStructureRandom(
      int chunkX, int chunkZ, StructureType structureType, int worldSeed) {
    int structureSeed = worldSeed ^
        (chunkX * 341873128 +
            chunkZ * 132897987 +
            structureType.index * 1000000);
    return JavaRandom(structureSeed);
  }

  /// Determine biome type based on coordinates using Java-compatible RNG
  String _getBiomeType(int x, int z, int worldSeed) {
    JavaRandom biomeRandom = _getStructureRandom(
        (x / 64).floor(), (z / 64).floor(), StructureType.village, worldSeed);

    double biomeValue = biomeRandom.nextDouble();

    if (biomeValue < 0.12) return 'desert';
    if (biomeValue < 0.22) return 'jungle';
    if (biomeValue < 0.32) return 'ocean';
    if (biomeValue < 0.40) return 'swamp';
    if (biomeValue < 0.50) return 'taiga';
    if (biomeValue < 0.60) return 'savanna';
    if (biomeValue < 0.68) return 'badlands';
    if (biomeValue < 0.78) return 'forest';
    if (biomeValue < 0.88) return 'mountains';
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

  /// Calculate structure probability using improved spacing rules and Java-compatible RNG
  double _calculateStructureProbability(
      int x, int z, StructureType structureType, int worldSeed) {
    String biome = _getBiomeType(x, z, worldSeed);

    // Handle special dimensions
    if (structureType == StructureType.endCity) {
      biome = 'end';
    } else if (structureType == StructureType.netherFortress ||
        structureType == StructureType.bastionRemnant) {
      biome = 'nether';
    }

    if (!_canStructureSpawnInBiome(structureType, biome)) return 0.0;

    int chunkX = (x / 16).floor();
    int chunkZ = (z / 16).floor();

    // Check structure spacing rules (simplified)
    if (!_checkStructureSpacing(chunkX, chunkZ, structureType, worldSeed)) {
      return 0.0;
    }

    // Get base probability with more realistic values
    double baseProbability = _getStructureBaseProbability(structureType);

    // Use Java-compatible randomness
    JavaRandom structureRandom =
        _getStructureRandom(chunkX, chunkZ, structureType, worldSeed);
    double randomFactor =
        0.6 + (structureRandom.nextDouble() * 0.8); // 0.6 to 1.4 multiplier

    double probability = baseProbability * randomFactor;

    // Apply biome-specific modifiers
    probability *= _getBiomeModifier(structureType, biome);

    return min(probability, 1.0);
  }

  /// Get more realistic base probabilities for structures
  double _getStructureBaseProbability(StructureType structureType) {
    switch (structureType) {
      case StructureType.village:
        return 0.6; // Common but not everywhere
      case StructureType.stronghold:
        return 0.15; // Very rare, only 128 per world
      case StructureType.endCity:
        return 0.25; // Rare in End
      case StructureType.netherFortress:
        return 0.4; // Uncommon in Nether
      case StructureType.bastionRemnant:
        return 0.35; // Uncommon in Nether
      case StructureType.ancientCity:
        return 0.08; // Extremely rare
      case StructureType.oceanMonument:
        return 0.2; // Rare in deep ocean
      case StructureType.woodlandMansion:
        return 0.05; // Extremely rare
      case StructureType.pillagerOutpost:
        return 0.5; // Fairly common
      case StructureType.ruinedPortal:
        return 0.8; // Very common
      case StructureType.shipwreck:
        return 0.7; // Common in ocean
      case StructureType.buriedTreasure:
        return 0.4; // Uncommon
      case StructureType.desertTemple:
        return 0.3; // Uncommon in desert
      case StructureType.jungleTemple:
        return 0.25; // Rare in jungle
      case StructureType.witchHut:
        return 0.2; // Rare in swamp
    }
  }

  /// Check simplified structure spacing rules
  bool _checkStructureSpacing(
      int chunkX, int chunkZ, StructureType structureType, int worldSeed) {
    // Simplified spacing check - in real Minecraft this is much more complex
    int spacing = _getStructureSpacing(structureType);

    // Check if this chunk could contain a structure based on spacing
    JavaRandom spacingRandom =
        JavaRandom(worldSeed + chunkX * 341873128 + chunkZ * 132897987);
    int spacingCheck = spacingRandom.nextInt(spacing);

    return spacingCheck ==
        0; // Only allow structures at specific spacing intervals
  }

  /// Get structure spacing in chunks (simplified)
  int _getStructureSpacing(StructureType structureType) {
    switch (structureType) {
      case StructureType.village:
        return 32; // Villages have 32-chunk spacing
      case StructureType.stronghold:
        return 128; // Strongholds are very far apart
      case StructureType.oceanMonument:
        return 64; // Ocean monuments have large spacing
      case StructureType.woodlandMansion:
        return 256; // Mansions are extremely far apart
      case StructureType.pillagerOutpost:
        return 48; // Outposts have medium spacing
      case StructureType.ancientCity:
        return 96; // Ancient cities are very rare
      default:
        return 24; // Default spacing for other structures
    }
  }

  /// Get biome-specific modifier for structure generation
  double _getBiomeModifier(StructureType structureType, String biome) {
    // Some structures are more common in certain biomes
    switch (structureType) {
      case StructureType.village:
        if (['plains', 'desert', 'savanna'].contains(biome)) {
          return 1.2; // More common in these biomes
        }
        return 1.0;
      case StructureType.desertTemple:
        return biome == 'desert' ? 1.5 : 0.0;
      case StructureType.jungleTemple:
        return biome == 'jungle' ? 1.5 : 0.0;
      case StructureType.witchHut:
        return biome == 'swamp' ? 1.5 : 0.0;
      case StructureType.oceanMonument:
        return biome == 'ocean' ? 1.3 : 0.0;
      default:
        return 1.0;
    }
  }

  /// Find structure locations using improved algorithms and Java-compatible RNG
  Future<List<StructureLocation>> findStructures({
    required String seed,
    required int centerX,
    required int centerZ,
    required int radius,
    required Set<StructureType> structureTypes,
    double minProbability = 0.3,
  }) async {
    // Use Java-compatible seed conversion
    int worldSeed = MinecraftRandom.stringToSeed(seed);
    List<StructureLocation> locations = [];

    // Use chunk-aligned search for better accuracy
    int step = 32; // Check every 2 chunks for better coverage

    for (int x = centerX - radius; x <= centerX + radius; x += step) {
      for (int z = centerZ - radius; z <= centerZ + radius; z += step) {
        for (StructureType structureType in structureTypes) {
          double probability =
              _calculateStructureProbability(x, z, structureType, worldSeed);

          if (probability >= minProbability) {
            int y = _getStructureY(structureType, x, z, worldSeed);
            String biome = _getBiomeType(x, z, worldSeed);

            // Handle special dimensions
            if (structureType == StructureType.endCity) {
              biome = 'end';
            } else if (structureType == StructureType.netherFortress ||
                structureType == StructureType.bastionRemnant) {
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

      // Yield control back to the UI thread periodically
      if (x % 128 == 0) {
        await Future.delayed(const Duration(milliseconds: 2));
      }
    }

    // Sort by probability (highest first)
    locations.sort((a, b) => b.probability.compareTo(a.probability));

    return locations;
  }
}
