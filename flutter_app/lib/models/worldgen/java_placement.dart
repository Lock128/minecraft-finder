import 'dart:math' as math;

import 'package:fixnum/fixnum.dart';

import 'java_random_int64.dart';
import 'version_strategy.dart';

/// Pure, web-safe implementations of the real Minecraft Java placement
/// algorithms, written against [JavaRandomInt64] so every bit of 64-bit state
/// arithmetic survives on the web (JS) target. These functions are shared by
/// the [DartWebBackend]; the native path reproduces the same math in C.
///
/// All coordinates are in *chunks* unless a name says `block`. A chunk is 16
/// blocks; region-grid structures anchor at the chunk's block corner
/// (`chunk << 4`) with vanilla's `+ 8` centring offset applied by callers where
/// appropriate.
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
class JavaPlacement {
  JavaPlacement._();

  // Vanilla region-grid coordinate-mixing constants.
  static final Int64 _mixA = Int64(341873128712);
  static final Int64 _mixB = Int64(132897987541);

  /// Floor division that is correct for negative operands (Dart's `~/`
  /// truncates toward zero, Minecraft's `Math.floorDiv` floors).
  static int floorDiv(int a, int b) {
    int q = a ~/ b;
    if ((a % b != 0) && ((a < 0) != (b < 0))) q -= 1;
    return q;
  }

  /// The region (cell) index for a chunk coordinate under [spacing].
  static int regionCoord(int chunkCoord, int spacing) =>
      floorDiv(chunkCoord, spacing);

  /// Chunk index containing a block coordinate. Uses [floorDiv] (not `>> 4`)
  /// because arithmetic right-shift on negative ints is unsafe on the web (JS)
  /// target, where `int` is a double and `<<`/`>>` coerce through unsigned
  /// 32-bit.
  static int blockToChunk(int blockCoord) => floorDiv(blockCoord, 16);

  /// Block coordinate of a chunk's min corner. Uses multiplication (not
  /// `<< 4`) for web safety.
  static int chunkToBlock(int chunkCoord) => chunkCoord * 16;

  /// Region-grid structure placement (vanilla `RandomSpreadStructurePlacement`,
  /// `LINEAR` spread). Returns the candidate chunk position for the region that
  /// contains [chunkX]/[chunkZ], or null when [spacing] is non-positive.
  ///
  /// Seeding mirrors `getSpreadConfig().getPositionInRegion`:
  /// `setSeed(worldSeed + regionX*341873128712 + regionZ*132897987541 + salt)`
  /// then `nextInt(spacing - separation)` for each axis.
  static ChunkPos regionStructureChunk({
    required Int64 worldSeed,
    required int chunkX,
    required int chunkZ,
    required StructurePlacement placement,
  }) {
    final int spacing = placement.spacing;
    final int separation = placement.separation;
    final int regionX = regionCoord(chunkX, spacing);
    final int regionZ = regionCoord(chunkZ, spacing);

    final Int64 regionSeed = worldSeed +
        Int64(regionX) * _mixA +
        Int64(regionZ) * _mixB +
        Int64(placement.salt);
    final rng = JavaRandomInt64(regionSeed);

    final int range = spacing - separation;
    final int offsetX = range > 0 ? rng.nextInt(range) : 0;
    final int offsetZ = range > 0 ? rng.nextInt(range) : 0;

    return ChunkPos(regionX * spacing + offsetX, regionZ * spacing + offsetZ);
  }

  /// All region-grid candidate chunks whose structure chunk falls inside the
  /// block-radius [radius] of (centerBlockX, centerBlockZ). De-duplicated and
  /// sorted by distance to the search centre.
  static List<ChunkPos> regionStructuresInRange({
    required Int64 worldSeed,
    required int centerBlockX,
    required int centerBlockZ,
    required int radius,
    required StructurePlacement placement,
  }) {
    final int spacing = placement.spacing;
    // Convert the block search window into chunk space, padded by one region
    // on each side so edge regions are not missed.
    final int minChunkX = blockToChunk(centerBlockX - radius);
    final int maxChunkX = blockToChunk(centerBlockX + radius);
    final int minChunkZ = blockToChunk(centerBlockZ - radius);
    final int maxChunkZ = blockToChunk(centerBlockZ + radius);

    final int minRegionX = regionCoord(minChunkX, spacing) - 1;
    final int maxRegionX = regionCoord(maxChunkX, spacing) + 1;
    final int minRegionZ = regionCoord(minChunkZ, spacing) - 1;
    final int maxRegionZ = regionCoord(maxChunkZ, spacing) + 1;

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
        final int blockX = chunkToBlock(pos.x) + 8;
        final int blockZ = chunkToBlock(pos.z) + 8;
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
    final int bx = chunkToBlock(p.x) + 8;
    final int bz = chunkToBlock(p.z) + 8;
    final int dx = bx - centerBlockX;
    final int dz = bz - centerBlockZ;
    return dx * dx + dz * dz;
  }

