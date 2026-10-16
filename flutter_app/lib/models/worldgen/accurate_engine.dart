import '../ore_location.dart';
import '../structure_location.dart';
import 'minecraft_version.dart';
import 'version_strategy.dart';
import 'version_strategy_registry.dart';
import 'worldgen_backend.dart';
import 'worldgen_engine.dart';

/// Seed-accurate [WorldGenEngine]. Owns a [BackendSelector] and a
/// [VersionStrategyRegistry].
///
/// Returns [EngineUnsupportedVersion] when no strategy exists for the request
/// and [EngineUnavailable] when the selected backend cannot run (e.g. the web
/// path does not yet support a version, or the native library fails to load).
///
/// Backends may be wiring stubs here that later milestone features fill in;
/// the engine wiring itself is complete.
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
class AccurateEngine implements WorldGenEngine {
  AccurateEngine({
    required this.registry,
    required BackendSelector selectBackend,
    required this.platform,
  }) : _selectBackend = selectBackend;

  final VersionStrategyRegistry registry;
  final BackendSelector _selectBackend;
  final Platform platform;

  WorldGenBackend get backend => _selectBackend(platform);

  @override
  Future<EngineResult<StructureLocation>> findStructures(
      StructureQuery q) async {
    final strategy = _resolve(q.version);
    if (strategy == null) {
      return EngineUnsupportedVersion<StructureLocation>(q.version, q.edition);
    }
    final b = backend;
    if (!b.canRun(strategy)) {
      return EngineUnavailable<StructureLocation>(_unavailableReason());
    }
    try {
      final results = await b.computeStructures(q, strategy);
      return EngineOk<StructureLocation>(results);
    } on Object {
      return EngineUnavailable<StructureLocation>(_unavailableReason());
    }
  }

  @override
  Future<EngineResult<OreLocation>> findOres(OreQuery q) async {
    final strategy = _resolve(q.version);
    if (strategy == null) {
      return EngineUnsupportedVersion<OreLocation>(q.version, q.edition);
    }
    final b = backend;
    if (!b.canRun(strategy)) {
      return EngineUnavailable<OreLocation>(_unavailableReason());
    }
    try {
      final results = await b.computeOres(q, strategy);
      return EngineOk<OreLocation>(results);
    } on Object {
      return EngineUnavailable<OreLocation>(_unavailableReason());
    }
  }

  VersionStrategy? _resolve(MinecraftVersion version) =>
      registry.strategyFor(version);

  FallbackReason _unavailableReason() => platform == Platform.web
      ? FallbackReason.webUnsupported
      : FallbackReason.ffiLoadFailure;
}
