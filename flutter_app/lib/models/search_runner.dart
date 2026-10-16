import 'package:flutter/foundation.dart';

import 'game_random.dart';
import 'ore_finder.dart';
import 'ore_location.dart';
import 'structure_finder.dart';
import 'structure_location.dart';
import 'worldgen/accurate_engine.dart';
import 'worldgen/engine_selector.dart';
import 'worldgen/java_version_strategy.dart';
import 'worldgen/minecraft_version.dart';
import 'worldgen/native_ffi_backend.dart';
import 'worldgen/simulated_engine.dart';
import 'worldgen/version_strategy_registry.dart';
import 'worldgen/worldgen_backend.dart';
import 'worldgen/worldgen_engine.dart';

/// Runs the search algorithms on a background isolate via [compute] so the
/// heavy nested loops never block the UI thread. Keeping the work off the main
/// isolate is what lets the search spinner animate and the app stay responsive
/// while a search runs.
///
/// All ore/structure searches are routed through the [WorldGenEngine] layer:
/// an [EngineSelectionContext] picks exactly one engine (Estimate -> Simulated,
/// Accurate -> Accurate when verified/runnable), the runner branches on the
/// sealed [EngineResult], and on any `EngineUnavailable`/
/// `EngineUnsupportedVersion` it falls back to the Simulated engine and tags
/// the output with a non-null [SearchMeta.fallbackReason] (Req 5.1-5.4, 11.3).
///
/// The param/result objects below only hold primitives, enums, and lists of
/// model objects (whose fields are primitives/enums/strings), so they are safe
/// to send across the isolate boundary.

/// Carries mode/version/verification and, when a fallback occurred, the reason.
/// Read by the UI to decide whether to render the Estimate-mode notice and
/// whether to omit the fabricated probability %.
class SearchMeta {
  const SearchMeta({
    required this.mode,
    required this.version,
    required this.verified,
    this.fallbackReason,
  });

  /// The mode the output was actually produced in (Estimate after a fallback).
  final SearchMode mode;

  /// The version id the search ran for (e.g. "java-1.20").
  final String version;

  /// Whether the version was verified (only meaningful for Accurate output).
  final bool verified;

  /// Non-null and non-empty whenever Accurate degraded to Estimate (Req 5.4).
  final FallbackReason? fallbackReason;

  /// Metadata for a plain Estimate-mode result (no fallback occurred).
  const SearchMeta.estimate(this.version)
      : mode = SearchMode.estimate,
        verified = false,
        fallbackReason = null;

  /// Metadata for a successful Accurate-mode result.
  const SearchMeta.accurate(this.version)
      : mode = SearchMode.accurate,
        verified = true,
        fallbackReason = null;

  /// Metadata for an Accurate request that fell back to Estimate.
  const SearchMeta.fallback(this.version, this.fallbackReason)
      : mode = SearchMode.estimate,
        verified = false;

  bool get didFallback => fallbackReason != null;
}

/// Bundles a result list with the total number of qualifying candidates found
/// before the display cap was applied, plus the [SearchMeta] describing how the
/// output was produced.
class SearchOutput<T> {
  const SearchOutput(this.results, this.totalFound, {this.meta});
  final List<T> results;
  final int totalFound;
  final SearchMeta? meta;
}

// ---------------------------------------------------------------------------
// Ore search
// ---------------------------------------------------------------------------

class OreSearchParams {
  const OreSearchParams({
    required this.seed,
    required this.centerX,
    required this.centerY,
    required this.centerZ,
    required this.radius,
    required this.oreType,
    required this.includeNether,
    required this.edition,
    required this.versionEra,
    required this.maxResults,
    this.mode = SearchMode.estimate,
    this.versionId,
  });

  final String seed;
  final int centerX;
  final int centerY;
  final int centerZ;
  final int radius;
  final OreType oreType;
  final bool includeNether;
  final MinecraftEdition edition;
  final VersionEra versionEra;
  final int maxResults;

  /// Which engine path the caller is requesting. Defaults to Estimate so the
  /// existing callers keep the current behavior exactly.
  final SearchMode mode;

  /// Explicit version id for Accurate mode (e.g. "java-1.20"). When null, a
  /// version is derived from [edition]/[versionEra] for the Simulated path.
  final String? versionId;

  MinecraftVersion get version => _versionOf(edition, versionEra, versionId);
}

class NetheriteSearchParams {
  const NetheriteSearchParams({
    required this.seed,
    required this.centerX,
    required this.centerZ,
    required this.edition,
    required this.versionEra,
    required this.maxResults,
  });

  final String seed;
  final int centerX;
  final int centerZ;
  final MinecraftEdition edition;
  final VersionEra versionEra;
  final int maxResults;
}

class StructureSearchParams {
  const StructureSearchParams({
    required this.seed,
    required this.centerX,
    required this.centerZ,
    required this.radius,
    required this.structureTypes,
    required this.maxResults,
    required this.edition,
    required this.versionEra,
    this.mode = SearchMode.estimate,
    this.versionId,
  });

