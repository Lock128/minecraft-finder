import '../game_random.dart';
import '../ore_location.dart';
import '../structure_location.dart';
import 'minecraft_version.dart';
import 'version_strategy.dart';

/// Concrete [VersionStrategy] entries for Java Edition 1.18, 1.19, and 1.20.
///
/// The placement tables below are the real Minecraft Java values:
///
/// * Region-grid structures use the `spacing`/`separation` and per-type `salt`
///   from the vanilla `StructureSet` / `RandomSpreadStructurePlacement`
///   definitions. Those three releases share the same values for the common
///   structures, so one table serves all three; the per-version factory keeps
///   the door open for divergence (e.g. trail ruins land only in later
///   versions) without touching the engine.
/// * Stronghold rings use the vanilla `ConcentricRingsStructurePlacement`
///   values: 128 strongholds spread over 8 rings.
/// * Ore features use the per-chunk `count` and the configured-feature `size`
///   (vein size) and height range from the vanilla ore `PlacedFeature`s for
///   1.18+ (the "new" cave-and-cliffs distribution).
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
class JavaVersionStrategy implements VersionStrategy {
  JavaVersionStrategy({
    required this.version,
    required Map<StructureType, StructurePlacement> placements,
    required StrongholdRingConfig strongholdRings,
    required BiomeParams biomeParams,
    required Map<OreType, OreFeature> oreFeatures,
    required RngParams rngParams,
  })  : _placements = placements,
        _strongholdRings = strongholdRings,
        _biomeParams = biomeParams,
        _oreFeatures = oreFeatures,
        _rngParams = rngParams;

  @override
  final MinecraftVersion version;

  final Map<StructureType, StructurePlacement> _placements;
  final StrongholdRingConfig _strongholdRings;
  final BiomeParams _biomeParams;
  final Map<OreType, OreFeature> _oreFeatures;
  final RngParams _rngParams;

  @override
  MinecraftEdition get edition => MinecraftEdition.java;

