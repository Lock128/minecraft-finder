import '../ore_location.dart';
import '../structure_location.dart';
import 'version_strategy.dart';
import 'worldgen_engine.dart';

/// Target platform abstraction used for backend selection.
///
/// Injected rather than read from `dart:io`/global state so `selectBackend`
/// stays a pure, testable function and so web builds never pull `dart:ffi`
/// into the bundle.
enum Platform {
  web,
  android,
  ios,
  macos,
  windows,
  linux,
  fuchsia,
}

/// Internal contract both accurate backends implement. The only difference
/// between them is *how* they execute a [VersionStrategy]: native C via
/// `dart:ffi` vs pure Int64 Dart.
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
abstract interface class WorldGenBackend {
  /// Whether this backend can run [strategy] for the given query.
  bool canRun(VersionStrategy strategy);

  Future<List<StructureLocation>> computeStructures(
    StructureQuery query,
    VersionStrategy strategy,
  );

  Future<List<OreLocation>> computeOres(
    OreQuery query,
    VersionStrategy strategy,
  );

  /// Compute the biome id at a world coordinate for the given seed.
  Future<String> computeBiome(
    int seed,
    int x,
    int z,
    VersionStrategy strategy,
  );
}

/// Pure selector: web -> [DartWebBackend], everything else ->
/// [NativeFfiBackend]. Platform detection is injected via [p].
WorldGenBackend selectBackend(
  Platform p, {
  required WorldGenBackend dartWebBackend,
  required WorldGenBackend nativeFfiBackend,
}) {
  return p == Platform.web ? dartWebBackend : nativeFfiBackend;
}

/// Function type for the backend selector so it can be injected into the
/// [AccurateEngine].
typedef BackendSelector = WorldGenBackend Function(Platform platform);

/// Placeholder pure-Dart web backend. Real placement logic is filled in by the
/// later milestone features (M1-M3); here it is a wiring stub that reports it
/// cannot run so the engine degrades cleanly.
class DartWebBackend implements WorldGenBackend {
  const DartWebBackend();

  @override
  bool canRun(VersionStrategy strategy) => false;

  @override
  Future<List<StructureLocation>> computeStructures(
      StructureQuery query, VersionStrategy strategy) async {
    throw UnsupportedError('DartWebBackend placement not yet implemented');
  }

  @override
  Future<List<OreLocation>> computeOres(
      OreQuery query, VersionStrategy strategy) async {
    throw UnsupportedError('DartWebBackend placement not yet implemented');
  }

  @override
  Future<String> computeBiome(
      int seed, int x, int z, VersionStrategy strategy) async {
    throw UnsupportedError('DartWebBackend biome not yet implemented');
  }
}

/// Placeholder native FFI backend. The real `dart:ffi` binding to Cubiomes is
/// filled in by a later milestone feature; here it is a wiring stub that
/// reports it cannot run so the engine degrades cleanly.
class NativeFfiBackend implements WorldGenBackend {
  const NativeFfiBackend();

  @override
  bool canRun(VersionStrategy strategy) => false;

  @override
  Future<List<StructureLocation>> computeStructures(
      StructureQuery query, VersionStrategy strategy) async {
    throw UnsupportedError('NativeFfiBackend not yet implemented');
  }

  @override
  Future<List<OreLocation>> computeOres(
      OreQuery query, VersionStrategy strategy) async {
    throw UnsupportedError('NativeFfiBackend not yet implemented');
  }

  @override
  Future<String> computeBiome(
      int seed, int x, int z, VersionStrategy strategy) async {
    throw UnsupportedError('NativeFfiBackend not yet implemented');
  }
}
