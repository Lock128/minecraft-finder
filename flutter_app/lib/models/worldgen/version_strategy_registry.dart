import '../game_random.dart';
import 'minecraft_version.dart';
import 'version_strategy.dart';

/// Maps `(version, edition) -> VersionStrategy` and answers [isSupported] and
/// [isVerified].
///
/// A version is **Supported** when a strategy is registered for it, and
/// **Verified** when its golden fixtures pass (driven by [verifiedVersions],
/// which the fixture/CI layer populates). The registry is the single source of
/// truth queried by [VersionAvailability] so the UI version picker and the
/// content gating stay consistent.
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
class VersionStrategyRegistry {
  VersionStrategyRegistry({
    Map<String, VersionStrategy>? strategies,
    Set<String>? verifiedVersions,
  })  : _strategies = strategies ?? <String, VersionStrategy>{},
        _verified = verifiedVersions ?? <String>{};

  final Map<String, VersionStrategy> _strategies;
  final Set<String> _verified;

  /// Register (or replace) a strategy, keyed by its version id.
  void register(VersionStrategy strategy, {bool verified = false}) {
    _strategies[strategy.version.id] = strategy;
    if (verified) {
      _verified.add(strategy.version.id);
    }
  }

  /// Mark a registered version as verified (its golden fixtures pass).
  void markVerified(MinecraftVersion version) {
    _verified.add(version.id);
  }

  /// Resolve the strategy for [version], or null when none is registered.
  VersionStrategy? strategyFor(MinecraftVersion version) {
    final s = _strategies[version.id];
    if (s == null) return null;
    // The strategy's own edition must agree with the requested version's.
    if (s.edition != version.edition) return null;
    return s;
  }

  /// Whether a strategy exists for [version] (Supported_Version).
  bool isSupported(MinecraftVersion version) => strategyFor(version) != null;

  /// Whether [version] is supported AND verified (Verified_Version).
  bool isVerified(MinecraftVersion version) =>
      isSupported(version) && _verified.contains(version.id);

  /// All supported versions, in registration order.
  List<MinecraftVersion> get supportedVersions =>
      _strategies.values.map((s) => s.version).toList(growable: false);

  /// Supported versions filtered by [edition].
  List<MinecraftVersion> supportedVersionsFor(MinecraftEdition edition) =>
      _strategies.values
          .where((s) => s.edition == edition)
          .map((s) => s.version)
          .toList(growable: false);
}
