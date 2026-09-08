import 'package:flutter/foundation.dart';

import '../config/feature_flags.dart';
import '../utils/preferences_service.dart';

/// Controls whether monetization features are active.
///
/// Monetization is active when EITHER:
/// - The compile-time default [FeatureFlags.enableMonetizationByDefault] is true, OR
/// - The user has enabled the hidden runtime override (by tapping the "Pro Tip"
///   card in the Guide tab 7 times in a row).
///
/// The runtime override is persisted so it survives app restarts.
class MonetizationConfig extends ChangeNotifier {
  /// Number of consecutive taps required to unlock monetization mode.
  static const int unlockTapCount = 7;

  bool _runtimeOverride = false;

  /// Whether monetization features should be active right now.
  bool get isEnabled =>
      FeatureFlags.enableMonetizationByDefault || _runtimeOverride;

  /// Whether the runtime override specifically is active (independent of the
  /// compile-time default). Useful for showing developer state.
  bool get isRuntimeOverrideEnabled => _runtimeOverride;

  /// Whether the runtime override can change the effective state.
  ///
  /// When monetization is forced on at compile time
  /// ([FeatureFlags.enableMonetizationByDefault] is `true`), the runtime
  /// override has no effect and the hidden gesture should be a no-op.
  bool get canToggleAtRuntime => !FeatureFlags.enableMonetizationByDefault;

  MonetizationConfig() {
    _load();
  }

  Future<void> _load() async {
    _runtimeOverride = await PreferencesService.getMonetizationOverride();
    if (_runtimeOverride) notifyListeners();
  }

  /// Enables the runtime override and persists it.
  Future<void> enableViaOverride() async {
    if (_runtimeOverride) return;
    _runtimeOverride = true;
    notifyListeners();
    await PreferencesService.setMonetizationOverride(true);
  }

  /// Disables the runtime override and persists it. (Does not affect the
  /// compile-time default.)
  Future<void> disableOverride() async {
    if (!_runtimeOverride) return;
    _runtimeOverride = false;
    notifyListeners();
    await PreferencesService.setMonetizationOverride(false);
  }
}
