import '../game_random.dart';
import '../ore_location.dart';
import '../structure_location.dart';
import 'minecraft_version.dart';
import 'version_strategy.dart';

/// Concrete [VersionStrategy] for Bedrock Edition.
///
/// Bedrock reuses the same region-grid / stronghold / ore-feature *structure*
/// of the Java tables, but computes placement with the MT19937 RNG
/// ([BedrockRandom]) rather than the Java 48-bit LCG. That difference is
/// captured by [RngParams.usesMt19937] = true; the [BedrockPlacement] /
/// [BedrockBackend] honour it. The placement spacing/separation/salt values
/// below mirror the Bedrock parity values for the common structures.
///
/// The Bedrock placement constants are not published the way Java's
/// data-driven `StructureSet`s are, so the golden fixtures for Bedrock are
/// algorithm-derived and the version is registered Supported-but-NOT-Verified
/// (Accurate still degrades to Simulated per Req 5.2 until an authoritative
/// reference confirms the constants).
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
class BedrockVersionStrategy implements VersionStrategy {
  BedrockVersionStrategy({required this.version});

  @override
  final MinecraftVersion version;

  @override
  MinecraftEdition get edition => MinecraftEdition.bedrock;

  @override
  StructurePlacement placementFor(StructureType type) {
    final p = _placements[type];
    if (p != null) return p;
    return StructurePlacement(spacing: 32, separation: 8, salt: type.index);
  }

  @override
  StrongholdRingConfig get strongholdRings => _strongholdRings;

  @override
  BiomeParams get biomeParams => _biomeParams;

  @override
  OreFeature oreFeatureFor(OreType ore) {
    final f = _oreFeatures[ore];
    if (f != null) return f;
    final vein = oreVeinSizes[ore];
    return OreFeature(
      countPerChunk: 1,
      tries: 1,
      minY: -64,
      maxY: 320,
      minVeinSize: vein?[0] ?? 1,
      maxVeinSize: vein?[1] ?? 8,
    );
  }

  @override
  RngParams get rngParams => _rngParams;

  /// Build the Bedrock 1.21 strategy.
  factory BedrockVersionStrategy.bedrock121() =>
      BedrockVersionStrategy(version: const MinecraftVersion('bedrock-1.21'));

  // ---------------------------------------------------------------------------
  // Bedrock placement tables. The spacing/separation mirror the Bedrock parity
  // values for the common structures; the per-type salt distinguishes the
  // MT19937 seed per structure set.
  // ---------------------------------------------------------------------------

  static Map<StructureType, StructurePlacement> get _placements => const {
        StructureType.village:
            StructurePlacement(spacing: 27, separation: 10, salt: 10387312),
        StructureType.desertTemple:
            StructurePlacement(spacing: 32, separation: 8, salt: 14357617),
        StructureType.jungleTemple:
            StructurePlacement(spacing: 32, separation: 8, salt: 14357619),
        StructureType.witchHut:
            StructurePlacement(spacing: 32, separation: 8, salt: 14357620),
        StructureType.pillagerOutpost:
            StructurePlacement(spacing: 32, separation: 8, salt: 165745296),
        StructureType.ruinedPortal:
            StructurePlacement(spacing: 40, separation: 15, salt: 34222645),
        StructureType.shipwreck:
            StructurePlacement(spacing: 24, separation: 4, salt: 165745295),
        StructureType.oceanMonument:
            StructurePlacement(spacing: 32, separation: 5, salt: 10387313),
        StructureType.woodlandMansion:
            StructurePlacement(spacing: 80, separation: 20, salt: 10387319),
        StructureType.bastionRemnant:
            StructurePlacement(spacing: 30, separation: 4, salt: 30084232),
        StructureType.netherFortress:
            StructurePlacement(spacing: 30, separation: 4, salt: 30084232),
        StructureType.endCity:
            StructurePlacement(spacing: 20, separation: 9, salt: 10387313),
      };

  static const StrongholdRingConfig _strongholdRings =
      StrongholdRingConfig(count: 128, distance: 128, spread: 3);

  /// Bedrock 1.18+ also uses a multi-noise climate model.
  static const BiomeParams _biomeParams =
      BiomeParams(hasMultiNoise: true, noiseSalt: 200);

  /// Ore feature table for Bedrock (cave-and-cliffs distribution, matching the
  /// 1.18+ Y ranges / counts shared with Java).
  static Map<OreType, OreFeature> get _oreFeatures => const {
        OreType.diamond: OreFeature(
          countPerChunk: 7,
          tries: 4,
          minY: -64,
          maxY: 16,
          minVeinSize: 1,
          maxVeinSize: 8,
        ),
        OreType.gold: OreFeature(
          countPerChunk: 4,
          tries: 4,
          minY: -64,
          maxY: 32,
          minVeinSize: 1,
          maxVeinSize: 9,
        ),
        OreType.netherite: OreFeature(
          countPerChunk: 2,
          tries: 2,
          minY: 8,
          maxY: 22,
          minVeinSize: 1,
          maxVeinSize: 3,
        ),
        OreType.redstone: OreFeature(
          countPerChunk: 4,
          tries: 4,
          minY: -64,
          maxY: 15,
          minVeinSize: 1,
          maxVeinSize: 10,
        ),
        OreType.iron: OreFeature(
          countPerChunk: 10,
          tries: 4,
          minY: -24,
          maxY: 56,
          minVeinSize: 1,
          maxVeinSize: 13,
        ),
        OreType.coal: OreFeature(
          countPerChunk: 20,
          tries: 4,
          minY: 0,
          maxY: 192,
          minVeinSize: 1,
          maxVeinSize: 17,
        ),
        OreType.lapis: OreFeature(
          countPerChunk: 2,
          tries: 4,
          minY: -32,
          maxY: 32,
          minVeinSize: 1,
          maxVeinSize: 7,
        ),
        OreType.copper: OreFeature(
          countPerChunk: 16,
          tries: 4,
          minY: -16,
          maxY: 112,
          minVeinSize: 1,
          maxVeinSize: 20,
        ),
        OreType.emerald: OreFeature(
          countPerChunk: 100,
          tries: 1,
          minY: -16,
          maxY: 320,
          minVeinSize: 1,
          maxVeinSize: 1,
        ),
      };

  static const RngParams _rngParams =
      RngParams(usesMt19937: true, decorationSalt: 0);
}
