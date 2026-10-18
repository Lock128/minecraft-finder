import 'package:fixnum/fixnum.dart';

/// Web-safe mirror of `java.util.Random` (and the native [JavaRandom]) that
/// performs all 48-bit seed/state arithmetic with [Int64] from
/// `package:fixnum`.
///
/// Minecraft RNG relies on 64-bit two's-complement overflow. On native Dart
/// `int` is 64-bit and wraps correctly, but on the web Dart `int` is a JS
/// `double` and loses precision above 2^53, so the plain [JavaRandom] silently
/// diverges in the browser. This class keeps every state operation in [Int64]
/// and only converts *reduced* results (which provably fit in 2^53) to Dart
/// `int`, so its stream matches `java.util.Random` exactly on every platform.
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
class JavaRandomInt64 {
  Int64 _seed;

  static final Int64 _mult = Int64.parseHex('5DEECE66D');
  static final Int64 _mask = (Int64.ONE << 48) - Int64.ONE;
  static final Int64 _inc = Int64(0xB);

  /// Construct from a 64-bit seed. Mirrors `java.util.Random(long seed)`'s
  /// scramble: `(seed ^ 0x5DEECE66D) & ((1 << 48) - 1)`.
  JavaRandomInt64(Int64 seed) : _seed = (seed ^ _mult) & _mask;

  /// Convenience constructor from a Dart `int` seed (safe on native; on the
  /// web only use this when the seed itself fits in 2^53).
  JavaRandomInt64.fromInt(int seed) : this(Int64(seed));

  /// Re-seed (mirrors `Random.setSeed`).
  void setSeed(Int64 seed) {
    _seed = (seed ^ _mult) & _mask;
  }

  /// Core generator: advance the 48-bit state and return the top [bits] bits.
  ///
  /// Returned value is at most 32 bits, so it fits in 2^53 and converts to a
  /// Dart `int` without precision loss.
  int _next(int bits) {
    _seed = (_seed * _mult + _inc) & _mask;
    return (_seed >> (48 - bits)).toInt();
  }

  /// Mirror of `java.util.Random.nextInt(int bound)`.
  int nextInt(int bound) {
    if (bound <= 0) {
      throw ArgumentError('bound must be positive');
    }

    // Power of two: use the high bits directly.
    if ((bound & -bound) == bound) {
      final Int64 m = Int64(bound);
      return ((m * Int64(_next(31))) >> 31).toInt();
    }

    int bits, val;
    do {
      bits = _next(31);
      val = bits % bound;
    } while (bits - val + (bound - 1) < 0);
    return val;
  }

  /// Mirror of `java.util.Random.nextLong()`. Returns a full 64-bit value as
  /// an [Int64] because the result does NOT generally fit in a Dart web `int`.
  Int64 nextLong() {
    final Int64 hi = Int64(_next(32));
    final Int64 lo = Int64(_next(32));
    return (hi << 32) + lo;
  }

  /// Mirror of `java.util.Random.nextFloat()` in `[0.0, 1.0)`.
  double nextFloat() {
    return _next(24) / (1 << 24);
  }

  /// Mirror of `java.util.Random.nextDouble()` in `[0.0, 1.0)`.
  double nextDouble() {
    final int hi = _next(26);
    final int lo = _next(27);
    // (hi << 27) + lo is at most 53 bits, which fits exactly in a double.
    final Int64 mantissa = (Int64(hi) << 27) + Int64(lo);
    return mantissa.toDouble() / (Int64.ONE << 53).toDouble();
  }

  /// Mirror of `java.util.Random.nextBoolean()`.
  bool nextBool() {
    return _next(1) != 0;
  }
}