  @override
  StructurePlacement placementFor(StructureType type) {
    final p = _placements[type];
    if (p != null) return p;
    // Fallback: a neutral region-grid using the type's index as salt so an
    // unseen structure still produces deterministic, non-crashing output.
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

  // ---------------------------------------------------------------------------
  // Shared vanilla tables for Java 1.18-1.20.
  // ---------------------------------------------------------------------------

  /// Region-grid placement table shared by Java 1.18/1.19/1.20.
  ///
  /// `spacing`/`separation` are in chunks; `salt` is the per-`StructureSet`
  /// salt vanilla mixes into the placement RNG. Values match the Java
  /// `worldgen/structure_set` definitions for these releases.
  static Map<StructureType, StructurePlacement> get _sharedPlacements => const {
        StructureType.village:
            StructurePlacement(spacing: 34, separation: 8, salt: 10387312),
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
            StructurePlacement(spacing: 27, separation: 4, salt: 30084232),
        StructureType.netherFortress:
            StructurePlacement(spacing: 27, separation: 4, salt: 30084232),
        StructureType.endCity:
            StructurePlacement(spacing: 20, separation: 11, salt: 10387313),
        StructureType.ancientCity:
            StructurePlacement(spacing: 24, separation: 8, salt: 20083232),
      };

  /// Vanilla concentric-ring stronghold placement: 128 strongholds, inner ring
  /// radius of 128 chunks, spread of 3 chunks (the `count`/`distance`/`spread`
  /// of `minecraft:strongholds`).
  static const StrongholdRingConfig _sharedStrongholdRings =
      StrongholdRingConfig(count: 128, distance: 128, spread: 3);

  /// Multi-noise climate biome model is used by every 1.18+ release.
  static const BiomeParams _multiNoiseBiomes = BiomeParams(hasMultiNoise: true);

  /// Ore feature table shared by Java 1.18/1.19/1.20 (cave-and-cliffs
  /// distribution). `countPerChunk` is the placed-feature `count`, `tries` the
  /// inner retry count, and `min/maxVeinSize` the configured-feature `size`.
  static Map<OreType, OreFeature> get _sharedOreFeatures => const {
        // Diamond: count 7, size 0-8 (avg ~4), triangle Y -64..16.
        OreType.diamond: OreFeature(
          countPerChunk: 7,
          tries: 4,
          minY: -64,
          maxY: 16,
          minVeinSize: 1,
          maxVeinSize: 8,
        ),
        // Gold: count 4, size 0-9, triangle Y -64..32.
        OreType.gold: OreFeature(
          countPerChunk: 4,
          tries: 4,
          minY: -64,
          maxY: 32,
          minVeinSize: 1,
          maxVeinSize: 9,
        ),
        // Netherite / ancient debris: count 2 (+1), size 0-3, Y 8..22.
        OreType.netherite: OreFeature(
          countPerChunk: 2,
          tries: 2,
          minY: 8,
          maxY: 22,
          minVeinSize: 1,
          maxVeinSize: 3,
        ),
        // Redstone: count 4, size 0-10, Y -64..15.
        OreType.redstone: OreFeature(
          countPerChunk: 4,
          tries: 4,
          minY: -64,
          maxY: 15,
          minVeinSize: 1,
          maxVeinSize: 10,
        ),
        // Iron: count 10, size 0-13, Y -24..56.
        OreType.iron: OreFeature(
          countPerChunk: 10,
          tries: 4,
          minY: -24,
          maxY: 56,
          minVeinSize: 1,
          maxVeinSize: 13,
        ),
        // Coal: count 20, size 0-17, Y 0..192.
        OreType.coal: OreFeature(
          countPerChunk: 20,
          tries: 4,
          minY: 0,
          maxY: 192,
          minVeinSize: 1,
          maxVeinSize: 17,
        ),
        // Lapis: count 2, size 0-7, triangle Y -32..32.
        OreType.lapis: OreFeature(
          countPerChunk: 2,
          tries: 4,
          minY: -32,
          maxY: 32,
          minVeinSize: 1,
          maxVeinSize: 7,
        ),
        // Copper: count 16, size 0-20, triangle Y -16..112.
        OreType.copper: OreFeature(
          countPerChunk: 16,
          tries: 4,
          minY: -16,
          maxY: 112,
          minVeinSize: 1,
          maxVeinSize: 20,
        ),
        // Emerald: count 100 (per-block rarity), size 1, Y -16..320.
        OreType.emerald: OreFeature(
          countPerChunk: 100,
          tries: 1,
          minY: -16,
          maxY: 320,
          minVeinSize: 1,
          maxVeinSize: 1,
        ),
      };

  static const RngParams _javaRngParams =
      RngParams(usesMt19937: false, decorationSalt: 0);

  /// Build the Java 1.18 strategy.
  factory JavaVersionStrategy.java118() => JavaVersionStrategy(
        version: const MinecraftVersion('java-1.18'),
        placements: _sharedPlacements,
        strongholdRings: _sharedStrongholdRings,
        biomeParams: _multiNoiseBiomes,
        oreFeatures: _sharedOreFeatures,
        rngParams: _javaRngParams,
      );

  /// Build the Java 1.19 strategy.
  factory JavaVersionStrategy.java119() => JavaVersionStrategy(
        version: const MinecraftVersion('java-1.19'),
        placements: _sharedPlacements,
        strongholdRings: _sharedStrongholdRings,
        biomeParams: _multiNoiseBiomes,
        oreFeatures: _sharedOreFeatures,
        rngParams: _javaRngParams,
      );

  /// Build the Java 1.20 strategy.
  factory JavaVersionStrategy.java120() => JavaVersionStrategy(
        version: const MinecraftVersion('java-1.20'),
        placements: _sharedPlacements,
        strongholdRings: _sharedStrongholdRings,
        biomeParams: _multiNoiseBiomes,
        oreFeatures: _sharedOreFeatures,
        rngParams: _javaRngParams,
      );
}
