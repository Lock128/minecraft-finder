import '../game_random.dart';
import 'accurate_engine.dart';
import 'minecraft_version.dart';
import 'simulated_engine.dart';
import 'version_strategy_registry.dart';
import 'worldgen_backend.dart';
import 'worldgen_engine.dart';

/// Search mode requested by the caller. Estimate is the current statistical
/// path; Accurate is the seed-accurate engine.
enum SearchMode { accurate, estimate }

/// Everything [selectEngine] needs to choose exactly one engine. Injected
/// (not read from global state) so selection stays a pure, testable function
/// that also runs inside the `compute` isolate.
class EngineSelectionContext {
  const EngineSelectionContext({
    required this.mode,
    required this.version,
    required this.edition,
    required this.platform,
    required this.registry,
    required this.simulated,
    required this.accurate,
    this.webCanRun = _defaultWebCanRun,
  });

  final SearchMode mode;
  final MinecraftVersion version;
  final MinecraftEdition edition;
  final Platform platform;
  final VersionStrategyRegistry registry;

  /// The engine instances to choose between. Both are supplied so selection
  /// never constructs engines and stays side-effect free.
  final WorldGenEngine simulated;
  final WorldGenEngine accurate;

  /// Whether the web (pure-Dart) path can run this version/edition. Defaults to
  /// "no" so, until the web backend supports a version, Accurate requests on
  /// web degrade to Estimate before any work is attempted (Req 5.1).
  final bool Function(MinecraftVersion version, MinecraftEdition edition)
      webCanRun;

  static bool _defaultWebCanRun(
          MinecraftVersion version, MinecraftEdition edition) =>
      false;
}

/// Pure engine selector (Req 1.5). Resolves to exactly one engine:
///
/// - Estimate -> Simulated.
/// - Accurate -> Simulated when the version is unverified (Req 5.2) or the web
///   path cannot run it (Req 5.1); otherwise Accurate.
///
/// Totality: every `(mode, version, edition, platform)` maps to one engine.
WorldGenEngine selectEngine(EngineSelectionContext ctx) {
  if (ctx.mode == SearchMode.estimate) {
    return ctx.simulated;
  }
  // Accurate requested.
  if (!ctx.registry.isVerified(ctx.version)) {
    return ctx.simulated; // Req 5.2
  }
  if (ctx.platform == Platform.web &&
      !ctx.webCanRun(ctx.version, ctx.edition)) {
    return ctx.simulated; // Req 5.1
  }
  return ctx.accurate;
}

/// Convenience: true when [engine] is the accurate path. Used by the runner to
/// decide whether to branch on the sealed [EngineResult] or treat output as a
/// plain simulated success.
bool isAccurateEngine(WorldGenEngine engine) => engine is AccurateEngine;

/// Convenience: true when [engine] is the simulated path.
bool isSimulatedEngine(WorldGenEngine engine) => engine is SimulatedEngine;
