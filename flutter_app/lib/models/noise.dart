import 'dart:math';
import 'java_random.dart';

/// Perlin noise implementation using Java-compatible RNG for permutation table
class PerlinNoise {
  final List<int> _permutation;

  PerlinNoise(int seed) : _permutation = _generatePermutation(seed);

  static List<int> _generatePermutation(int seed) {
    // Use Java-compatible random for permutation to match Minecraft's noise
    JavaRandom random = JavaRandom(seed);
    List<int> p = List.generate(256, (i) => i);

    // Fisher-Yates shuffle using Java RNG
    for (int i = 255; i > 0; i--) {
      int j = random.nextInt(i + 1);
      int temp = p[i];
      p[i] = p[j];
      p[j] = temp;
    }

    // Duplicate the permutation array
    return [...p, ...p];
  }

  double _fade(double t) {
    return t * t * t * (t * (t * 6 - 15) + 10);
  }

  double _lerp(double t, double a, double b) {
    return a + t * (b - a);
  }

  double _grad(int hash, double x, double y, double z) {
    int h = hash & 15;
    double u = h < 8 ? x : y;
    double v = h < 4 ? y : (h == 12 || h == 14 ? x : z);
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
  }

  /// Generate 3D Perlin noise value at given coordinates
  double noise3D(double x, double y, double z) {
    int X = (x.floor()) & 255;
    int Y = (y.floor()) & 255;
    int Z = (z.floor()) & 255;

    x -= x.floor();
    y -= y.floor();
    z -= z.floor();

    double u = _fade(x);
    double v = _fade(y);
    double w = _fade(z);

    int a = _permutation[X] + Y;
    int aa = _permutation[a] + Z;
    int ab = _permutation[a + 1] + Z;
    int b = _permutation[X + 1] + Y;
    int ba = _permutation[b] + Z;
    int bb = _permutation[b + 1] + Z;

    return _lerp(
        w,
        _lerp(
            v,
            _lerp(u, _grad(_permutation[aa], x, y, z),
                _grad(_permutation[ba], x - 1, y, z)),
            _lerp(u, _grad(_permutation[ab], x, y - 1, z),
                _grad(_permutation[bb], x - 1, y - 1, z))),
        _lerp(
            v,
            _lerp(u, _grad(_permutation[aa + 1], x, y, z - 1),
                _grad(_permutation[ba + 1], x - 1, y, z - 1)),
            _lerp(u, _grad(_permutation[ab + 1], x, y - 1, z - 1),
                _grad(_permutation[bb + 1], x - 1, y - 1, z - 1))));
  }

  /// Generate octave noise (multiple frequencies combined)
  double octaveNoise3D(double x, double y, double z, int octaves,
      double persistence, double scale) {
    double value = 0;
    double amplitude = 1;
    double frequency = scale;
    double maxValue = 0;

    for (int i = 0; i < octaves; i++) {
      value +=
          noise3D(x * frequency, y * frequency, z * frequency) * amplitude;
      maxValue += amplitude;
      amplitude *= persistence;
      frequency *= 2;
    }

    return value / maxValue;
  }
}

/// Triangular distribution helper used by Minecraft 1.18+ ore placement.
/// Returns a value between 0.0 and 1.0 representing spawn probability
/// based on distance from the peak Y level within [minY, maxY].
double _triangularFactor(double y, double minY, double maxY) {
  double peak = (minY + maxY) / 2.0;
  double halfRange = (maxY - minY) / 2.0;
  if (halfRange <= 0) return 0.0;
  double dist = (y - peak).abs();
  return max(0.0, 1.0 - dist / halfRange);
}

/// Triangular distribution with an explicit peak (not necessarily centered).
double _triangularFactorWithPeak(double y, double minY, double maxY, double peak) {
  if (y < minY || y > maxY) return 0.0;
  if (y <= peak) {
    double range = peak - minY;
    return range > 0 ? (y - minY) / range : 1.0;
  } else {
    double range = maxY - peak;
    return range > 0 ? (maxY - y) / range : 1.0;
  }
}

