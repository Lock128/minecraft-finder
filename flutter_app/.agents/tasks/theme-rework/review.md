# Light/dark theme rework for WCAG-AA readability

The change retunes every light-mode accent in `GamerColors`, routes muted greys and neon accents through two new theme helpers (`adaptiveAccent`, `mutedText`/`mutedIcon`), and gives `StructureUtils.getRarityColor` an `isDark` flag so light-mode rarity labels use darker readable variants. Dark mode is untouched: every `neon*`/`*Neon`/`dark*` constant is unchanged and each adaptive expression returns the raw neon when `isDark` is true. The goal was to clear WCAG AA (4.5:1 normal text, 3:1 large text/icons) in light mode on the near-white surfaces where several accents and hardcoded `Colors.grey[400/500]` labels previously failed.

Watch for: a pre-existing `Colors.grey[600]` (`#757575`) is still used for light-mode secondary text in several widgets the plan said it would sweep (search_center_card, pro_upgrade_dialog, quick_start_card, edition_version_card, app_info_dialog, release_notes_tab, guide_tab). It measures 4.38 on lightCard and 4.11 on lightBg — below the 4.5 normal-text bar on those surfaces — and is not covered by the verification note (confirmed). It is pre-existing and borderline, so it is a non-blocking readability observation rather than a regression introduced here.

**Verdict**: APPROVED

## High-level view

The accent retune is the core of the change and it holds up. I recomputed all seven changed light accents (`lightGreen #007A37`, `lightCyan #00727F`, `lightOrange #B84A00`, `lightYellow #7A6600`, `lightGold #7E6A00`, `lightDiamond #00698C`, `lightIron #4B636E`) against the worst-case scaffold background `#F0F2F5`, and every one clears 4.5:1 (lowest is lightOrange at 4.66). On cards and white inputs they sit higher. The previously-failing gold/orange/cyan/yellow/green pairs now pass everywhere.

Neon no longer leaks into light-mode text, icons, card borders, or section bars. The three duplicated local `_lightVariant` maps were deleted and replaced by one `adaptiveAccent` helper, and the widgets that previously passed raw neon into `GamerCard.accentColor`/`GamerSectionHeader.accentColor` (guide, edition-version, structure-selection, quick-start, favorites) now route the accent through it. Map markers and the results header icons do the same. Dark mode returns the untouched neon through the identity branch.

Muted greys route through `onSurface` at alpha 0.70 (≈6.0 on lightBg), with large empty-state glyphs at 0.55 (≈3.7, clearing the 3:1 graphical bar). The hardcoded `grey[400]`/`grey[500]` text/icon offenders were converted or replaced with a fixed `#616161` (5.5–6.2). The one gap is the `grey[600]` secondary text noted above, which the sweep missed.

Rarity labels gained a light-mode path: `#2E7D32`/`#4A7A28`/`#B45309`/`#C62828`/`#7B2FA0` all clear AA on the `#FAFAFA` chip (4.81–7.30), and the dark default (`isDark = true`) keeps the vivid Material colors for existing callers.

No app logic, layout, widget tree, or copy changed — the only structural edits are deleting the redundant `_lightVariant` helpers and adding the `isDark` parameter to `getRarityColor`.

<details>
<summary>Issues (1)</summary>

1. **Residual grey[600] light-mode text** — `#757575` secondary text remains in search_center_card, pro_upgrade_dialog, quick_start_card, edition_version_card, app_info_dialog, release_notes_tab, and guide_tab; it is 4.38 on lightCard / 4.11 on lightBg (below 4.5 for normal text) and not covered by the verification note. Pre-existing and borderline, so non-blocking — route these through `mutedText` in a follow-up for full consistency.

</details>

<details>
<summary>Details</summary>

### Accent retune meets AA on the worst-case surface

I ran an independent contrast computation on the seven changed constants against all three light surfaces rather than trusting the note's card-only column. Results (fg on `#F0F2F5` / `#F8F9FC` / `#FFFFFF`):

```
lightGold    #7E6A00  4.74 / 5.05 / 5.32
lightOrange  #B84A00  4.66 / 4.96 / 5.23
lightGreen   #007A37  4.88 / 5.20 / 5.47
lightCyan    #00727F  5.04 / 5.37 / 5.66
lightYellow  #7A6600  5.02 / 5.35 / 5.63
lightDiamond #00698C  5.51 / 5.87 / 6.18
lightIron    #4B636E  5.66 / 6.03 / 6.35
```

