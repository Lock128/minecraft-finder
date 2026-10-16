import 'bedrock_version_strategy.dart';
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
  // M1-M3 Java (1.18-1.20): algorithm-derived fixtures, Supported-not-Verified.
  registry.register(JavaVersionStrategy.java118());
  registry.register(JavaVersionStrategy.java119());
  registry.register(JavaVersionStrategy.java120());
  // M4 version expansion: 1.16/1.17 (legacy distribution) and 1.21+ (modern).
  // These are also Supported-but-NOT-Verified: their golden fixtures are
  // algorithm-derived (the pre-1.18 placement tables and 1.21 constants have
  // not been cross-checked against an authoritative native run), so Accurate
  // requests for them still degrade to the Simulated path (Req 5.2).
  registry.register(JavaVersionStrategy.java116());
  registry.register(JavaVersionStrategy.java117());
  registry.register(JavaVersionStrategy.java121());
  // M5 Bedrock track (MT19937). Supported-but-NOT-Verified for the same
  // reason: the Bedrock placement constants are algorithm-derived. An
  // unregistered Bedrock version (anything other than the ids registered here)
  // has no strategy and the SearchRunner degrades it to Simulated with
  // FallbackReason.bedrockNoStrategy (Req 11.3).
  registry.register(BedrockVersionStrategy.bedrock121());
  return registry;
}