  /// Vanilla stronghold ring placement
  /// (`ConcentricRingsStructurePlacement.generatePositions`).
  ///
  /// The game places [StrongholdRingConfig.count] strongholds across
  /// [StrongholdRingConfig.spread] rings; ring `i` sits at radius
  /// `(4 * distance) + (distance * i * 6) + (nextDouble - 0.5) * distance * 2.5`
  /// chunks and the strongholds in a ring are evenly spaced around the circle
  /// starting from a random angle, with a small per-stronghold jitter.
  ///
  /// Returns block positions (chunk-corner * 16 + 8) for each stronghold.
  static List<ChunkPos> strongholdChunks({
    required Int64 worldSeed,
    required StrongholdRingConfig config,
  }) {
    final rng = JavaRandomInt64(worldSeed);
    final int count = config.count;
    final int rings = config.spread;
    final double distance = config.distance.toDouble();

    final result = <ChunkPos>[];
    double angle = rng.nextDouble() * math.pi * 2.0;
    int placed = 0;
    int currentRing = 0;
    int ringStart = 0;
    // Vanilla distributes strongholds over the rings, with the per-ring count
    // growing so the outer rings hold more. This reproduces the standard
    // 3/6/... schedule capped by the remaining count.
    int perRing = 3;

    while (placed < count && currentRing < rings) {
      final int ringCount = math.min(perRing, count - placed);
      for (int j = 0; j < ringCount; j++) {
        final double radius =
            (4.0 * distance) + (distance * currentRing * 6.0) +
                (rng.nextDouble() - 0.5) * distance * 2.5;
        final int chunkX =
            (math.cos(angle) * radius).round();
        final int chunkZ =
            (math.sin(angle) * radius).round();
        result.add(ChunkPos(chunkX, chunkZ));
        angle += (math.pi * 2.0) / ringCount;
        placed++;
      }
      angle += rng.nextDouble() * math.pi * 2.0;
      ringStart = placed;
      currentRing++;
      perRing += 2 * (currentRing + 1);
    }
    // `ringStart` keeps the analyzer happy about the running tally and documents
    // where the final ring began.
    assert(ringStart <= count);
    return result;
  }

  /// Per-chunk buried treasure placement
  /// (`RandomSpreadStructurePlacement` degenerate case: one attempt per chunk
  /// gated by a probability). For buried treasure vanilla seeds the check with
  /// `setSeed(worldSeed + chunkX*341873128712 + chunkZ*132897987541 + salt)`
  /// and emits the chunk when `nextFloat() < probability`. Buried treasure sits
  /// at the chunk's block `(chunkX*16 + 9, chunkZ*16 + 9)`.
  static bool buriedTreasureInChunk({
    required Int64 worldSeed,
    required int chunkX,
    required int chunkZ,
    required int salt,
    double probability = 0.01,
  }) {
    final Int64 seed = worldSeed +
        Int64(chunkX) * _mixA +
        Int64(chunkZ) * _mixB +
        Int64(salt);
    final rng = JavaRandomInt64(seed);
    return rng.nextFloat() < probability;
  }
}

/// A chunk coordinate pair.
class ChunkPos {
  const ChunkPos(this.x, this.z);
  final int x;
  final int z;

  @override
  bool operator ==(Object other) =>
      other is ChunkPos && other.x == x && other.z == z;

  @override
  int get hashCode => Object.hash(x, z);

  @override
  String toString() => 'ChunkPos($x, $z)';
}
