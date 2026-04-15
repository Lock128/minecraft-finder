import 'dart:math';
import 'noise.dart';

/// Legacy ore density function for pre-1.18 Minecraft versions.
///
/// Uses uniform distribution within fixed Y ranges per ore type,
/// modulated by Perlin noise for spatial variation. Returns 0.0
/// for Y values outside the valid range.
class LegacyDensityFunction {
  final PerlinNoise _noise;

  /// Legacy Y ranges per ore type: [minY, maxY].
  static const Map<String, List<int>> oreYRanges = {
    'diamond': [1, 15],
    'gold': [1, 31],
    'iron': [1, 63],
    'coal': [1, 127],
    'redstone': [1, 15],
    'lapis': [14, 30],
  };

  /// Creates a LegacyDensityFunction with the given [seed].
  ///
  /// An optional [GameRandom] can be provided for PerlinNoise
  /// permutation table generation. If omitted, PerlinNoise falls
  /// back to JavaRandom (current default behavior).
  LegacyDensityFunction(int seed) : _noise = PerlinNoise(seed);

  /// Calculate ore density at the given coordinates for [oreType].
  ///
  /// Returns a value >= 0.0 representing spawn probability.
  /// Returns 0.0 if [y] is outside the legacy Y range for [oreType]
  /// or if [oreType] is unrecognized.
  double getOreDensity(double x, double y, double z, String oreType) {
    final range = oreYRanges[oreType];
    if (range == null) return 0.0;

    final minY = range[0].toDouble();
    final maxY = range[1].toDouble();

    // Uniform Y-factor: 1.0 inside range, 0.0 outside
    if (y < minY || y > maxY) return 0.0;
    const double yFactor = 1.0;

    // Spatial variation via Perlin noise
    double noise =
        _noise.octaveNoise3D(x * 0.01, y * 0.02, z * 0.01, 3, 0.5, 1.0);

    return max(0.0, (noise + 0.5) * yFactor);
  }
}
