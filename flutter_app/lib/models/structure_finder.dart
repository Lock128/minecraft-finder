import 'dart:math';
import 'structure_location.dart';
import 'java_random.dart';
import 'noise.dart';
import 'biome_classifier.dart';

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

  /// Deep-dark noise instance, cached per world-seed. Kept separate from the
  /// shared biome classifier because deep_dark uses its own (larger, sparser)
  /// noise pattern rather than the temperature/humidity model.
  PerlinNoise? _tempNoise;
  int? _biomeSeed;

  /// Shared biome classifier (source of truth in biome_classifier.dart).
  /// OreFinder uses the same class so biome assignments stay identical.
  final BiomeClassifier _biomeClassifier = BiomeClassifier();

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
        return biome == 'deep_dark'; // Only in deep dark biome
      case StructureType.oceanMonument:
        // Ocean monuments require deep ocean. The classifier now emits both
        // 'ocean' and 'deep_ocean' where it previously emitted a single
        // 'ocean'; accept both so the monument's eligible area does not shrink
        // relative to the pre-split classifier.
        return ['ocean', 'deep_ocean'].contains(biome);
      case StructureType.woodlandMansion:
        // Third Drop 2026: the cool-temperate forest band was subdivided to
        // introduce 'dappled_forest' and 'cherry_grove'. Woodland mansions are
        // wooded-biome structures, so we keep them eligible across all three of
        // the wooded slices that used to be a single 'forest' region. This
        // preserves the mansion's original eligible area (humidity [-0.3, 0.3))
        // that the new biomes would otherwise have halved.
        return ['forest', 'dappled_forest', 'cherry_grove'].contains(biome);
      case StructureType.pillagerOutpost:
        return ['plains', 'desert', 'savanna', 'taiga'].contains(biome);
      case StructureType.ruinedPortal:
        return true; // Can spawn anywhere
      case StructureType.shipwreck:
        // Shipwrecks generate in oceans and on beaches. Accept every category
        // carved out of the old single 'ocean' band so the eligible area is
        // at least as large as before the split.
        return ['ocean', 'deep_ocean', 'beach'].contains(biome);
      case StructureType.buriedTreasure:
        // Buried treasure generates in beach chunks and along ocean edges.
        // The pre-split classifier returned a single 'ocean' for this whole
        // humidity strip, so we accept every category it was subdivided into
        // (beach + ocean + deep_ocean) to guarantee the eligible area does not
        // shrink. Beach is the canonical biome; the ocean categories preserve
        // the original coverage.
        return ['beach', 'ocean', 'deep_ocean'].contains(biome);
      case StructureType.desertTemple:
        return biome == 'desert';
      case StructureType.jungleTemple:
        return biome == 'jungle';
      case StructureType.witchHut:
        return biome == 'swamp';
      case StructureType.abandonedCamp:
        // Third Drop 2026: Abandoned Camp generates in the new Dappled Forest
        // biome and in Cherry Groves.
        return ['dappled_forest', 'cherry_grove'].contains(biome);
    }
  }

  /// Check if a location qualifies as deep_dark biome.
  /// 
  /// Deep dark generates in large "cheese caves" at Y=-52 or below.
  /// We approximate this using noise to create sporadic deep_dark pockets.
  bool _isDeepDark(int x, int z, int worldSeed) {
    if (_biomeSeed != worldSeed) {
      _tempNoise = PerlinNoise(worldSeed + 1000);
      _biomeSeed = worldSeed;
    }

    // Deep dark uses a different noise pattern — larger, sparser pockets
    double deepDarkNoise = _tempNoise!.octaveNoise3D(
        x * 0.002, -52 * 0.01, z * 0.002, 2, 0.6, 1.0);
    
    // Only ~15% of valid underground area is deep_dark
    return deepDarkNoise > 0.35;
  }

  /// Get structure generation Y level
  int _getStructureY(StructureType structureType, int x, int z, int worldSeed) {
    switch (structureType) {
      case StructureType.village:
      case StructureType.pillagerOutpost:
      case StructureType.desertTemple:
      case StructureType.jungleTemple:
      case StructureType.witchHut:
      case StructureType.abandonedCamp:
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

    // Handle special dimensions and biomes
    if (structureType == StructureType.endCity) {
      biome = 'end';
    } else if (structureType == StructureType.netherFortress ||
        structureType == StructureType.bastionRemnant) {
      biome = 'nether';
    } else if (structureType == StructureType.ancientCity) {
      // Ancient cities only spawn in deep_dark biome
      biome = _isDeepDark(x, z, worldSeed) ? 'deep_dark' : biome;
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
      case StructureType.abandonedCamp:
        return 0.45; // Common-ish surface structure in its native biomes
    }
  }

  /// Check whether [chunkX],[chunkZ] is the designated candidate chunk for
  /// a structure of [structureType] in its region, then roll the actual spawn
  /// probability.
  ///
  /// Real Minecraft uses a region grid where each N×N chunk region has exactly
  /// one candidate location, chosen by mixing the world seed with the region
  /// coordinates. A second RNG roll decides whether the candidate actually
  /// generates. This avoids the clustering that a pure per-chunk random check
  /// produces.
  ///
  /// **Strongholds are special**: they use a ring-based system with fixed counts
  /// per ring, not a region grid. See [_checkStrongholdPlacement].
  ///
  /// **Buried treasure is special**: it can spawn in any beach chunk at the
  /// fixed chunk-local position (9, 9). See [_checkBuriedTreasurePlacement].
  bool _checkStructureSpacing(
      int chunkX, int chunkZ, StructureType structureType, int worldSeed) {
    // Strongholds use ring-based placement, not region grid
    if (structureType == StructureType.stronghold) {
      return _checkStrongholdPlacement(chunkX, chunkZ, worldSeed);
    }

    // Buried treasure uses per-chunk probability, always at (9, 9) in chunk
    if (structureType == StructureType.buriedTreasure) {
      return _checkBuriedTreasurePlacement(chunkX, chunkZ, worldSeed);
    }

    final params = _getStructureSpacingParams(structureType);
    final int spacing = params['spacing']!;    // region size in chunks
    final int separation = params['separation']!; // minimum gap in chunks

    // Derive the region this chunk belongs to (integer division, floor for negatives)
    int regionX = chunkX < 0
        ? ((chunkX + 1) ~/ spacing) - 1
        : chunkX ~/ spacing;
    int regionZ = chunkZ < 0
        ? ((chunkZ + 1) ~/ spacing) - 1
        : chunkZ ~/ spacing;

    // Pick the one candidate chunk inside this region using Java-compatible RNG.
    // Mix is identical to Minecraft's StructureStart seed construction.
    int regionSeed = worldSeed +
        regionX * 341873128 +
        regionZ * 132897987 +
        structureType.index * 10000003;
    JavaRandom regionRandom = JavaRandom(regionSeed);

    // Offset within the region: [0, spacing - separation)
    int range = spacing - separation;
    if (range <= 0) range = 1;
    int candidateOffsetX = regionRandom.nextInt(range);
    int candidateOffsetZ = regionRandom.nextInt(range);

    int candidateChunkX = regionX * spacing + candidateOffsetX;
    int candidateChunkZ = regionZ * spacing + candidateOffsetZ;

    // This chunk is only eligible if it is the candidate for its region.
    if (chunkX != candidateChunkX || chunkZ != candidateChunkZ) return false;

    // Second roll: does the structure actually generate at this candidate?
    // Use a different seed so the placement roll is independent of the offset roll.
    int placeSeed = worldSeed ^
        (chunkX * 341873128 +
            chunkZ * 132897987 +
            structureType.index * 1000000);
    JavaRandom placeRandom = JavaRandom(placeSeed);
    double spawnChance = _getStructureSpawnChance(structureType);
    return placeRandom.nextDouble() < spawnChance;
  }

  /// Stronghold ring-based placement.
  ///
  /// Minecraft places strongholds in concentric rings around the world origin:
  /// - Ring 1: 3 strongholds, 1408–2688 blocks from origin (88–168 chunks)
  /// - Ring 2: 6 strongholds, 4480–5760 blocks (280–360 chunks)
  /// - Ring 3: 10 strongholds, 7552–8832 blocks (472–552 chunks)
  /// - ... up to 8 rings, 128 total strongholds
  ///
  /// Within each ring, strongholds are evenly spaced angularly with a random
  /// offset. We approximate this by checking if the chunk is within any ring's
  /// distance band and has the correct angular position.
  bool _checkStrongholdPlacement(int chunkX, int chunkZ, int worldSeed) {
    // Convert to block coordinates (chunk center)
    double blockX = chunkX * 16.0 + 8;
    double blockZ = chunkZ * 16.0 + 8;
    double distance = sqrt(blockX * blockX + blockZ * blockZ);
    double angle = atan2(blockZ, blockX); // radians, -π to π

    // Ring definitions: [count, minDist, maxDist] in blocks
    const List<List<int>> rings = [
      [3, 1408, 2688],
      [6, 4480, 5760],
      [10, 7552, 8832],
      [15, 10624, 11904],
      [21, 13696, 14976],
      [28, 16768, 18048],
      [36, 19840, 21120],
      [9, 22912, 24192], // Last ring has fewer to reach 128 total
    ];

    for (int ringIndex = 0; ringIndex < rings.length; ringIndex++) {
      int count = rings[ringIndex][0];
      int minDist = rings[ringIndex][1];
      int maxDist = rings[ringIndex][2];

      if (distance < minDist || distance > maxDist) continue;

      // This chunk is in the distance band for this ring.
      // Check if angle matches one of the stronghold positions.
      JavaRandom ringRandom = JavaRandom(worldSeed + ringIndex * 9999991);
      double startAngle = ringRandom.nextDouble() * 2 * pi; // Random offset for ring

      for (int i = 0; i < count; i++) {
        double strongholdAngle = startAngle + (2 * pi * i / count);
        // Normalize to -π to π
        while (strongholdAngle > pi) {
          strongholdAngle -= 2 * pi;
        }
        while (strongholdAngle < -pi) {
          strongholdAngle += 2 * pi;
        }

        // Check if this chunk's angle is close to a stronghold position
        // Allow ~11.25 degrees tolerance (π/16 radians ≈ one chunk width at typical distance)
        double angleDiff = (angle - strongholdAngle).abs();
        if (angleDiff > pi) angleDiff = 2 * pi - angleDiff;

        if (angleDiff < pi / 16) {
          // Additional distance check within the ring band
          double targetDist = minDist + ringRandom.nextDouble() * (maxDist - minDist);
          if ((distance - targetDist).abs() < 256) { // Within ~16 chunks of target
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Buried treasure placement.
  ///
  /// Unlike most structures, buried treasure doesn't use region-based spacing.
  /// Instead, each beach chunk has an independent probability of containing
  /// buried treasure, always at the chunk-local position (9, 9, Y varies).
  /// The biome check (ocean/beach) is handled by _canStructureSpawnInBiome.
  bool _checkBuriedTreasurePlacement(int chunkX, int chunkZ, int worldSeed) {
    // Seed for this specific chunk
    int chunkSeed = worldSeed ^
        (chunkX * 341873128 + chunkZ * 132897987 + 10387320); // Salt for buried treasure
    JavaRandom chunkRandom = JavaRandom(chunkSeed);

    // ~4% chance per beach chunk (roughly matching Minecraft's frequency)
    return chunkRandom.nextDouble() < 0.04;
  }

  /// Spawn-chance for the second RNG roll (independent of base probability).
  double _getStructureSpawnChance(StructureType structureType) {
    switch (structureType) {
      case StructureType.village:         return 0.7;
      case StructureType.stronghold:      return 1.0; // always if candidate
      case StructureType.endCity:         return 0.5;
      case StructureType.netherFortress:  return 0.8;
      case StructureType.bastionRemnant:  return 0.8;
      case StructureType.ancientCity:     return 0.6;
      case StructureType.oceanMonument:   return 0.6;
      case StructureType.woodlandMansion: return 1.0; // extremely rare via spacing
      case StructureType.pillagerOutpost: return 0.6;
      case StructureType.ruinedPortal:    return 0.9;
      case StructureType.shipwreck:       return 0.85;
      case StructureType.buriedTreasure:  return 0.7;
      case StructureType.desertTemple:    return 0.75;
      case StructureType.jungleTemple:    return 0.7;
      case StructureType.witchHut:        return 0.65;
      case StructureType.abandonedCamp:   return 0.6;
    }
  }

  /// Region spacing and minimum separation in chunks.
  ///
  /// spacing   — side length of the region grid (one candidate per region)
  /// separation — minimum gap between candidates (kept away from region edge)
  ///
  /// Values sourced from Minecraft wiki / decompiled structure placement tables.
  Map<String, int> _getStructureSpacingParams(StructureType structureType) {
    switch (structureType) {
      case StructureType.village:
        return {'spacing': 32, 'separation': 8};
      case StructureType.stronghold:
        return {'spacing': 128, 'separation': 32};
      case StructureType.oceanMonument:
        return {'spacing': 32, 'separation': 5};
      case StructureType.woodlandMansion:
        return {'spacing': 80, 'separation': 20};
      case StructureType.pillagerOutpost:
        return {'spacing': 32, 'separation': 8};
      case StructureType.ancientCity:
        return {'spacing': 24, 'separation': 8};
      case StructureType.netherFortress:
        return {'spacing': 27, 'separation': 4};
      case StructureType.bastionRemnant:
        return {'spacing': 27, 'separation': 4};
      case StructureType.endCity:
        return {'spacing': 20, 'separation': 11};
      case StructureType.desertTemple:
        return {'spacing': 32, 'separation': 8};
      case StructureType.jungleTemple:
        return {'spacing': 32, 'separation': 8};
      case StructureType.witchHut:
        return {'spacing': 32, 'separation': 8};
      case StructureType.shipwreck:
        return {'spacing': 24, 'separation': 4};
      case StructureType.buriedTreasure:
        return {'spacing': 1,  'separation': 0}; // one per chunk — probability driven
      case StructureType.ruinedPortal:
        return {'spacing': 40, 'separation': 15};
      case StructureType.abandonedCamp:
        return {'spacing': 32, 'separation': 8}; // surface spacing like villages
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
        // Accept both ocean categories (see _canStructureSpawnInBiome). Deep
        // ocean is the canonical monument biome, so give it the full modifier
        // while shallow ocean keeps the same 1.3 it had before the split.
        return ['ocean', 'deep_ocean'].contains(biome) ? 1.3 : 0.0;
      case StructureType.abandonedCamp:
        // Slightly more common in its native Dappled Forest / Cherry Grove.
        return ['dappled_forest', 'cherry_grove'].contains(biome) ? 1.2 : 1.0;
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