  final String seed;
  final int centerX;
  final int centerZ;
  final int radius;
  final Set<StructureType> structureTypes;
  final int maxResults;
  final MinecraftEdition edition;
  final VersionEra versionEra;

  /// Which engine path the caller is requesting. Defaults to Estimate.
  final SearchMode mode;

  /// Explicit version id for Accurate mode. When null, derived from
  /// [edition]/[versionEra].
  final String? versionId;

  MinecraftVersion get version => _versionOf(edition, versionEra, versionId);
}

/// Derive a [MinecraftVersion] from an explicit id or, failing that, from the
/// coarse era (the mapping the Simulated path collapses back to an era anyway).
MinecraftVersion _versionOf(
    MinecraftEdition edition, VersionEra era, String? versionId) {
  if (versionId != null && versionId.isNotEmpty) {
    return MinecraftVersion(versionId);
  }
  return MinecraftVersion.of(
      edition, era == VersionEra.legacy ? '1.16' : '1.20');
}

// ---------------------------------------------------------------------------
// Engine wiring used inside the isolate. Kept as factory functions so the
// runner routes exclusively through WorldGenEngine while the search still runs
// on a background isolate via compute().
// ---------------------------------------------------------------------------

/// Builds the engine pair + selection context for a request. The platform is
/// fixed to a native-like value inside the isolate so Estimate requests behave
/// exactly as before; Accurate selection honours verification/web-can-run.
EngineSelectionContext _contextFor({
  required SearchMode mode,
  required MinecraftVersion version,
  required MinecraftEdition edition,
}) {
  final registry = VersionStrategyRegistry();
  // Register the Java 1.18-1.20 strategies as Supported. They are NOT marked
  // Verified: their golden fixtures are algorithm-derived pending authoritative
  // native cross-checking, so Accurate requests still degrade to the Simulated
  // path (Req 5.2) until a live native run verifies the fixtures.
  registry.register(JavaVersionStrategy.java118());
  registry.register(JavaVersionStrategy.java119());
  registry.register(JavaVersionStrategy.java120());
  const simulated = SimulatedEngine();
  final accurate = AccurateEngine(
    registry: registry,
    platform: _runnerPlatform,
    selectBackend: (p) => selectBackend(
      p,
      dartWebBackend: const DartWebBackend(),
      // native_ffi_backend.dart conditionally imports dart:ffi, so no FFI
      // dependency reaches the web bundle. On web selectBackend routes to the
      // DartWebBackend and never touches this instance.
      nativeFfiBackend: NativeFfiBackend(),
    ),
  );
  return EngineSelectionContext(
    mode: mode,
    version: version,
    edition: edition,
    platform: _runnerPlatform,
    registry: registry,
    simulated: simulated,
    accurate: accurate,
  );
}

/// The platform the runner assumes when not on web. The engine's actual load
/// attempt (and its load-failure handling) still governs whether Accurate
/// produces output or degrades.
const Platform _runnerPlatform = kIsWeb ? Platform.web : Platform.linux;

Future<SearchOutput<OreLocation>> _runOreSearch(OreSearchParams p) async {
  final ctx = _contextFor(
    mode: p.mode,
    version: p.version,
    edition: p.edition,
  );
  final engine = selectEngine(ctx);
  final query = OreQuery(
    seed: p.seed,
    centerX: p.centerX,
    centerY: p.centerY,
    centerZ: p.centerZ,
    radius: p.radius,
    oreType: p.oreType,
    includeNether: p.includeNether,
    edition: p.edition,
    version: p.version,
    maxResults: p.maxResults,
  );
  return dispatchOreSearch(engine, query, p.versionEra);
}

/// Dispatch an ore search through the chosen [engine], branching on the sealed
/// [EngineResult] and falling back to the Simulated finder on any
/// unavailable/unsupported outcome. Exposed (not private) so the runner-seam
/// test can inject a spy engine and assert the dispatch path.
///
/// Routes every search exclusively through [WorldGenEngine]: Accurate output is
/// consumed via its [EngineResult]; otherwise the engine is itself a
/// [WorldGenEngine] (Simulated) whose [EngineOk] is used directly.
Future<SearchOutput<OreLocation>> dispatchOreSearch(
    WorldGenEngine engine, OreQuery query, VersionEra era) async {
  final result = await engine.findOres(query);
  switch (result) {
    case EngineOk<OreLocation> ok:
      return SearchOutput<OreLocation>(
        ok.results,
        ok.results.length,
        meta: engine is AccurateEngine
            ? SearchMeta.accurate(query.version.id)
            : SearchMeta.estimate(query.version.id),
      );
    case EngineUnavailable<OreLocation> u:
      return _oreFallback(query, era, reason: u.reason);
    case EngineUnsupportedVersion<OreLocation> _:
      return _oreFallback(query, era,
          reason: FallbackReason.unsupportedVersion);
  }
}