Every pair clears 4.5:1 even on the darkest light surface, so the ore value labels, nav labels, and primary green (`ColorScheme.primary` + focused input border) are all legible. Note one documentation drift: the verification note and plan describe `lightGold` as `#87700A`, but the committed constant is `#7E6A00`. Both clear AA (`#7E6A00` at 4.74/5.05/5.32 matches the note's 5.05 card figure), so the code is correct and only the written hex in the note is stale. `lightDiamond #00698C` and `lightCyan #00727F` are kept as deliberately distinct teals, mirroring diamondNeon vs neonCyan, and both pass.

### adaptiveAccent closes the neon-in-light leak

`adaptiveAccent(neon, isDark)` is the single mapping point: in dark mode it returns the neon unchanged, in light mode it maps to the tuned variant. The three local `_lightVariant` copies in guide_tab, edition_version_card, and search_buttons were removed in favor of it. The widgets that previously leaked neon into non-text surfaces — passing raw `neonOrange`/`neonPurple`/`neonYellow` straight into `GamerCard.accentColor` and `GamerSectionHeader.accentColor` — now pass the adaptive accent, so card borders and section bars follow the readable variant in light mode. Map markers in `results_map_view._oreColor` and the results-summary header icons (`place_outlined`, `grid_on`, `info_outline`, now driven by `greenText(isDark)`) route through the same path. The remaining raw-neon references I checked are either dark-mode branches or graphical elements exempt under the 3:1 bar (e.g. the TabBar `indicatorColor` and the `focusedBorder` cyan stroke), consistent with the plan's stated treatment.

### Muted greys via onSurface, with one missed tier

`mutedText`/`mutedIcon` resolve to `onSurface.withValues(alpha)`. On the worst-case lightBg, alpha 0.70 yields 5.96 and alpha 0.55 (the 64px empty-state glyphs) yields 3.73 — clearing the graphical 3:1 bar. The hardcoded `grey[400]` (1.78) and `grey[500]` (2.54) text/icon offenders were converted to these helpers or to a fixed `#616161` (6.19 on white, 5.52 on lightBg).

What the sweep did not catch is the `grey[600]` tier. `#757575` is 4.61 on white but only 4.38 on lightCard and 4.11 on lightBg. It is still used for light-mode secondary text in search_center_card (`:183`), pro_upgrade_dialog (`:114/:152/:255`), quick_start_card (`:92/:169`), edition_version_card (`:117`), app_info_dialog (`:220/:271/:500`), release_notes_tab (`:240`), and guide_tab (`:321`). All of these predate this commit (none appear in the diff), and the plan's step 5 explicitly named several of these files as targets while its measured-facts table only ever checked `grey[500]` and `grey[400]`, so `grey[600]` slipped through unmeasured. Because the text is small secondary copy, borderline, and pre-existing, it does not block, but it is the one place the "not readable in light mode" complaint is not fully resolved.

### Rarity labels get a light path without dulling dark

`getRarityColor` now takes `isDark = true`. The default preserves every existing dark-mode caller (vivid `Colors.green`/`orange`/`red`/`purple`), and the light branch returns darker variants that clear AA on the `#FAFAFA` chip: Very Common 4.91, Common 4.90, Uncommon 4.81, Rare 5.39, Very Rare 7.30, default `#616161` 5.93. `structure_selection_card` passes `isDark: isDarkMode` at the one call site.

### Scope held to color/theme

The only non-color edits are structural consequences of the color work: the deleted `_lightVariant` helpers and the new `isDark` parameter on `getRarityColor`. No control flow, no widget-tree restructuring, and no user-facing strings changed. The `isDark ? neon : light` pattern is applied consistently, so dark mode renders exactly as before.

</details>

<details>
<summary>File map</summary>

- `lib/theme/gamer_theme.dart` — retuned 7 light accents; added `adaptiveAccent`, `mutedText`, `mutedIcon`; `primary`/`secondary`/focused border now reference the constants.
- `lib/utils/structure_utils.dart` — `getRarityColor` gains `isDark` flag with light-mode variants.
- `lib/widgets/guide_tab.dart`, `edition_version_card.dart`, `search_buttons.dart` — removed local `_lightVariant`, routed accents through `adaptiveAccent`.
- `lib/widgets/structure_selection_card.dart`, `quick_start_card.dart`, `favorites_tab.dart` — card/section accents and rarity label via adaptive helpers.
- `lib/widgets/results_tab.dart` — muted greys → `mutedText`/`mutedIcon`; header icons via `greenText`; bookmark via `purpleText`.
- `lib/widgets/results_map_view.dart` — markers and axis labels adapted for light mode.
- `lib/widgets/app_info_dialog.dart`, `pro_upgrade_dialog.dart`, `recent_seeds_widget.dart`, `search_history_widget.dart`, `release_notes_tab.dart`, `ore_finder_screen.dart` — grey text/icons → helpers or fixed `#616161`.

Full diff: `git -C .worktrees/theme-rework diff 6e0539f..HEAD -- flutter_app/lib`

</details>
