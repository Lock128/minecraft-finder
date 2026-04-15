import 'game_random.dart';

/// Bedrock Edition-compatible RNG using the MT19937 (32-bit Mersenne Twister)
/// algorithm, replicating the C++ `std::mt19937` used by Bedrock Minecraft.
class BedrockRandom implements GameRandom {
  // MT19937 constants
  static const int _n = 624;
  static const int _m = 397;
  static const int _matrixA = 0x9908B0DF;
  static const int _upperMask = 0x80000000;
  static const int _lowerMask = 0x7FFFFFFF;

  // Tempering constants
  static const int _temperU = 11;
  static const int _temperS = 7;
  static const int _temperB = 0x9D2C5680;
  static const int _temperT = 15;
  static const int _temperC = 0xEFC60000;
  static const int _temperL = 18;

  /// 624-element state array (32-bit words stored in 64-bit Dart ints, masked).
  final List<int> _mt = List<int>.filled(_n, 0);

  /// Index into the state array.
  int _mti = _n + 1;

  BedrockRandom(int seed) {
    setSeed(seed);
  }

  @override
  void setSeed(int seed) {
    _mt[0] = seed & 0xFFFFFFFF;
    for (_mti = 1; _mti < _n; _mti++) {
      _mt[_mti] =
          (1812433253 * (_mt[_mti - 1] ^ (_mt[_mti - 1] >> 30)) + _mti) &
              0xFFFFFFFF;
    }
  }

  /// Generate the next 624 words of the state array (the "twist" step).
  void _generateNumbers() {
    for (int i = 0; i < _n; i++) {
      final int y = (_mt[i] & _upperMask) | (_mt[(i + 1) % _n] & _lowerMask);
      _mt[i] = _mt[(i + _m) % _n] ^ (y >> 1);
      if (y & 1 != 0) {
        _mt[i] = _mt[i] ^ _matrixA;
      }
    }
    _mti = 0;
  }

  /// Extract a tempered 32-bit unsigned integer from the state.
  int _nextUint32() {
    if (_mti >= _n) {
      _generateNumbers();
    }

    int y = _mt[_mti++];
    // Tempering
    y = y ^ (y >> _temperU);
    y = y ^ ((y << _temperS) & _temperB);
    y = y ^ ((y << _temperT) & _temperC);
    y = y ^ (y >> _temperL);

    return y & 0xFFFFFFFF;
  }

  @override
  int nextInt(int bound) {
    if (bound <= 0) {
      throw ArgumentError('bound must be positive');
    }

    // Rejection sampling to avoid modulo bias.
    // Compute the largest multiple of bound that fits in 32 bits.
    final int limit = (0x100000000 ~/ bound) * bound;
    int r;
    do {
      r = _nextUint32();
    } while (r >= limit);
    return r % bound;
  }

  @override
  int nextLong() {
    final int high = _nextUint32();
    final int low = _nextUint32();
    return (high << 32) | low;
  }

  @override
  double nextDouble() {
    // Use full 32-bit value scaled to [0.0, 1.0)
    return _nextUint32() / 4294967296.0; // 2^32
  }

  @override
  double nextFloat() {
    // Use full 32-bit value scaled to [0.0, 1.0)
    return _nextUint32() / 4294967296.0; // 2^32
  }

  @override
  bool nextBool() {
    return (_nextUint32() & 1) != 0;
  }
}
