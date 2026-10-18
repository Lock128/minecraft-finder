# Theme Rework — Verification Note

Scope: colors/theme/contrast only. No app logic, layout structure, widget trees,
or user-facing copy were changed. Dark-mode neon accents are untouched (all
`neon*` / `*Neon` / `dark*` constants and every dark-mode branch are unchanged).

## Commands run (from `.worktrees/theme-rework/flutter_app`)

- `flutter analyze` → **No issues found!** (baseline was also clean, so no new
  errors/warnings introduced).
- `flutter test` → **All 486 tests passed.**

### Golden / screenshot harness

`test/golden_screenshot.dart` is a smoke test (it only asserts the app builds
and finds a title string); it does **not** call `matchesGoldenFile`. A repo-wide
grep for `matchesGoldenFile` returns no matches, so there are no pixel-comparison
golden tests that color changes could break. The `test/*.png` files are device
screenshots produced by the separate `generate_screenshots` workflow, not golden
comparison fixtures. Therefore `flutter test --update-goldens` was **not needed**
and was not run. The full `flutter test` suite passed unchanged.

## Contrast ratios (WCAG; AA = 4.5:1 normal text, 3:1 large text/icons)

Backgrounds: lightBg `#F0F2F5` (scaffold) < lightCard `#F8F9FC` (cards) <
lightSurface/white `#FFFFFF` (inputs/headers). Ratios below are on lightCard
(the surface the result/value text actually sits on) unless noted; every value
also clears AA on the darker lightBg and on white.

### Ore / accent light variants (text + value labels)

| color (use)                 | old (card) | new (card) | AA |
|-----------------------------|-----------:|-----------:|----|
| lightGreen (primary, nav)   | 4.40 FAIL  | 5.20       | PASS |
| lightCyan                   | 3.95 FAIL  | 5.37       | PASS |
| lightOrange (structure val) | 3.79 FAIL  | 4.96       | PASS |
| lightYellow ("Vein size")   | 4.27 FAIL  | 5.35       | PASS |
| lightGold (gem value)       | 3.43 FAIL  | 5.05       | PASS |
| lightDiamond (gem value)    | 4.79       | 5.87       | PASS |
| lightIron                   | 5.13       | 6.03       | PASS |
| lightLapis (unchanged)      | 5.46       | 5.46       | PASS |
| lightRedstone (unchanged)   | 5.34       | 5.34       | PASS |
| lightPurple (unchanged)     | 7.24       | 7.24       | PASS |
| lightNetherite (unchanged)  | 5.99       | 5.99       | PASS |
| lightCoal (unchanged)       | 6.88       | 6.88       | PASS |

lightDiamond `#00698C` (bluer) and lightCyan `#00727F` (greener) are kept as
distinct teals, mirroring diamondNeon vs neonCyan in dark mode.

### Muted grey labels (chunk coords, biome, copy/bookmark icons, nav labels)

| pair | before | after | AA |
|------|-------:|------:|----|
| chunk/biome/count labels: `Colors.grey[500] #9E9E9E` → `onSurface@0.70` | 2.54 FAIL | 6.14 | PASS |
| copy/empty icons: `Colors.grey[400] #BDBDBD` → `onSurface@0.70` (icons @0.55 for the large 64px empty-state glyphs = ~3.6, meets the 3:1 graphical bar) | 1.78 FAIL | 6.14 | PASS |
| nav/tab unselected label, map axis labels, dialog captions: `grey[500]` → fixed `#616161` | 2.54 FAIL | 6.19 (on white) | PASS |

Dark mode keeps `Colors.white54/70` (unchanged) — those already pass on dark
surfaces.

### Experimental / mode-notice banner

Body text already used `onSurface.withValues(alpha: 0.85)` = **10.40** (PASS).
The banner **icon** previously rendered the raw neon accent on the near-white
banner tint; it now routes through `GamerColors.adaptiveAccent`, so it uses the
readable light variant (e.g. lightOrange 4.96 / lightGreen 5.20) in light mode.

### Structure rarity labels (10px text on chip bg `#FAFAFA`)

| rarity | old | new | AA |
|--------|----:|----:|----|
| Very Common | 2.66 FAIL | 4.91 | PASS |
| Common      | 2.01 FAIL | 4.90 | PASS |
| Uncommon    | 2.06 FAIL | 4.81 | PASS |
| Rare        | 3.53 FAIL | 5.39 | PASS |
| Very Rare   | 6.04      | 7.30 | PASS |

`StructureUtils.getRarityColor` gained an `isDark` flag (default `true`): dark
mode returns the original vivid Material colors unchanged; light mode returns the
darker readable variants above.

## How colors are routed (reduced hardcoded hex)

- `GamerColors.adaptiveAccent(neon, isDark)` centralizes the neon→light mapping.
  The three duplicated local `_lightVariant()` maps (guide_tab, edition_version_card,
  search_buttons) were removed and replaced with it; it also now backs the card
  border, section-bar, and accent colors that previously stayed neon in light mode.
- `GamerColors.mutedText(context)` / `mutedIcon(context)` route muted greys
  through `ColorScheme.onSurface`, replacing hardcoded `Colors.grey[400/500]`
  text/icons in light mode (dark-mode `white54/70` branches preserved).

## Temporary files

A throwaway TypeScript contrast helper (`contrast.ts`) was used to compute the
ratios above and then deleted.
