import 'java_version_strategy.dart';
import 'version_strategy_registry.dart';

/// Builds the app's default [VersionStrategyRegistry] with the Java 1.18-1.20
/// strategies registered as **Supported**.
///
/// These versions are intentionally NOT marked **Verified**: their golden
/// fixtures are algorithm-derived pending authoritative native cross-checking,
/// so Accurate requests for them still degrade to the Simulated path (Req 5.2)
/// until a live native run verifies the fixtures. Verification state is read
/// from this registry (never hard-coded in the UI) so the version picker and
/// the result cards stay consistent with the engine's behavior.
///
/// Both the search isolate (`search_runner.dart`) and the UI state
/// (`providers/search_state.dart`) build their registry through this single
/// factory so the supported/verified version lists never drift apart.
VersionStrategyRegistry buildDefaultRegistry() {
  final registry = VersionStrategyRegistry();
  registry.register(JavaVersionStrategy.java118());
  registry.register(JavaVersionStrategy.java119());
  registry.register(JavaVersionStrategy.java120());
  return registry;
}
