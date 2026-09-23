import 'noise.dart';

/// Shared biome classifier — the single source of truth for mapping
/// (x, z, worldSeed) to a biome string.
///
/// Both [OreFinder] and [StructureFinder] delegate to this class so their
/// biome assignments stay identical. Historically each finder carried its own
/// copy of `_getBiomeType` and they drifted (the round-1 biomes
/// `dappled_forest`/`cherry_grove` existed only in the structure finder).
/// Centralising the thresholds here removes that drift risk: change the map in
/// one place and both callers move together.
///
/// The classifier uses a temperature × humidity multi-noise model (Perlin
/// noise at scale 0.005, ~200-block regions) that approximates modern
/// Minecraft world generation. Special dimensions/biomes (nether, end,
/// deep_dark) are injected by callers during probability calculation, not
/// produced here.
class BiomeClassifier {
  /// Perlin noise instances, cached per world-seed to avoid rebuilding the
  /// permutation tables on every coordinate evaluation. The noise is seeded
  /// purely from the world seed (fresh JavaRandom via [PerlinNoise]) so the
  /// classification is deterministic and edition-independent, guaranteeing that
  /// every caller sees the same biome for the same (x, z, seed).
  PerlinNoise? _tempNoise;
  PerlinNoise? _humidNoise;
  int? _biomeSeed;

  void _ensureNoise(int worldSeed) {
    if (_biomeSeed != worldSeed) {
      _tempNoise = PerlinNoise(worldSeed + 1000);
      _humidNoise = PerlinNoise(worldSeed + 2000);
      _biomeSeed = worldSeed;
    }
  }

  /// Sampling scale — ~200-block biome regions.
  static const double scale = 0.005;

  /// Classify the surface biome at (x, z) for [worldSeed].
  ///
  /// Threshold map (temperature bands, then humidity within each band):
  ///   temp < -0.5                     : humidity<0 -> taiga, else swamp
  ///   temp < -0.1 (cool-temperate)    : mountains / forest / dappled_forest /
  ///                                     cherry_grove / jungle
  ///   temp < 0.3  (temperate)         : plains / savanna, then a water strip
  ///                                     split into beach / ocean / deep_ocean
  ///   otherwise (hot)                 : desert / badlands
  ///
  /// Water handling (modern world-gen currency): the slice that used to return
  /// a single 'ocean' is subdivided by humidity into a thin 'beach' transition,
  /// 'ocean', and the most-humid 'deep_ocean'. The three together cover exactly
  /// the same area the single 'ocean' band used to, so ocean-dependent
  /// structures do not lose eligible area (their eligibility lists are widened
  /// to accept the new categories in StructureFinder).
  String classify(int x, int z, int worldSeed) {
    _ensureNoise(worldSeed);

    final double temperature =
        _tempNoise!.octaveNoise3D(x * scale, 0, z * scale, 3, 0.5, 1.0);
    final double humidity =
        _humidNoise!.octaveNoise3D(x * scale, 0, z * scale, 3, 0.5, 1.0);

    if (temperature < -0.5) {
      return humidity < 0 ? 'taiga' : 'swamp';
    } else if (temperature < -0.1) {
      // Cool-temperate band, adjacent to the cold (taiga/swamp) band above.
      // Third Drop 2026: 'dappled_forest' is an autumn forest that generates
      // near cold biomes, and cherry groves sit alongside it. We carve both
      // out of the humid slice of this band that would otherwise be forest,
      // so they occur with a realistic (non-vanishing) frequency while leaving
      // the mountains/jungle edges of the band unchanged.
      if (humidity < -0.3) return 'mountains';
      if (humidity < 0.0) return 'forest';
      if (humidity < 0.15) return 'dappled_forest';
      if (humidity < 0.3) return 'cherry_grove';
      return 'jungle';
    } else if (temperature < 0.3) {
      if (humidity < -0.3) return 'plains';
      if (humidity < 0.3) return 'savanna';
      // Water strip (humidity >= 0.3), previously all 'ocean'. Subdivide by
      // humidity, keeping total area identical:
      //   [0.3, 0.35) -> beach       (thin coastal transition)
      //   [0.35, 0.5) -> ocean       (shallow ocean)
      //   [0.5,  1.0] -> deep_ocean  (ocean monuments require deep ocean)
      if (humidity < 0.35) return 'beach';
      if (humidity < 0.5) return 'ocean';
      return 'deep_ocean';
    } else {
      return humidity < 0 ? 'desert' : 'badlands';
    }
  }
}
