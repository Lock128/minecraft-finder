import '../bedrock_random.dart';
import 'java_placement.dart' show ChunkPos, JavaPlacement;
import 'version_strategy.dart';

/// Pure, web-safe implementations of Bedrock Edition placement math.
///
/// Bedrock reproduces Minecraft placement with the MT19937 (Mersenne Twister)
/// RNG rather than Java's 48-bit LCG. [BedrockRandom] already masks all state
/// to 32 bits (`& 0xFFFFFFFF`), so it is web (JS) safe as-is and is reused on
/// both the web and native Bedrock paths (there is no separate C port needed
/// for the RNG itself).
///
/// The region-grid structure model mirrors Java's `spacing`/`separation`
/// scheme but seeds the MT19937 generator from the world seed mixed with the
/// region coordinates and the per-structure salt. Bedrock does not expose the
/// exact mixing constants publicly the way Java's data-driven `StructureSet`s
/// do; the mixing below is deterministic and self-consistent so that the golden
/// fixtures reproduce exactly, and it is documented as algorithm-derived in the
/// fixtures and the registry (the Bedrock version is therefore registered as
/// Supported-but-NOT-Verified so Accurate still degrades to Simulated per
/// Req 5.2 until an authoritative reference confirms the constants).
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
class BedrockPlacement {
  BedrockPlacement._();

  // Region coordinate-mixing constants (shared with the Java region grid so
  // the two editions stay structurally comparable; Bedrock mixes them into the
  // MT19937 seed instead of the LCG seed).
  static const int _mixA = 341873128712;
  static const int _mixB = 132897987541;

  /// Build the 32-bit MT19937 seed for a region. All arithmetic is reduced to a
  /// masked 32-bit value because MT19937 is seeded from a single 32-bit word.
  static int regionSeed({
    required int worldSeed,
    required int regionX,
    required int regionZ,
    required int salt,
  }) {
    // Combine the pieces, then fold down to 32 bits. The fold keeps the result
    // stable across the web (JS) target where ints are doubles: every operand
    // is masked to 32 bits before combination so no value exceeds 2^53.
    final int wx = (worldSeed & 0xFFFFFFFF);
    final int a = (regionX * (_mixA & 0xFFFFFFFF)) & 0xFFFFFFFF;
    final int b = (regionZ * (_mixB & 0xFFFFFFFF)) & 0xFFFFFFFF;
    return (wx ^ a ^ b ^ (salt & 0xFFFFFFFF)) & 0xFFFFFFFF;
  }

  /// Region-grid structure placement for Bedrock. Returns the candidate chunk
  /// position for the region containing [chunkX]/[chunkZ].
  static ChunkPos regionStructureChunk({
    required int worldSeed,
    required int chunkX,
    required int chunkZ,
    required StructurePlacement placement,
  }) {
    final int spacing = placement.spacing;
    final int separation = placement.separation;
    final int regionX = JavaPlacement.regionCoord(chunkX, spacing);
    final int regionZ = JavaPlacement.regionCoord(chunkZ, spacing);

    final rng = BedrockRandom(regionSeed(
      worldSeed: worldSeed,
      regionX: regionX,
      regionZ: regionZ,
      salt: placement.salt,
    ));

    final int range = spacing - separation;
    final int offsetX = range > 0 ? rng.nextInt(range) : 0;
    final int offsetZ = range > 0 ? rng.nextInt(range) : 0;

    return ChunkPos(regionX * spacing + offsetX, regionZ * spacing + offsetZ);
  }

  /// All region-grid candidate chunks whose structure chunk falls inside the
  /// block-radius [radius] of (centerBlockX, centerBlockZ). De-duplicated and
  /// sorted by distance to the search centre.
  static List<ChunkPos> regionStructuresInRange({
    required int worldSeed,
    required int centerBlockX,
    required int centerBlockZ,
    required int radius,
    required StructurePlacement placement,
  }) {
    final int spacing = placement.spacing;
    final int minChunkX = JavaPlacement.blockToChunk(centerBlockX - radius);
    final int maxChunkX = JavaPlacement.blockToChunk(centerBlockX + radius);
    final int minChunkZ = JavaPlacement.blockToChunk(centerBlockZ - radius);
    final int maxChunkZ = JavaPlacement.blockToChunk(centerBlockZ + radius);

    final int minRegionX = JavaPlacement.regionCoord(minChunkX, spacing) - 1;
    final int maxRegionX = JavaPlacement.regionCoord(maxChunkX, spacing) + 1;
    final int minRegionZ = JavaPlacement.regionCoord(minChunkZ, spacing) - 1;
    final int maxRegionZ = JavaPlacement.regionCoord(maxChunkZ, spacing) + 1;

    final seen = <int>{};
    final out = <ChunkPos>[];
    for (int rx = minRegionX; rx <= maxRegionX; rx++) {
      for (int rz = minRegionZ; rz <= maxRegionZ; rz++) {
        final pos = regionStructureChunk(
          worldSeed: worldSeed,
          chunkX: rx * spacing,
          chunkZ: rz * spacing,
          placement: placement,
        );
        final int blockX = JavaPlacement.chunkToBlock(pos.x) + 8;
        final int blockZ = JavaPlacement.chunkToBlock(pos.z) + 8;
        if ((blockX - centerBlockX).abs() > radius) continue;
        if ((blockZ - centerBlockZ).abs() > radius) continue;
        final key = (pos.x * 73856093) ^ (pos.z * 19349663);
        if (!seen.add(key)) continue;
        out.add(pos);
      }
    }
    out.sort((a, b) {
      final da = _distSq(a, centerBlockX, centerBlockZ);
      final db = _distSq(b, centerBlockX, centerBlockZ);
      return da.compareTo(db);
    });
    return out;
  }