Future<SearchOutput<OreLocation>> _oreFallback(
  OreQuery query,
  VersionEra era, {
  required FallbackReason reason,
}) async {
  final finder = OreFinder();
  int t = 0;
  final results = await finder.findOres(
    seed: query.seed,
    centerX: query.centerX,
    centerY: query.centerY,
    centerZ: query.centerZ,
    radius: query.radius,
    oreType: query.oreType,
    includeNether: query.includeNether,
    edition: query.edition,
    versionEra: era,
    maxResults: query.maxResults,
    onTotalFound: (n) => t += n,
  );
  return SearchOutput<OreLocation>(
    results,
    t,
    meta: SearchMeta.fallback(query.version.id, reason),
  );
}

Future<SearchOutput<OreLocation>> _runNetheriteSearch(
    NetheriteSearchParams p) async {
  final finder = OreFinder();
  int total = 0;
  final results = await finder.findAllNetherite(
    seed: p.seed,
    centerX: p.centerX,
    centerZ: p.centerZ,
    edition: p.edition,
    versionEra: p.versionEra,
    maxResults: p.maxResults,
    onTotalFound: (n) => total += n,
  );
  return SearchOutput<OreLocation>(
    results,
    total,
    meta: SearchMeta.estimate(
        MinecraftVersion.of(p.edition,
                p.versionEra == VersionEra.legacy ? '1.16' : '1.20')
            .id),
  );
}

Future<SearchOutput<StructureLocation>> _runStructureSearch(
    StructureSearchParams p) async {
  final ctx = _contextFor(
    mode: p.mode,
    version: p.version,
    edition: p.edition,
  );
  final engine = selectEngine(ctx);
  final query = StructureQuery(
    seed: p.seed,
    centerX: p.centerX,
    centerZ: p.centerZ,
    radius: p.radius,
    structureTypes: p.structureTypes,
    maxResults: p.maxResults,
    edition: p.edition,
    version: p.version,
  );
  return dispatchStructureSearch(engine, query, p.versionEra);
}

/// Dispatch a structure search through the chosen [engine], branching on the
/// sealed [EngineResult] and falling back to the Simulated finder on any
/// unavailable/unsupported outcome. Exposed for the runner-seam test.
Future<SearchOutput<StructureLocation>> dispatchStructureSearch(
    WorldGenEngine engine, StructureQuery query, VersionEra era) async {
  final result = await engine.findStructures(query);
  switch (result) {
    case EngineOk<StructureLocation> ok:
      return SearchOutput<StructureLocation>(
        ok.results,
        ok.results.length,
        meta: engine is AccurateEngine
            ? SearchMeta.accurate(query.version.id)
            : SearchMeta.estimate(query.version.id),
      );
    case EngineUnavailable<StructureLocation> u:
      return _structureFallback(query, era, reason: u.reason);
    case EngineUnsupportedVersion<StructureLocation> _:
      return _structureFallback(query, era,
          reason: FallbackReason.unsupportedVersion);
  }
}

Future<SearchOutput<StructureLocation>> _structureFallback(
  StructureQuery query,
  VersionEra era, {
  required FallbackReason reason,
}) async {
  int total = 0;
  final results = await StructureFinder().findStructures(
    seed: query.seed,
    centerX: query.centerX,
    centerZ: query.centerZ,
    radius: query.radius,
    structureTypes: query.structureTypes,
    maxResults: query.maxResults,
    edition: query.edition,
    versionEra: era,
    onTotalFound: (n) => total += n,
  );
  return SearchOutput<StructureLocation>(
    results,
    total,
    meta: SearchMeta.fallback(query.version.id, reason),
  );
}

/// Public helpers that dispatch each search to a background isolate.
///
/// The methods keep their original shapes so existing callers keep working;
/// the dispatch now runs through the [WorldGenEngine] layer inside the isolate.
class SearchRunner {
  const SearchRunner._();

  /// The isolate-offload function used to dispatch searches. Defaults to
  /// Flutter's [compute]. Overridable in tests to assert that searches are
  /// still offloaded via `compute` (the test records invocations and then
  /// delegates to the real [compute]).
  @visibleForTesting
  static Future<R> Function<M, R>(
    ComputeCallback<M, R> callback,
    M message, {
    String? debugLabel,
  }) computeImpl = compute;

  /// Restore the default [compute] implementation (for test teardown).
  @visibleForTesting
  static void resetComputeImpl() {
    computeImpl = compute;
  }

  static Future<SearchOutput<OreLocation>> findOres(OreSearchParams params) {
    return computeImpl(_runOreSearch, params);
  }

  static Future<SearchOutput<OreLocation>> findAllNetherite(
      NetheriteSearchParams params) {
    return computeImpl(_runNetheriteSearch, params);
  }

  static Future<SearchOutput<StructureLocation>> findStructures(
      StructureSearchParams params) {
    return computeImpl(_runStructureSearch, params);
  }
}
