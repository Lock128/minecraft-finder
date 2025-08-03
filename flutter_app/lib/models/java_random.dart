/// Java-compatible Random implementation for Minecraft seed analysis
class JavaRandom {
  late int _seed;

  JavaRandom(int seed) {
    _seed = (seed ^ 0x5DEECE66D) & ((1 << 48) - 1);
  }

  /// Set the seed (used for re-seeding)
  void setSeed(int seed) {
    _seed = (seed ^ 0x5DEECE66D) & ((1 << 48) - 1);
  }

  /// Generate next random bits
  int _next(int bits) {
    _seed = ((_seed * 0x5DEECE66D + 0xB) & ((1 << 48) - 1));
    return (_seed >> (48 - bits));
  }

  /// Generate random integer in range [0, bound)
  int nextInt(int bound) {
    if (bound <= 0) {
      throw ArgumentError('bound must be positive');
    }

    if ((bound & -bound) == bound) {
      // bound is a power of 2
      return (bound * _next(31)) >> 31;
    }

    int bits, val;
    do {
      bits = _next(31);
      val = bits % bound;
    } while (bits - val + (bound - 1) < 0);

    return val;
  }

  /// Generate random long
  int nextLong() {
    return (_next(32) << 32) + _next(32);
  }

  /// Generate random double [0.0, 1.0)
  double nextDouble() {
    return ((_next(26) << 27) + _next(27)) / (1 << 53);
  }

  /// Generate random boolean
  bool nextBool() {
    return _next(1) != 0;
  }

  /// Generate random float [0.0, 1.0)
  double nextFloat() {
    return _next(24) / (1 << 24);
  }
}

/// Utility class for Minecraft-specific random operations
class MinecraftRandom {
  /// Convert string seed to long using Java's String.hashCode()
  static int stringToSeed(String seedStr) {
    if (seedStr.isEmpty) return 0;

    // Try to parse as number first
    int? numericSeed = int.tryParse(seedStr);
    if (numericSeed != null) {
      return numericSeed;
    }

    // Use Java's String.hashCode() algorithm
    int hash = 0;
    for (int i = 0; i < seedStr.length; i++) {
      hash = 31 * hash + seedStr.codeUnitAt(i);
      // Keep within 32-bit signed integer range
      hash = ((hash << 32) >> 32); // Sign extend to handle overflow
    }
    return hash;
  }

  /// Create seeded random for chunk coordinates
  static JavaRandom createChunkRandom(int worldSeed, int chunkX, int chunkZ) {
    JavaRandom random = JavaRandom(worldSeed);
    int chunkSeed = random.nextLong();
    random.setSeed(chunkSeed);

    // Mix in chunk coordinates
    int mixedSeed = chunkSeed ^ (chunkX * 341873128 + chunkZ * 132897987);
    return JavaRandom(mixedSeed);
  }

  /// Create seeded random for ore generation at specific coordinates
  static JavaRandom createOreRandom(
      int worldSeed, int x, int y, int z, String oreType) {
    // Use a different salt for each ore type to avoid correlation
    int oreSalt = oreType.hashCode;
    int seed =
        worldSeed ^ (x * 341873128 + z * 132897987 + y * 268582165 + oreSalt);
    return JavaRandom(seed);
  }
}
