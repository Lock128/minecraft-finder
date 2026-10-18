import '../game_random.dart';
import '../ore_location.dart';
import '../structure_location.dart';
import 'minecraft_version.dart';

/// Encapsulates everything version-specific so the engine core stays
/// version-agnostic. Adding a version means adding a [VersionStrategy] (and a
/// golden fixture set), not editing the engine.
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
abstract interface class VersionStrategy {
  MinecraftVersion get version;
  MinecraftEdition get edition;

  /// Structure placement: region spacing/separation + per-type salt.
  StructurePlacement placementFor(StructureType type);

  /// Stronghold ring count/radii/spread.
  StrongholdRingConfig get strongholdRings;

  /// Biome generation parameters (multi-noise climate for 1.18+).
  BiomeParams get biomeParams;

  /// Ore feature loops: per-chunk count x tries, Y range, vein size.
  OreFeature oreFeatureFor(OreType ore);

  /// RNG configuration: Java LCG vs Bedrock MT19937, decoration salts.
  RngParams get rngParams;
}

/// Region-grid placement parameters for a single structure type.
///
/// Positions come from a region grid: the world is divided into regions of
/// [spacing] chunks; a structure is attempted once per region at an offset
/// bounded by `spacing - separation`, seeded with the per-type [salt].
class StructurePlacement {
  const StructurePlacement({
    required this.spacing,
    required this.separation,
    required this.salt,
  });

  /// Region size in chunks (region spacing).
  final int spacing;

  /// Minimum gap in chunks between structures in adjacent regions.
  final int separation;

  /// Per-type salt mixed into the placement RNG.
  final int salt;
}

/// Stronghold ring placement configuration.
class StrongholdRingConfig {
  const StrongholdRingConfig({
    required this.count,
    required this.distance,
    required this.spread,
  });

  /// Total number of strongholds.
  final int count;

  /// Base ring radius in chunks.
  final int distance;

  /// Radial spread in chunks used when placing each ring.
  final int spread;
}

/// Multi-noise climate biome generation parameters.
class BiomeParams {
  const BiomeParams({
    required this.hasMultiNoise,
    this.noiseSalt = 0,
  });

  /// Whether this version uses the 1.18+ multi-noise climate model.
  final bool hasMultiNoise;

  /// Salt applied to the biome noise seeding.
  final int noiseSalt;
}

/// Ore feature placement parameters for a single ore type.
class OreFeature {
  const OreFeature({
    required this.countPerChunk,
    required this.tries,
    required this.minY,
    required this.maxY,
    required this.minVeinSize,
    required this.maxVeinSize,
  });

  /// Number of feature placements attempted per chunk.
  final int countPerChunk;

  /// Per-feature placement tries.
  final int tries;

  /// Inclusive minimum Y for this ore's distribution.
  final int minY;

  /// Inclusive maximum Y for this ore's distribution.
  final int maxY;

  /// Minimum vein size.
  final int minVeinSize;

  /// Maximum vein size.
  final int maxVeinSize;
}

/// RNG configuration for a version.
class RngParams {
  const RngParams({
    required this.usesMt19937,
    this.decorationSalt = 0,
  });

  /// True for Bedrock (MT19937), false for Java (48-bit LCG).
  final bool usesMt19937;

  /// Decoration salt used when seeding per-chunk feature placement.
  final int decorationSalt;
}
