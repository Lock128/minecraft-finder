# Implementation Plan — Light/Dark Theme Rework

Goal: make the light and dark themes consistent, cohesive, and readable, with special focus on LIGHT mode where several accent colors fail WCAG AA on the near-white surfaces. Dark mode must keep its vibrant neon aesthetic. Only colors/theme/contrast change — no logic, layout, or copy changes.

## Scope note (worktree + git)
- Operate only on files under `/Users/johanneskoch/git-private/minecraft-finder/.worktrees/theme-rework/flutter_app`.
- For git, use `git -C /Users/johanneskoch/git-private/minecraft-finder/.worktrees/theme-rework`. Do NOT use `git stash`.

## Build / test commands (verified during exploration)
- Analyze: `flutter analyze` (baseline is clean — "No issues found"). Flutter 3.47.2 is on PATH.
- Tests: `flutter test` (run the full suite; it is fast and pure-Dart).
- Both run from `.worktrees/theme-rework/flutter_app`. There are no existing theme/contrast unit tests; `test/golden_screenshot.dart` only asserts the app builds, so it is a smoke check, not a pixel golden.

## Measured contrast facts (why the changes below are needed)
Computed WCAG ratios of the current `GamerColors` light variants against the real light backgrounds (lightSurface `#FFFFFF`, lightCard `#F8F9FC`, lightBg `#F0F2F5`). AA requires >=4.5:1 for normal text, >=3:1 for large text/icons.

| constant | hex | white | lightCard | lightBg | verdict (normal text) |
|---|---|---|---|---|---|
| lightGold | `#9E8500` | 3.62 | 3.43 | 3.22 | FAIL everywhere |
| lightOrange | `#D45A00` | 3.99 | 3.79 | 3.56 | FAIL (large-text only) |
| lightCyan | `#0088A3` | 4.16 | 3.95 | 3.71 | FAIL on card/bg |
| lightYellow | `#8A7600` | 4.49 | 4.27 | 4.01 | borderline FAIL on card/bg |
| lightGreen | `#00873E` | 4.63 | 4.40 | 4.13 | borderline FAIL on card/bg |
| lightDiamond | `#007A8C` | 5.05 | 4.79 | 4.50 | pass |
| lightLapis | `#1565C0` | 5.75 | 5.46 | 5.12 | pass |
| lightRedstone | `#C62828` | 5.62 | 5.34 | 5.01 | pass |
| lightIron | `#546E7A` | 5.40 | 5.13 | 4.82 | pass (bump for margin) |
| lightPurple | `#7B2FA0` | 7.62 | 7.24 | 6.79 | pass |
| lightNetherite | `#9C27B0` | 6.30 | 5.99 | 5.62 | pass |
| lightCoal | `#455A64` | 7.24 | 6.88 | 6.46 | pass |

Muted grey from `onSurface #1A1A2E` blended over lightCard: alpha 0.6 → 4.43 (just under AA), 0.7 → 6.16 (pass), 0.85 → 10.34 (pass).
Flutter `Colors.grey[500] #9E9E9E` over lightCard → 2.54 (FAIL), `Colors.grey[400] #BDBDBD` → 1.78 (FAIL). These hardcoded greys are used for chunk/biome labels and copy icons and are the main "muted grey not readable" offenders.

