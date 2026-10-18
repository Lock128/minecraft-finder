import '../models/search_runner.dart';
import '../models/worldgen/engine_selector.dart';

/// Pure presentation model deriving what the results UI should show from a
/// [SearchMeta]. Kept free of Flutter imports so Property 20 (disclaimer /
/// probability visibility) can be asserted directly, without a widget pump.
///
/// Rules (Req 12.3, 12.5, 5.4):
///   - The fabricated probability % is omitted whenever the displayed results
///     are Accurate-mode (`mode == accurate`).
///   - The estimate disclaimer is hidden **iff** the results are Accurate AND
///     from a Verified_Version — i.e. a successful Accurate run with no
///     fallback. Any Estimate result (including an Accurate request that
///     degraded to Estimate) keeps the disclaimer.
///   - The Estimate-mode fallback notice is shown with its reason text exactly
///     when a fallback occurred (`fallbackReason != null`).
class ResultPresentation {
  const ResultPresentation({
    required this.showProbability,
    required this.showDisclaimer,
    required this.showRealMetadata,
    required this.fallbackText,
    this.showExperimentalNotice = false,
  });

  /// Whether to render the fabricated probability %. False in Accurate mode.
  final bool showProbability;

  /// Whether to render the estimate disclaimer. False only for a Verified
  /// Accurate result.
  final bool showDisclaimer;

  /// Whether to render real metadata (vein size, structure variant). True only
  /// for a successful Accurate result.
  final bool showRealMetadata;

  /// The fallback-notice text to display, or null when no fallback occurred.
  final String? fallbackText;

  /// Whether a fallback notice should be shown at all.
  bool get showFallbackNotice => fallbackText != null;

  /// Whether to show the "experimental accurate" notice: the results are real
  /// seed-accurate positions produced via the user-opted-in web path on an
  /// unverified version, so we surface an experimental caveat instead of the
  /// verified-accurate notice.
  final bool showExperimentalNotice;

  /// Derive the presentation from a [meta]. A null [meta] (no search has run,
  /// or a legacy code path produced no meta) is treated as plain Estimate: the
  /// probability and disclaimer both show, matching the pre-existing behavior.
  factory ResultPresentation.fromMeta(SearchMeta? meta) {
    if (meta == null) {
      return const ResultPresentation(
        showProbability: true,
        showDisclaimer: true,
        showRealMetadata: false,
        fallbackText: null,
      );
    }
    // A verified Accurate result: no fallback, Accurate mode, verified version.
    final bool verifiedAccurate = meta.mode == SearchMode.accurate &&
        meta.verified &&
        meta.fallbackReason == null;
    // An experimental Accurate result: Accurate mode, real positions, but the
    // version is not verified (user opted in on web). Real metadata is shown,
    // but an "experimental" notice replaces the verified-accurate notice.
    final bool experimentalAccurate = meta.mode == SearchMode.accurate &&
        meta.experimental &&
        meta.fallbackReason == null;
    final bool accurate = meta.mode == SearchMode.accurate;
    return ResultPresentation(
      // Probability is a fabricated score; omit it whenever Accurate.
      showProbability: !accurate,
      // Disclaimer hidden for Verified Accurate and for Experimental Accurate
      // (the latter shows its own experimental notice instead).
      showDisclaimer: !verifiedAccurate && !experimentalAccurate,
      // Real metadata makes sense for any successful Accurate result, verified
      // or experimental (positions are real in both).
      showRealMetadata: verifiedAccurate || experimentalAccurate,
      showExperimentalNotice: experimentalAccurate,
      fallbackText: meta.fallbackReason?.text,
    );
  }
}
