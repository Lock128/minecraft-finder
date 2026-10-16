import '../game_random.dart';
import '../ore_location.dart';
import '../structure_location.dart';
import 'minecraft_version.dart';

/// The single interface the search layer calls. Both [SimulatedEngine] and
/// [AccurateEngine] implement it, so engines are interchangeable behind the
/// `SearchRunner`.
///
/// Signatures mirror the existing finder parameters so the Simulated engine is
/// a direct delegate, but the version input is the explicit [MinecraftVersion]
/// rather than the coarse [VersionEra].
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
abstract interface class WorldGenEngine {
  Future<EngineResult<StructureLocation>> findStructures(StructureQuery q);
  Future<EngineResult<OreLocation>> findOres(OreQuery q);
}

// ---------------------------------------------------------------------------
// Queries. These mirror StructureSearchParams / OreSearchParams from
// search_runner.dart but carry an explicit MinecraftVersion.
// ---------------------------------------------------------------------------

/// Query for structure searches. Mirrors `StructureSearchParams` plus a
/// [version] field.
class StructureQuery {
  const StructureQuery({
    required this.seed,
    required this.centerX,
    required this.centerZ,
    required this.radius,
    required this.structureTypes,
    required this.maxResults,
    required this.edition,
    required this.version,
  });

  final String seed;
  final int centerX;
  final int centerZ;
  final int radius;
  final Set<StructureType> structureTypes;
  final int maxResults;
  final MinecraftEdition edition;
  final MinecraftVersion version;
}

/// Query for ore searches. Mirrors `OreSearchParams` plus a [version] field.
class OreQuery {
  const OreQuery({
    required this.seed,
    required this.centerX,
    required this.centerY,
    required this.centerZ,
    required this.radius,
    required this.oreType,
    required this.includeNether,
    required this.edition,
    required this.version,
    required this.maxResults,
  });

  final String seed;
  final int centerX;
  final int centerY;
  final int centerZ;
  final int radius;
  final OreType oreType;
  final bool includeNether;
  final MinecraftEdition edition;
  final MinecraftVersion version;
  final int maxResults;
}

// ---------------------------------------------------------------------------
// Result hierarchy. A sealed type lets the runner branch on
// unavailable/unsupported without exception control flow, and keeps the value
// isolate-serializable (primitives / enums / model objects only).
// ---------------------------------------------------------------------------

/// Outcome wrapper: either results, or a signal that the engine could not run.
sealed class EngineResult<T> {
  const EngineResult();
}

/// Successful computation. [results] is the (possibly capped) list of
/// locations; [meta] carries real accurate-mode metadata.
class EngineOk<T> extends EngineResult<T> {
  const EngineOk(this.results, {this.meta = const ResultMeta.empty()});
  final List<T> results;
  final ResultMeta meta;
}

/// The engine was the right choice but could not run (FFI load failure, web
/// limitation). The [reason] explains why, so the runner can fall back and the
/// UI can surface a notice.
class EngineUnavailable<T> extends EngineResult<T> {
  const EngineUnavailable(this.reason);
  final FallbackReason reason;
}

/// No strategy exists for the requested [version]/[edition]; the engine
/// reports rather than crashing.
class EngineUnsupportedVersion<T> extends EngineResult<T> {
  const EngineUnsupportedVersion(this.version, this.edition);
  final MinecraftVersion version;
  final MinecraftEdition edition;
}

/// Real accurate-mode metadata layered on top of the reused location classes.
///
/// In Accurate mode the fabricated `probability` field on a location is not
/// displayed; instead these real values are surfaced where available.
class ResultMeta {
  /// Number of ore blocks in an emitted vein (present and >= 1 for accurate
  /// ore veins). Null when not applicable.
  final int? veinSize;

  /// Structure variant label (e.g. village type) when known.
  final String? structureVariant;

  /// Computed biome at the result position, when known.
  final String? biome;

  const ResultMeta({this.veinSize, this.structureVariant, this.biome});

  /// A metadata value carrying nothing.
  const ResultMeta.empty()
      : veinSize = null,
        structureVariant = null,
        biome = null;
}

/// Why an Accurate request ended up falling back to the Simulated path. Each
/// value has human-readable [text] the UI renders in the fallback notice.
enum FallbackReason {
  /// The web (JS) path does not support this version/edition yet.
  webUnsupported,

  /// A strategy exists but its golden fixtures have not been verified.
  unverifiedVersion,

  /// No strategy is registered for this version/edition.
  unsupportedVersion,

  /// The native FFI library could not be loaded or a symbol was missing.
  ffiLoadFailure,

  /// A Bedrock version with no registered strategy was requested.
  bedrockNoStrategy;

  /// Human-readable explanation suitable for display to the user.
  String get text {
    switch (this) {
      case FallbackReason.webUnsupported:
        return 'Accurate mode is not available for this version on the web; '
            'showing estimated results instead.';
      case FallbackReason.unverifiedVersion:
        return 'Accurate results for this version have not been verified yet; '
            'showing estimated results instead.';
      case FallbackReason.unsupportedVersion:
        return 'This version is not supported by Accurate mode; showing '
            'estimated results instead.';
      case FallbackReason.ffiLoadFailure:
        return 'The accurate world-generation engine could not be loaded; '
            'showing estimated results instead.';
      case FallbackReason.bedrockNoStrategy:
        return 'Accurate mode does not support this Bedrock version yet; '
            'showing estimated results instead.';
    }
  }
}