## Target palette decisions (rationale)
Keep every DARK (neon*/*Neon) constant untouched — dark mode stays vibrant. Only the `light*` variants and hardcoded light-mode greys change. New light hexes are chosen to clear AA (>=4.6:1) against the worst real background (lightBg `#F0F2F5`) while keeping the same hue family so the palette stays cohesive. Target >=4.6 on lightBg gives a safety margin above the 4.5 threshold since cards sit on lightCard/white (slightly easier).

Corrected light hexes (all verified ≥ listed ratio on lightCard / white):
- `lightGold` `#9E8500` → `#87700A` (card 4.58 / white 4.83) — darker amber, same gold hue.
- `lightOrange` `#D45A00` → `#B84A00` (recompute in step 1; target card ≥4.6) — deeper burnt orange.
- `lightCyan` `#0088A3` → `#00727F` (card 5.37 / white 5.66) — deeper teal-cyan.
- `lightYellow` `#8A7600` → `#7A6600` (card 5.35 / white 5.63) — darker olive-gold.
- `lightGreen` `#00873E` → `#007A37` (recompute; target card ≥4.6) — slightly deeper green. NOTE: this constant also backs `ColorScheme.primary` and the light `focusedBorder`; keep it a saturated readable green.
- `lightDiamond` `#007A8C` → `#00707F` (card 5.50 / white 5.79) — nudge up for margin; keep distinct from lightCyan by staying marginally different, or (preferred) unify — see step 1 note.
- `lightIron` `#546E7A` → `#4B636E` (card 6.03 / white 6.35) — small bump for margin.
- Leave lightPurple, lightNetherite, lightRedstone, lightLapis, lightCoal unchanged (all comfortably pass).

Muted-grey decision: replace hardcoded `Colors.grey[400/500/600]` and `Colors.grey.shade300` used for TEXT and ICONS in light mode with theme-driven `onSurface.withValues(alpha: ...)`. Standard alphas: secondary/muted label text `0.70` (ratio ~6.2), de-emphasized icons `0.70`, hint/placeholder `0.60` is acceptable only for large/icon use — for normal body label text use `0.70` minimum. Dark mode keeps `Colors.white54/70` as-is (those pass on dark surfaces).

Surface/card relationship (keep, it is already cohesive): lightBg `#F0F2F5` (scaffold) < lightCard `#F8F9FC` (cards) < lightSurface `#FFFFFF` (inputs/headers). No change needed to surfaces; document the intended hierarchy in a comment.

---

## Steps

- [ ] 1. Correct the light-mode-safe palette hexes in `GamerColors` and add a short comment block documenting the AA target and the surface hierarchy.
      Update the constants `lightGreen`, `lightCyan`, `lightOrange`, `lightYellow`, `lightGold`, `lightDiamond`, `lightIron` to the corrected values in the decisions table. Before committing each new orange/green hex, recompute its ratio (same formula used in exploration) and confirm card ≥4.6; adjust one shade darker if short. Do NOT touch any `neon*`/`*Neon`/`dark*` constant. Decide and comment whether `lightDiamond` and `lightCyan` stay distinct or unify (diamond ore = cyan accent) — pick one and note why in a code comment.
      Files: `lib/theme/gamer_theme.dart`
      Verify: `flutter analyze` → no issues. Run a quick ratio recomputation of the new hexes against `#F8F9FC` and `#F0F2F5` and confirm every one is ≥4.5 (document the numbers in the commit message).

- [ ] 2. Add a reusable muted-foreground helper to `GamerColors` so muted greys route through the theme instead of hardcoded `Colors.grey[*]`.
      Add `static Color mutedText(BuildContext context, {double alpha = 0.70})` returning `Theme.of(context).colorScheme.onSurface.withValues(alpha: alpha)`, and an `mutedIcon` convenience (same, default alpha 0.70). Document that light mode must use these instead of `Colors.grey[400/500/600]`. This centralizes the fix so later steps don't scatter new hex.
      Files: `lib/theme/gamer_theme.dart`
      Verify: `flutter analyze` → no issues.

- [ ] 3. Replace hardcoded light-mode grey text/icon colors in the Results screen with `onSurface` alpha (via the step‑2 helper or `Theme.of(context).colorScheme.onSurface.withValues`).
      In `results_tab.dart` the chunk label, biome label (`Colors.grey[500]`), copy/bookmark icons (`Colors.grey[400]`), empty/no-results icons (`Colors.grey[400]`), loading hint (`Colors.grey[500]`), and pro-upsell subtitle (`Colors.grey[600]`) must use `onSurface` alpha in LIGHT mode while keeping the existing dark-mode branch (`Colors.white54/70`). Keep ore/structure value colors (`oreColor`, `structColor`) as-is — those come from the corrected adaptive helpers and now pass AA. The experimental/mode notice banner text already uses `onSurface.withValues(alpha: 0.85)` (ratio 10.3) — leave it.
      Files: `lib/widgets/results_tab.dart`
      Verify: `flutter analyze` → no issues; `flutter test` → suite passes (confirms no behavioral/build regression).

- [ ] 4. Fix the neon→light leak in widgets that pass raw neon constants as `accentColor` into `GamerCard`/`GamerSectionHeader` or use them for text/icons without an adaptive helper.
      The three widgets with duplicated local `_lightVariant()` maps (`guide_tab.dart`, `edition_version_card.dart`, `search_buttons.dart`) apply the light variant to TEXT but still pass the raw neon to `GamerCard.accentColor` and `GamerSectionHeader.accentColor` (card border + section bar stay neon in light mode). Route the accent through the adaptive variant in light mode too, OR centralize by adding a single `GamerColors.adaptiveAccent(Color neon, bool isDark)` helper in `gamer_theme.dart` and replacing the three local `_lightVariant` copies with it (preferred — removes duplication). Apply the same adaptive accent in: `structure_selection_card.dart`, `quick_start_card.dart` (neonYellow/neonCyan), `favorites_tab.dart`, `recent_seeds_widget.dart`, `results_map_view.dart` (legend + marker neon ore colors used in light mode), and `ore_finder_screen.dart` TabBar (`indicatorColor: neonGreen` and the results-count badge are acceptable as neon accents on the white tab bar since they are large/non-text UI — keep, but switch the selected `labelColor` path is already correct).
      Files: `lib/theme/gamer_theme.dart`, `lib/widgets/guide_tab.dart`, `lib/widgets/edition_version_card.dart`, `lib/widgets/search_buttons.dart`, `lib/widgets/structure_selection_card.dart`, `lib/widgets/quick_start_card.dart`, `lib/widgets/favorites_tab.dart`, `lib/widgets/recent_seeds_widget.dart`, `lib/widgets/results_map_view.dart`
      Verify: `flutter analyze` → no issues; `flutter test` → passes.

- [ ] 5. Sweep remaining widgets for hardcoded light-mode grey text/icons and raw `Color(0xFF...)` text leaks, applying the same `onSurface`-alpha / adaptive-accent rules.
      Remaining files from the grep that use `Colors.grey[400/500/600]`/`Colors.grey.shade300` for text or icons: `app_info_dialog.dart`, `pro_upgrade_dialog.dart`, `search_center_card.dart`, `search_history_widget.dart`, `release_notes_tab.dart`, plus `guide_tab.dart` body text (`Colors.grey[700]` — this one at 7.0+ passes, leave it). The repeated `isDarkMode ? Colors.white : const Color(0xFF1A1A2E)` title pattern is correct (1A1A2E = onSurface, 16:1) — leave those. `release_notes_dialog.dart` uses a self-contained green palette (`#2E7D32`/`#4CAF50`/`#66BB6A`) that already meets AA and is not part of the gamer palette — leave unless visibly inconsistent. `app_info_dialog.dart` `Color(0xFF635BFF)` is the Buy-Me-a-Coffee brand color on a filled button with white text — leave (brand + large). Only change greys used as low-contrast foreground.
      Files: `lib/widgets/app_info_dialog.dart`, `lib/widgets/pro_upgrade_dialog.dart`, `lib/widgets/search_center_card.dart`, `lib/widgets/search_history_widget.dart`, `lib/widgets/release_notes_tab.dart`
      Verify: `flutter analyze` → no issues; `flutter test` → passes.

- [ ] 6. Confirm the "Vein size" / gem value text path specifically.
      In `results_tab.dart`, `veinSizeLabel` and `probabilityLabel` render in `oreColor` (= `GamerColors.diamondText/goldText/...`). After step 1, re-verify each ore's light color against lightCard: diamond 5.5, gold (new) 4.58, lapis 5.46, redstone 5.34, iron (new) 6.03, coal 6.88, netherite 5.99, emerald/green (new) ≥4.6. Confirm none regressed below 4.5. No code change expected here if step 1 is correct — this is a verification gate.
      Files: (none expected) — verification against `lib/widgets/results_tab.dart`
      Verify: recompute ore light-color ratios vs `#F8F9FC`; all ≥4.5. `flutter test` passes.

- [ ] 7. Final full verification and visual sanity.
      Run the whole analyzer and test suite from a clean state; optionally regenerate the golden smoke test.
      Files: (none)
      Verify: `flutter analyze` → "No issues found"; `flutter test` → all pass. Optionally `flutter test test/golden_screenshot.dart` builds the app without error. Record the final contrast table (ore colors + muted greys on lightCard/lightBg) in the commit/PR body as evidence that every light-mode foreground meets AA.

## Constraints reminder (do not violate)
- Dark mode neon stays as-is: never change `neon*`, `*Neon`, or `dark*` constants, nor the dark-mode branches of adaptive expressions.
- Prefer routing through `GamerColors` helpers / `ColorScheme` over new scattered hex.
- No changes to app logic, layout structure, widget trees, or user-facing copy — colors/theme/contrast only.

## Known gaps / assumptions
- No formal WCAG target is documented in the repo; assumed AA (4.5 normal / 3.0 large) per the task brief. Used lightBg (the darkest-contrast of the three light surfaces) as the worst case and targeted ≥4.6 for margin.
- `results_map_view.dart` markers/legend are graphical (not text); treated under the 3:1 large/graphical bar, but routing them through adaptive variants also improves consistency, so step 4 includes them.
- `lightDiamond` vs `lightCyan` currently near-identical teals; step 1 decides whether to unify. Assumption: keep both but ensure each ≥4.5; unify only if the implementer finds them visually indistinguishable.
