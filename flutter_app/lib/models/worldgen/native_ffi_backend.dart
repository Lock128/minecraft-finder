import '../ore_location.dart';
import '../structure_location.dart';
import 'native_library_loader.dart';
// Conditional import: the FFI loader binds `dart:ffi` on native platforms; the
// stub (no `dart:ffi`) is used on the web so the web bundle stays FFI-free.
import 'native_library_loader_stub.dart'
    if (dart.library.ffi) 'native_library_loader_ffi.dart';
import 'version_strategy.dart';
import 'worldgen_backend.dart';
import 'worldgen_engine.dart';

/// Native [WorldGenBackend] binding the vendored Cubiomes shim through
/// `dart:ffi`.
///
/// The backend lazily loads the native library on first use via an injectable
/// [NativeLibraryLoader]. Any failure to open the library or resolve a symbol
/// (`ArgumentError`, missing-symbol, `open` failure) is caught and surfaced to
/// the engine, which converts it into
/// `EngineUnavailable(FallbackReason.ffiLoadFailure)` rather than crashing the
/// search.
///
/// On the web the conditional import selects a stub loader that reports the
/// library is unavailable, so no `dart:ffi` dependency enters the web bundle.
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
class NativeFfiBackend implements WorldGenBackend {
  /// Creates a backend using the platform's default loader (FFI on native, a
  /// no-op stub on web).
  NativeFfiBackend() : _loader = const PlatformNativeLibraryLoader();

  /// Creates a backend with an injected [loader]; tests use this to simulate
  /// load failures.
  NativeFfiBackend.withLoader(this._loader);

  final NativeLibraryLoader _loader;

  /// Memoised resolved library; null until the first successful [_resolve].
  NativeWorldGen? _native;

  /// Set once a load attempt has failed so we do not retry on every call.
  bool _loadFailed = false;

  /// The backend can run only when the loader reports availability and we have
  /// not already observed a load failure.
  @override
  bool canRun(VersionStrategy strategy) => _loader.isAvailable && !_loadFailed;

  /// Resolve (and memoise) the native entry points. Throws [FfiUnavailable] on
  /// any load/lookup failure so callers degrade cleanly.
  NativeWorldGen _resolve() {
    final existing = _native;
    if (existing != null) return existing;
    if (_loadFailed) {
      throw const FfiUnavailable('native library previously failed to load');
    }
    try {
      final native = _loader.load();
      _native = native;
      return native;
    } on Object catch (e) {
      // ArgumentError (bad path), missing-symbol, open failure, etc.
      _loadFailed = true;
      throw FfiUnavailable(e.toString());
    }
  }

  @override
  Future<List<StructureLocation>> computeStructures(
      StructureQuery query, VersionStrategy strategy) async {
    final native = _resolve();
    final placement = strategy.placementFor(query.structureTypes.first);
    final hits = native.findStructures(
      worldSeed: _seedToInt(query.seed),
      structureType: query.structureTypes.first.index,
      centerX: query.centerX,
      centerZ: query.centerZ,
      radius: query.radius,
      spacing: placement.spacing,
      separation: placement.separation,
      salt: placement.salt,
      maxOut: query.maxResults,
    );
    return hits
        .map((h) => StructureLocation(
              x: h.blockX,
              y: h.blockY,
              z: h.blockZ,
              chunkX: h.chunkX,
              chunkZ: h.chunkZ,
              probability: 1.0,
              structureType: query.structureTypes.first,
              biome: h.biome.toString(),
            ))
        .toList(growable: false);
  }

  @override
  Future<List<OreLocation>> computeOres(
      OreQuery query, VersionStrategy strategy) async {
    final native = _resolve();
    final feature = strategy.oreFeatureFor(query.oreType);
    final hits = native.findOres(
      worldSeed: _seedToInt(query.seed),
      oreType: query.oreType.index,
      centerX: query.centerX,
      centerY: query.centerY,
      centerZ: query.centerZ,
      radius: query.radius,
      countPerChunk: feature.countPerChunk,
      tries: feature.tries,
      minY: feature.minY,
      maxY: feature.maxY,
      minVein: feature.minVeinSize,
      maxVein: feature.maxVeinSize,
      decorationSalt: strategy.rngParams.decorationSalt,
      maxOut: query.maxResults,
    );
    return hits
        .map((h) => OreLocation(
              x: h.blockX,
              y: h.blockY,
              z: h.blockZ,
              chunkX: h.blockX >> 4,
              chunkZ: h.blockZ >> 4,
              probability: 1.0,
              oreType: query.oreType,
              estimatedVeinSize: h.veinSize,
            ))
        .toList(growable: false);
  }

  @override
  Future<String> computeBiome(
      int seed, int x, int z, VersionStrategy strategy) async {
    final native = _resolve();
    return native.getBiome(seed, x, z).toString();
  }

  /// Parse a seed string the same way the legacy finders do: a numeric seed is
  /// used directly; otherwise the string's `hashCode` is used.
  static int _seedToInt(String seed) {
    final parsed = int.tryParse(seed.trim());
    if (parsed != null) return parsed;
    return seed.hashCode;
  }
}

/// Thrown internally when the native library cannot be loaded or a symbol is
/// missing. [AccurateEngine] catches any throw from the backend and maps it to
/// `EngineUnavailable(FallbackReason.ffiLoadFailure)`.
class FfiUnavailable implements Exception {
  const FfiUnavailable(this.message);
  final String message;

  @override
  String toString() => 'FfiUnavailable: $message';
}
