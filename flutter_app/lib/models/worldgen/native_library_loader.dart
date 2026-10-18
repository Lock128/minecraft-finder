import 'worldgen_engine.dart';

/// Loads the native `mc_finder_ffi` library and exposes its flat API to the
/// [NativeFfiBackend] without leaking `dart:ffi` types into shared code.
///
/// The concrete implementation lives behind a conditional import
/// ([NativeLibraryLoader.platformDefault]): on native platforms it binds to
/// `dart:ffi`; on the web it is a stub that always reports it cannot load. This
/// keeps the web bundle free of any `dart:ffi` dependency.
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
abstract interface class NativeLibraryLoader {
  /// Whether the native library is available on this platform/build.
  bool get isAvailable;

  /// Attempt to open the library and resolve the shim symbols. Throws when the
  /// library cannot be opened or a symbol is missing; [NativeFfiBackend]
  /// converts that into [EngineUnavailable] ([FallbackReason.ffiLoadFailure]).
  NativeWorldGen load();
}

/// The resolved native entry points used by [NativeFfiBackend]. Returns lists
/// of plain records (primitives) so no `dart:ffi` type crosses back into shared
/// code or the isolate boundary.
abstract interface class NativeWorldGen {
  /// Returns structure hits as `(chunkX, chunkZ, blockX, blockY, blockZ,
  /// biome)` records within [radius] blocks of the center.
  List<NativeStructureHit> findStructures({
    required int worldSeed,
    required int structureType,
    required int centerX,
    required int centerZ,
    required int radius,
    required int spacing,
    required int separation,
    required int salt,
    required int maxOut,
  });

  /// Returns ore hits as `(blockX, blockY, blockZ, veinSize)` records within
  /// [radius] blocks of the center.
  List<NativeOreHit> findOres({
    required int worldSeed,
    required int oreType,
    required int centerX,
    required int centerY,
    required int centerZ,
    required int radius,
    required int countPerChunk,
    required int tries,
    required int minY,
    required int maxY,
    required int minVein,
    required int maxVein,
    required int decorationSalt,
    required int maxOut,
  });

  /// Returns the biome id at a block coordinate.
  int getBiome(int worldSeed, int blockX, int blockZ);
}

/// Plain structure placement result marshalled out of native code.
class NativeStructureHit {
  const NativeStructureHit({
    required this.chunkX,
    required this.chunkZ,
    required this.blockX,
    required this.blockY,
    required this.blockZ,
    required this.biome,
  });

  final int chunkX;
  final int chunkZ;
  final int blockX;
  final int blockY;
  final int blockZ;
  final int biome;
}

/// Plain ore placement result marshalled out of native code.
class NativeOreHit {
  const NativeOreHit({
    required this.blockX,
    required this.blockY,
    required this.blockZ,
    required this.veinSize,
  });

  final int blockX;
  final int blockY;
  final int blockZ;
  final int veinSize;
}
