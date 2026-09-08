/// Central feature flags for the app.
///
/// These are compile-time build defaults. Some flags (like monetization) can
/// additionally be toggled at runtime — see [MonetizationConfig].
class FeatureFlags {
  FeatureFlags._();

  /// Compile-time default for monetization features.
  ///
  /// When `false`, monetization is off by default at build time, but can still
  /// be enabled at runtime via the hidden developer unlock (tap the "Pro Tip"
  /// card in the Guide tab 7 times). See [MonetizationConfig].
  ///
  /// When `true`, monetization is always on regardless of the runtime override.
  ///
  /// Effects when monetization is active:
  /// - Pro tier gating is enabled
  /// - The PRO badge in the app bar is shown
  /// - The Pro upgrade dialog is accessible
  /// - The Stripe donation/support section is shown
  /// - IAP initialization runs
  static const bool enableMonetizationByDefault = false;
}
