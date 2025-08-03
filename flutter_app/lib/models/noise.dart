import 'dart:math';

/// Simplified Perlin noise implementation for ore distribution
class PerlinNoise {
  final List<int> _permutation;

  PerlinNoise(int seed) : _permutation = _generatePermutation(seed);

  static List<int> _generatePermutation(int seed) {
    Random random = Random(seed);
    List<int> p = List.generate(256, (i) => i);

    // Shuffle the permutation array
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
      value += noise3D(x * frequency, y * frequency, z * frequency) * amplitude;
      maxValue += amplitude;
      amplitude *= persistence;
      frequency *= 2;
    }

    return value / maxValue;
  }
}

/// Density functions for ore generation (simplified version of Minecraft's density functions)
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
      default:
        return 0.0;
    }
  }

  double _getDiamondDensity(double x, double y, double z) {
    if (y > 16 || y < -64) return 0.0;

    // Diamond ore is most common at Y -59 to -53
    double yFactor = 1.0;
    if (y >= -59 && y <= -53) {
      yFactor = 1.0;
    } else if (y >= -64 && y <= -60) {
      yFactor = 0.8;
    } else if (y >= -52 && y <= -48) {
      yFactor = 0.6;
    } else {
      yFactor = 0.3;
    }

    // Add noise for vein-like distribution
    double noise =
        _noise.octaveNoise3D(x * 0.01, y * 0.02, z * 0.01, 3, 0.5, 1.0);
    return (noise + 0.5) * yFactor;
  }

  double _getGoldDensity(double x, double y, double z) {
    if (y > 32 || y < -64) return 0.0;

    // Gold is most common at Y -16 to -48
    double yFactor = 1.0;
    if (y >= -48 && y <= -16) {
      yFactor = 1.0;
    } else if (y >= -64 && y <= -49) {
      yFactor = 0.6;
    } else if (y >= -15 && y <= 32) {
      yFactor = 0.4;
    }

    double noise =
        _noise.octaveNoise3D(x * 0.008, y * 0.015, z * 0.008, 3, 0.6, 1.0);
    return (noise + 0.4) * yFactor;
  }

  double _getIronDensity(double x, double y, double z) {
    if (y > 256 || y < -64) return 0.0;

    double yFactor = 0.0;

    // Two peaks: underground (Y 15) and mountain (Y 232)
    if (y >= -24 && y <= 56) {
      // Underground iron
      double distanceFromPeak = (y - 15).abs();
      yFactor = max(0.0, 1.0 - distanceFromPeak / 40.0);
    }

    if (y >= 128 && y <= 256) {
      // Mountain iron
      double distanceFromPeak = (y - 232).abs();
      double mountainFactor = max(0.0, 1.0 - distanceFromPeak / 64.0);
      yFactor = max(yFactor, mountainFactor);
    }

    double noise =
        _noise.octaveNoise3D(x * 0.012, y * 0.008, z * 0.012, 4, 0.5, 1.0);
    return (noise + 0.3) * yFactor;
  }

  double _getCoalDensity(double x, double y, double z) {
    if (y > 256 || y < 0) return 0.0;

    // Coal peaks at Y 96
    double distanceFromPeak = (y - 96).abs();
    double yFactor = max(0.0, 1.0 - distanceFromPeak / 96.0);

    double noise =
        _noise.octaveNoise3D(x * 0.015, y * 0.01, z * 0.015, 3, 0.6, 1.0);
    return (noise + 0.2) * yFactor;
  }

  double _getRedstoneDensity(double x, double y, double z) {
    if (y > 15 || y < -64) return 0.0;

    // Redstone is most common at Y -64 to -59
    double yFactor = 1.0;
    if (y >= -64 && y <= -59) {
      yFactor = 1.0;
    } else if (y >= -58 && y <= -48) {
      yFactor = 0.8;
    } else if (y >= -47 && y <= -32) {
      yFactor = 0.6;
    } else {
      yFactor = 0.4;
    }

    double noise =
        _noise.octaveNoise3D(x * 0.009, y * 0.02, z * 0.009, 3, 0.5, 1.0);
    return (noise + 0.3) * yFactor;
  }

  double _getNetheriteDensity(double x, double y, double z) {
    if (y > 22 || y < 8) return 0.0;

    // Ancient debris (netherite) is most common at Y 15
    double distanceFromPeak = (y - 15).abs();
    double yFactor = max(0.0, 1.0 - distanceFromPeak / 7.0);

    // Very sparse distribution
    double noise =
        _noise.octaveNoise3D(x * 0.005, y * 0.03, z * 0.005, 2, 0.7, 1.0);
    return max(
        0.0, (noise + 0.8) * yFactor * 0.3); // Much rarer than other ores
  }
}