  static int _distSq(ChunkPos p, int centerBlockX, int centerBlockZ) {
    final int bx = JavaPlacement.chunkToBlock(p.x) + 8;
    final int bz = JavaPlacement.chunkToBlock(p.z) + 8;
    final int dx = bx - centerBlockX;
    final int dz = bz - centerBlockZ;
    return dx * dx + dz * dz;
  }

  /// Per-chunk buried-treasure presence for Bedrock. Seeds MT19937 from the
  /// chunk and salt and emits the chunk when `nextDouble() < probability`.
  static bool buriedTreasureInChunk({
    required int worldSeed,
    required int chunkX,
    required int chunkZ,
    required int salt,
    double probability = 0.01,
  }) {
    final rng = BedrockRandom(regionSeed(
      worldSeed: worldSeed,
      regionX: chunkX,
      regionZ: chunkZ,
      salt: salt,
    ));
    return rng.nextDouble() < probability;
  }

  /// A deterministic ore vein placement for Bedrock, reproducing the
  /// `count` placements per chunk using MT19937. Mirrors the Java loop shape
  /// but with [BedrockRandom] draws.
  static List<BedrockOreVein> veinsInChunk({
    required int worldSeed,
    required int chunkX,
    required int chunkZ,
    required OreFeature feature,
    required int featureIndex,
  }) {
    final int minBlockX = JavaPlacement.chunkToBlock(chunkX);
    final int minBlockZ = JavaPlacement.chunkToBlock(chunkZ);
    final int seed = regionSeed(
      worldSeed: worldSeed,
      regionX: chunkX,
      regionZ: chunkZ,
      salt: 0x4F524500 + featureIndex, // "ORE" tag + feature index
    );
    final rng = BedrockRandom(seed);

    final out = <BedrockOreVein>[];
    final int yRange = feature.maxY - feature.minY + 1;
    for (int c = 0; c < feature.countPerChunk; c++) {
      final int localX = rng.nextInt(16);
      final int localZ = rng.nextInt(16);
      final int y = feature.minY + (yRange > 0 ? rng.nextInt(yRange) : 0);
      final int span = feature.maxVeinSize - feature.minVeinSize + 1;
      int size = feature.minVeinSize + (span > 0 ? rng.nextInt(span) : 0);
      for (int t = 0; t < feature.tries; t++) {
        if (size < feature.maxVeinSize && rng.nextDouble() < 0.5) {
          size++;
        } else {
          rng.nextDouble();
        }
      }
      if (size < 1) size = 1;
      out.add(BedrockOreVein(
        x: minBlockX + localX,
        y: y,
        z: minBlockZ + localZ,
        size: size,
      ));
    }
    return out;
  }

  /// All ore veins of [feature] within the block window around (centerX,
  /// centerZ), sorted by distance to the centre.
  static List<BedrockOreVein> veinsInRange({
    required int worldSeed,
    required int centerX,
    required int centerZ,
    required int radius,
    required OreFeature feature,
    required int featureIndex,
  }) {
    final int minChunkX = JavaPlacement.blockToChunk(centerX - radius);
    final int maxChunkX = JavaPlacement.blockToChunk(centerX + radius);
    final int minChunkZ = JavaPlacement.blockToChunk(centerZ - radius);
    final int maxChunkZ = JavaPlacement.blockToChunk(centerZ + radius);

    final out = <BedrockOreVein>[];
    for (int cx = minChunkX; cx <= maxChunkX; cx++) {
      for (int cz = minChunkZ; cz <= maxChunkZ; cz++) {
        final veins = veinsInChunk(
          worldSeed: worldSeed,
          chunkX: cx,
          chunkZ: cz,
          feature: feature,
          featureIndex: featureIndex,
        );
        for (final v in veins) {
          if ((v.x - centerX).abs() > radius) continue;
          if ((v.z - centerZ).abs() > radius) continue;
          out.add(v);
        }
      }
    }
    out.sort((a, b) {
      final da = (a.x - centerX) * (a.x - centerX) +
          (a.z - centerZ) * (a.z - centerZ);
      final db = (b.x - centerX) * (b.x - centerX) +
          (b.z - centerZ) * (b.z - centerZ);
      return da.compareTo(db);
    });
    return out;
  }
}

/// A single Bedrock ore vein placement.
class BedrockOreVein {
  const BedrockOreVein({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
  });

  final int x;
  final int y;
  final int z;
  final int size;
}
