// Property 20: Disclaimer visibility follows mode and verification.
// Validates: Requirements 12.3, 12.5 (and 5.4 fallback-notice behavior).
//
// Asserted at the presentation-model level (ResultPresentation), independent of
// any widget pump, so the invariant is locked down directly:
//   - The estimate disclaimer is hidden IFF the results are Accurate AND from a
//     Verified_Version (a successful Accurate run with no fallback).
//   - The fabricated probability % is omitted WHENEVER the mode is Accurate.
//   - A fallback always carries its reason text in the notice.

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/search_runner.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/engine_selector.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';
import 'package:gem_ore_struct_finder_mc/widgets/result_presentation.dart';

void main() {
  group('Property 20: disclaimer hidden iff Accurate + Verified', () {
    test('Verified Accurate result hides the disclaimer and the probability',
        () {
      final p = ResultPresentation.fromMeta(
        const SearchMeta.accurate('java-1.20'),
      );
      expect(p.showDisclaimer, isFalse,
          reason: 'Verified Accurate must hide the estimate disclaimer');
      expect(p.showProbability, isFalse,
          reason: 'Accurate must omit the fabricated probability %');
      expect(p.showRealMetadata, isTrue);
      expect(p.showFallbackNotice, isFalse);
    });

    test('Plain Estimate result keeps the disclaimer and the probability', () {
      final p = ResultPresentation.fromMeta(
        const SearchMeta.estimate('java-1.20'),
      );
      expect(p.showDisclaimer, isTrue);
      expect(p.showProbability, isTrue);
      expect(p.showRealMetadata, isFalse);
      expect(p.showFallbackNotice, isFalse);
    });

    test('Accurate request that fell back keeps the disclaimer via notice', () {
      final p = ResultPresentation.fromMeta(
        const SearchMeta.fallback(
            'java-1.20', FallbackReason.unverifiedVersion),
      );
      // A degraded result is Estimate: probability shows, disclaimer shows (as
      // the fallback notice), and no real metadata.
      expect(p.showProbability, isTrue);
      expect(p.showDisclaimer, isTrue);
      expect(p.showRealMetadata, isFalse);
      expect(p.showFallbackNotice, isTrue);
      expect(p.fallbackText, FallbackReason.unverifiedVersion.text);
      expect(p.fallbackText, isNotEmpty);
    });

    test('null meta is treated as plain Estimate (pre-existing behavior)', () {
      final p = ResultPresentation.fromMeta(null);
      expect(p.showProbability, isTrue);
      expect(p.showDisclaimer, isTrue);
      expect(p.showRealMetadata, isFalse);
      expect(p.showFallbackNotice, isFalse);
    });

    test(
        'probability omitted whenever Accurate and disclaimer hidden only when '
        'verified — exhaustive over the meta space', () {
      // Verified Accurate.
      final verified = ResultPresentation.fromMeta(
          const SearchMeta.accurate('java-1.20'));
      // Every fallback reason (Accurate degraded to Estimate).
      for (final reason in FallbackReason.values) {
        final fallback = ResultPresentation.fromMeta(
            SearchMeta.fallback('java-1.20', reason));
        // Degraded == Estimate: probability shown, disclaimer shown.
        expect(fallback.showProbability, isTrue);
        expect(fallback.showDisclaimer, isTrue);
        expect(fallback.fallbackText, reason.text);
        expect(fallback.fallbackText, isNotEmpty);
      }
      final estimate =
          ResultPresentation.fromMeta(const SearchMeta.estimate('java-1.20'));

      // The disclaimer is hidden in exactly one case: the verified Accurate.
      expect(verified.showDisclaimer, isFalse);
      expect(estimate.showDisclaimer, isTrue);

      // The probability is omitted in exactly the Accurate (mode) case.
      expect(verified.showProbability, isFalse);
      expect(estimate.showProbability, isTrue);
    });

    test('an Accurate-mode meta always omits the probability', () {
      // Construct an (unusual) Accurate-mode meta that is not verified; the
      // mode alone must drive probability omission.
      const meta = SearchMeta(
        mode: SearchMode.accurate,
        version: 'java-1.19',
        verified: false,
      );
      final p = ResultPresentation.fromMeta(meta);
      expect(p.showProbability, isFalse,
          reason: 'probability omitted whenever mode is Accurate');
      // Not verified => disclaimer still shown.
      expect(p.showDisclaimer, isTrue);
      expect(p.showRealMetadata, isFalse);
    });
  });
}
