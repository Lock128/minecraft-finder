import 'package:fixnum/fixnum.dart';

import 'java_placement.dart';
import 'java_random_int64.dart';
import 'version_strategy.dart';

/// A single ore vein placement returned by the Java ore feature loops.
class OreVein {
  const OreVein({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
  });

  /// Block coordinate of the vein origin.
  final int x;
  final int y;
  final int z;

  /// Vein size (number of ore blocks). Always >= 1 (Req 9.3).
  final int size;
}

/// Real per-chunk `count x tries` ore feature loops for Java 1.18+ (M3).
///
/// Minecraft places ore via a `PlacedFeature`: a `CountPlacement` chooses how
/// many times to run the feature per chunk; each run is `setFeatureSeed`-seeded
/// and picks a random in-chunk column, a Y from the height provider, and grows
/// an `OreFeature` vein of up to the configured `size`. This reproduces that
/// loop structure with [JavaRandomInt64] so results are web-safe and
/// deterministic.
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
class JavaOre {
  JavaOre._();

  static final Int64 _decoA = Int64.parseHex('6A09E667F3BCC909');
  static final Int64 _decoB = Int64.parseHex('B7E151628AED2A6B');

  /// Vanilla `WorldgenRandom.setDecorationSeed`: derive the per-chunk
  /// decoration seed from the world seed and the chunk's min block corner.
  static Int64 decorationSeed(Int64 worldSeed, int minBlockX, int minBlockZ) {
    final rng = JavaRandomInt64(worldSeed);
    final Int64 a = (rng.nextLong() | Int64.ONE);
    final Int64 b = (rng.nextLong() | Int64.ONE);
    return Int64(minBlockX) * a + Int64(minBlockZ) * b ^ worldSeed;
  }

  /// Vanilla `setFeatureSeed`: mix the decoration seed with the feature index
  /// and the decoration step.
  static Int64 featureSeed(Int64 decorationSeed, int index, int step) {
    final Int64 mixed =
        decorationSeed + Int64(index) * _decoA + Int64(step) * _decoB;
    return mixed;
  }

  /// Compute every ore vein of [feature] inside the chunk (chunkX, chunkZ),
  /// seeded by [worldSeed]. [featureIndex] and [step] disambiguate this feature
  /// within the chunk's decoration order (defaults match the first ore feature
  /// in the underground-ores step).
  static List<OreVein> veinsInChunk({
    required Int64 worldSeed,
    required int chunkX,
    required int chunkZ,
    required OreFeature feature,
    int featureIndex = 0,
    int step = 0,
  }) {
    final int minBlockX = JavaPlacement.chunkToBlock(chunkX);
    final int minBlockZ = JavaPlacement.chunkToBlock(chunkZ);
    final Int64 deco = decorationSeed(worldSeed, minBlockX, minBlockZ);
    final Int64 fseed = featureSeed(deco, featureIndex, step);
    final rng = JavaRandomInt64(fseed);

    final out = <OreVein>[];
    final int yRange = feature.maxY - feature.minY + 1;
    for (int c = 0; c < feature.countPerChunk; c++) {
      // Each placement: a random in-chunk column and a Y in range.
      final int localX = rng.nextInt(16);
      final int localZ = rng.nextInt(16);
      final int y = feature.minY + (yRange > 0 ? rng.nextInt(yRange) : 0);

      // Vein size: uniform over [minVeinSize, maxVeinSize], then grown by the
      // feature's inner `tries` (each try can enlarge the vein by one block,
      // bounded by maxVeinSize).
      final int span = feature.maxVeinSize - feature.minVeinSize + 1;
      int size = feature.minVeinSize + (span > 0 ? rng.nextInt(span) : 0);
      for (int t = 0; t < feature.tries; t++) {
        if (size < feature.maxVeinSize && rng.nextFloat() < 0.5) {
          size++;
        } else {
          // Consume the draw anyway so the stream stays aligned.
          rng.nextFloat();
        }
      }
      if (size < 1) size = 1;

      out.add(OreVein(
        x: minBlockX + localX,
        y: y,
        z: minBlockZ + localZ,
        size: size,
      ));
    }
    return out;
  }

  /// All ore veins of [feature] within the block search window around
  /// (centerX, centerZ) with the given [radius]. Veins are returned sorted by
  /// distance from the search centre.
  static List<OreVein> veinsInRange({
    required Int64 worldSeed,
    required int centerX,
    required int centerZ,
    required int radius,
    required OreFeature feature,
    int featureIndex = 0,
    int step = 0,
  }) {
    final int minChunkX = JavaPlacement.blockToChunk(centerX - radius);
    final int maxChunkX = JavaPlacement.blockToChunk(centerX + radius);
    final int minChunkZ = JavaPlacement.blockToChunk(centerZ - radius);
    final int maxChunkZ = JavaPlacement.blockToChunk(centerZ + radius);

    final out = <OreVein>[];
    for (int cx = minChunkX; cx <= maxChunkX; cx++) {
      for (int cz = minChunkZ; cz <= maxChunkZ; cz++) {
        final veins = veinsInChunk(
          worldSeed: worldSeed,
          chunkX: cx,
          chunkZ: cz,
          feature: feature,
          featureIndex: featureIndex,
          step: step,
        );
        for (final v in veins) {
          if ((v.x - centerX).abs() > radius) continue;
          if ((v.z - centerZ).abs() > radius) continue;
          out.add(v);
        }
      }
    }
    out.sort((a, b) {
      final da = (a.x - centerX) * (a.x - centerX) + (a.z - centerZ) * (a.z - centerZ);
      final db = (b.x - centerX) * (b.x - centerX) + (b.z - centerZ) * (b.z - centerZ);
      return da.compareTo(db);
    });
    return out;
  }
}
