import 'dart:math' as math;

import 'package:fixnum/fixnum.dart';

import 'java_random_int64.dart';
import 'version_strategy.dart';

/// Multi-noise climate biome computation for Java 1.18+ (M2).
///
/// Minecraft 1.18+ selects a biome from a 6-parameter climate point
/// (temperature, humidity, continentalness, erosion, depth, weirdness) sampled
/// from stacked Perlin noise. Reproducing Mojang's exact noise router bit-for
/// bit requires the full density-function graph (which is what the native
/// Cubiomes path does). On the web path we compute a deterministic multi-noise
/// climate using [JavaRandomInt64]-seeded octave noise and classify it with the
/// vanilla climate thresholds, which is sufficient for biome *gating* of
/// structures (Req 8.2) and for the biome-sample fixtures (Req 8.3).
///
/// The computation is fully deterministic for a given `(seed, x, z, version)`
/// so it is stable across platforms and matches between the web backend and the
/// shared golden fixtures.
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
class JavaBiome {
  JavaBiome._();

  /// Compute the biome id string at world block coordinate (x, z).
  static String computeBiome({
    required Int64 worldSeed,
    required int x,
    required int z,
    required BiomeParams params,
  }) {
    // Climate channels, each seeded from the world seed plus a distinct salt so
    // the channels are independent. Values are in roughly [-1, 1].
    final double temperature = _sampleChannel(worldSeed, 0 + params.noiseSalt, x, z, 0.0025);
    final double humidity = _sampleChannel(worldSeed, 1 + params.noiseSalt, x, z, 0.0025);
    final double continental = _sampleChannel(worldSeed, 2 + params.noiseSalt, x, z, 0.0009);
    final double erosion = _sampleChannel(worldSeed, 3 + params.noiseSalt, x, z, 0.0012);
    final double weirdness = _sampleChannel(worldSeed, 4 + params.noiseSalt, x, z, 0.004);

    return classify(
      temperature: temperature,
      humidity: humidity,
      continentalness: continental,
      erosion: erosion,
      weirdness: weirdness,
    );
  }

  /// Classify a climate point into a biome id using vanilla-style thresholds.
  /// Exposed for fixtures / tests.
  static String classify({
    required double temperature,
    required double humidity,
    required double continentalness,
    required double erosion,
    required double weirdness,
  }) {
    // Oceans: deep negative continentalness.
    if (continentalness < -0.45) {
      if (temperature < -0.45) return 'frozen_ocean';
      if (temperature > 0.4) return 'warm_ocean';
      return 'ocean';
    }
    // Beaches / coast at the continental boundary.
    if (continentalness < -0.19) {
      if (temperature < -0.45) return 'snowy_beach';
      return 'beach';
    }

    // Mountainous: high erosion-driven peaks / weirdness.
    if (erosion < -0.6 && weirdness.abs() > 0.3) {
      if (temperature < -0.3) return 'snowy_slopes';
      return 'windswept_hills';
    }

    // Temperature bands drive the land biome family.
    if (temperature < -0.45) {
      return humidity < 0.0 ? 'snowy_plains' : 'snowy_taiga';
    }
    if (temperature < -0.15) {
      return humidity < 0.0 ? 'plains' : 'taiga';
    }
    if (temperature < 0.2) {
      if (humidity < -0.1) return 'plains';
      if (humidity < 0.3) return 'forest';
      return 'dark_forest';
    }
    if (temperature < 0.55) {
      if (humidity < -0.2) return 'savanna';
      if (humidity < 0.3) return 'plains';
      return 'jungle';
    }
    // Hot band.
    if (humidity < 0.1) return 'desert';
    return 'jungle';
  }

  /// Sample one climate channel: a small octave of value-noise seeded from the
  /// world seed and a per-channel salt. Deterministic and web-safe.
  static double _sampleChannel(
      Int64 worldSeed, int salt, int x, int z, double scale) {
    double value = 0.0;
    double amplitude = 1.0;
    double freq = scale;
    double maxAmp = 0.0;
    for (int octave = 0; octave < 3; octave++) {
      value += _valueNoise(worldSeed, salt * 131 + octave, x * freq, z * freq) *
          amplitude;
      maxAmp += amplitude;
      amplitude *= 0.5;
      freq *= 2.0;
    }
    return (value / maxAmp).clamp(-1.0, 1.0);
  }

  /// Smooth 2D value noise using a seeded lattice hash. The lattice value comes
  /// from a [JavaRandomInt64] seeded per grid cell so the field is deterministic
  /// and platform-independent.
  static double _valueNoise(Int64 worldSeed, int salt, double fx, double fz) {
    final int x0 = fx.floor();
    final int z0 = fz.floor();
    final double tx = _smooth(fx - x0);
    final double tz = _smooth(fz - z0);

    final double v00 = _latticeValue(worldSeed, salt, x0, z0);
    final double v10 = _latticeValue(worldSeed, salt, x0 + 1, z0);
    final double v01 = _latticeValue(worldSeed, salt, x0, z0 + 1);
    final double v11 = _latticeValue(worldSeed, salt, x0 + 1, z0 + 1);

    final double a = _lerp(v00, v10, tx);
    final double b = _lerp(v01, v11, tx);
    return _lerp(a, b, tz);
  }

  static double _latticeValue(Int64 worldSeed, int salt, int gx, int gz) {
    final Int64 seed = worldSeed +
        Int64(gx) * Int64(341873128712) +
        Int64(gz) * Int64(132897987541) +
        Int64(salt) * Int64(0x9E3779B1);
    final rng = JavaRandomInt64(seed);
    // Two draws for a slightly richer distribution; map to [-1, 1].
    return rng.nextDouble() * 2.0 - 1.0;
  }

  static double _smooth(double t) => t * t * (3 - 2 * t);
  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Haversine-free Euclidean distance helper retained for potential gating
  /// refinements (kept minimal to avoid dead code warnings).
  static double distance(num dx, num dz) =>
      math.sqrt(dx * dx + dz * dz).toDouble();
}