/// Uniform distribution helper — returns 1.0 if y is within [minY, maxY].
double _uniformFactor(double y, double minY, double maxY) {
  return (y >= minY && y <= maxY) ? 1.0 : 0.0;
}

/// Density functions for ore generation modeled after Minecraft 1.18+ distributions.
///
/// Each ore type uses the correct combination of triangular / uniform placements
/// as documented on the Minecraft Wiki for Java Edition 1.18+.
class DensityFunction {
  final PerlinNoise _noise;

  DensityFunction(int seed) : _noise = PerlinNoise(seed);

  /// Calculate ore density at given coordinates
  double getOreDensity(double x, double y, double z, String oreType) {
    switch (oreType) {
      case 'diamond':
        return _getDiamondDensity(x, y, z);
      case 'gold':
        return _getGoldDensity(x, y, z);
      case 'iron':
        return _getIronDensity(x, y, z);
      case 'coal':
        return _getCoalDensity(x, y, z);
      case 'redstone':
        return _getRedstoneDensity(x, y, z);
      case 'netherite':
        return _getNetheriteDensity(x, y, z);
      case 'lapis':
        return _getLapisDensity(x, y, z);
      default:
        return 0.0;
    }
  }

  // ---------------------------------------------------------------------------
  // Diamond: triangular distribution peaking at Y=-64, tapering to Y=16.
  // Minecraft also reduces generation when exposed to air (cave reduction).
  // We approximate air exposure with a secondary noise check.
  // ---------------------------------------------------------------------------
  double _getDiamondDensity(double x, double y, double z) {
    if (y > 16 || y < -64) return 0.0;

    // Triangular peak at Y=-64, linearly decreasing to 0 at Y=16
    double yFactor = _triangularFactorWithPeak(y, -64, 16, -64);

    // Air-exposure reduction: use noise to simulate cave proximity.
    // Negative noise values at this scale hint at open spaces (caves).
    double caveNoise =
        _noise.octaveNoise3D(x * 0.04, y * 0.04, z * 0.04, 2, 0.5, 1.0);
    double airReduction = caveNoise < -0.4 ? 0.5 : 1.0; // 50% reduction near caves

    double noise =
        _noise.octaveNoise3D(x * 0.01, y * 0.02, z * 0.01, 3, 0.5, 1.0);
    return max(0.0, (noise + 0.5) * yFactor * airReduction);
  }

  // ---------------------------------------------------------------------------
  // Gold (overworld): triangular distribution peaking at Y=-16 (from -64 to 32).
  // Badlands adds a uniform distribution from Y=32 to Y=256.
  // Nether gold is handled via biome modifier in OreFinder.
  // ---------------------------------------------------------------------------
  double _getGoldDensity(double x, double y, double z) {
    if (y > 256 || y < -64) return 0.0;

    // Primary: triangular peak at Y=-16, range -64 to 32
    double yFactor = _triangularFactorWithPeak(y, -64, 32, -16);

    // Badlands bonus is applied externally via biome modifier,
    // but we still allow the uniform range here so the density isn't zero.
    if (yFactor <= 0.0 && y >= 32 && y <= 256) {
      // Uniform badlands-eligible range (modifier applied in OreFinder)
      yFactor = 0.15; // Low base; biome modifier will boost it
    }

    double noise =
        _noise.octaveNoise3D(x * 0.008, y * 0.015, z * 0.008, 3, 0.6, 1.0);
    return max(0.0, (noise + 0.4) * yFactor);
  }

