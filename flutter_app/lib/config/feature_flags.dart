/// Central feature flags for the app.
///
/// Set these to `true` to activate the corresponding features.
/// Keep them `false` in production until you're ready to launch.
class FeatureFlags {
  FeatureFlags._();

  /// Master switch for all monetization features.
  ///
  /// When `false`:
  /// - Pro tier gating is disabled (all users get full access)
  /// - The PRO badge in the app bar is hidden
  /// - The Pro upgrade dialog is inaccessible
  /// - The Stripe donation/support section is hidden
  /// - IAP initialization is skipped entirely
  ///
  /// Set to `true` when you have:
  /// 1. Configured your Stripe Payment Link URL
  /// 2. Set up the 'mc_finder_pro_unlock' product in App Store Connect / Play Console
  /// 3. Tested purchases in sandbox
  static const bool enableMonetization = false;
}