  // ---------------------------------------------------------------------------
  // Iron: three separate placements combined.
  //   1. Uniform from Y=-64 to Y=72
  //   2. Triangular peaking at Y=16 (from Y=-24 to Y=56)
  //   3. Triangular peaking at Y=232 (from Y=80 to Y=384, clamped to 320)
  // ---------------------------------------------------------------------------
  double _getIronDensity(double x, double y, double z) {
    if (y > 320 || y < -64) return 0.0;

    // Placement 1: uniform -64 to 72
    double uniform = _uniformFactor(y, -64, 72) * 0.4;

    // Placement 2: triangular peak at Y=16, range -24 to 56
    double tri1 = _triangularFactorWithPeak(y, -24, 56, 16);

    // Placement 3: triangular peak at Y=232, range 80 to 320
    double tri2 = _triangularFactorWithPeak(y, 80, 320, 232);

    // Combine — take the max contribution then add the uniform base
    double yFactor = max(tri1, tri2) + uniform;
    yFactor = min(yFactor, 1.4); // Soft cap

    double noise =
        _noise.octaveNoise3D(x * 0.012, y * 0.008, z * 0.012, 4, 0.5, 1.0);
    return max(0.0, (noise + 0.3) * yFactor);
  }

  // ---------------------------------------------------------------------------
  // Coal: triangular distribution peaking at Y=96, from Y=0 to Y=192.
  // (Not Y=256 — the wiki specifies the range ends at 192.)
  // ---------------------------------------------------------------------------
  double _getCoalDensity(double x, double y, double z) {
    if (y > 192 || y < 0) return 0.0;

    double yFactor = _triangularFactorWithPeak(y, 0, 192, 96);

    double noise =
        _noise.octaveNoise3D(x * 0.015, y * 0.01, z * 0.015, 3, 0.6, 1.0);
    return max(0.0, (noise + 0.2) * yFactor);
  }

  // ---------------------------------------------------------------------------
  // Redstone: two placements.
  //   1. Uniform from Y=-64 to Y=-32
  //   2. Triangular peaking at Y=-32 (from Y=-64 to Y=15)
  // ---------------------------------------------------------------------------
  double _getRedstoneDensity(double x, double y, double z) {
    if (y > 15 || y < -64) return 0.0;

    // Placement 1: uniform -64 to -32
    double uniform = _uniformFactor(y, -64, -32) * 0.5;

    // Placement 2: triangular peak at -32, range -64 to 15
    double tri = _triangularFactorWithPeak(y, -64, 15, -32);

    double yFactor = max(uniform, tri);

    double noise =
        _noise.octaveNoise3D(x * 0.009, y * 0.02, z * 0.009, 3, 0.5, 1.0);
    return max(0.0, (noise + 0.3) * yFactor);
  }

  // ---------------------------------------------------------------------------
  // Netherite (Ancient Debris): triangular peaking at Y=15, range 8 to 22.
  // Very sparse — multiplied by a rarity factor.
  // ---------------------------------------------------------------------------
  double _getNetheriteDensity(double x, double y, double z) {
    if (y > 22 || y < 8) return 0.0;

    double yFactor = _triangularFactorWithPeak(y, 8, 22, 15);

    double noise =
        _noise.octaveNoise3D(x * 0.005, y * 0.03, z * 0.005, 2, 0.7, 1.0);
    return max(0.0, (noise + 0.8) * yFactor * 0.3);
  }

  // ---------------------------------------------------------------------------
  // Lapis Lazuli: normal-like (approximated triangular) centered at Y=0,
  // spread from Y=-32 to Y=32 for the primary placement.
  // A secondary uniform placement exists from Y=-64 to Y=64 at lower density.
  // ---------------------------------------------------------------------------
  double _getLapisDensity(double x, double y, double z) {
    if (y > 64 || y < -64) return 0.0;

    // Primary: triangular centered at Y=0, range -32 to 32
    double primary = _triangularFactorWithPeak(y, -32, 32, 0);

    // Secondary: uniform -64 to 64 at reduced density
    double secondary = _uniformFactor(y, -64, 64) * 0.25;

    double yFactor = max(primary, secondary);

    double noise =
        _noise.octaveNoise3D(x * 0.008, y * 0.018, z * 0.008, 3, 0.5, 1.0);
    return max(0.0, (noise + 0.4) * yFactor);
  }
}
