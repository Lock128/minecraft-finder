# Tasks: Multi-Language Support

## Task 1: Set up localization infrastructure
- [x] 1.1 Add `flutter_localizations` and `intl` dependencies to `pubspec.yaml`
- [x] 1.2 Create `flutter_app/l10n.yaml` configuration file for `gen-l10n`
- [x] 1.3 Create `flutter_app/lib/l10n/app_en.arb` English template with all translation keys and `@` descriptions
- [x] 1.4 Create `flutter_app/lib/l10n/app_de.arb` with German translations
- [x] 1.5 Create `flutter_app/lib/l10n/app_es.arb` with Spanish translations
- [x] 1.6 Create `flutter_app/lib/l10n/app_ja.arb` with Japanese translations
- [x] 1.7 Create `flutter_app/lib/l10n/app_fr.arb` with French translations
- [x] 1.8 Run `flutter gen-l10n` to generate `AppLocalizations` class and verify no errors

## Task 2: Add locale persistence to PreferencesService
- [x] 2.1 Add `_localeKey`, `getLocale()`, and `saveLocale()` methods to `PreferencesService`
- [x] 2.2 Write unit tests for locale save/load round-trip and default fallback to English

## Task 3: Wire locale state into root widget
- [x] 3.1 Add `Locale? _locale` field and `_loadLocale()` / `_setLocale()` methods to `_GemOreStructFinderAppState`
- [x] 3.2 Configure `MaterialApp` with `localizationsDelegates`, `supportedLocales`, and `locale` properties
- [x] 3.3 Pass `_setLocale` callback down to `OreFinderScreen` and AppBar

## Task 4: Add language switcher to AppBar
- [x] 4.1 Create `PopupMenuButton<Locale>` language switcher widget in AppBar actions
- [x] 4.2 Display all five languages with native names and check mark for active locale
- [x] 4.3 Wire language selection to `_setLocale` callback and `PreferencesService.saveLocale`

## Task 5: Extract and replace hardcoded strings in main.dart
- [x] 5.1 Replace tab labels (Search, Results, User Guide, Bedwars, Updates) with `AppLocalizations` calls
- [x] 5.2 Replace AppBar title and snackbar messages with localized strings
- [x] 5.3 Replace validation error messages with localized strings

## Task 6: Extract and replace hardcoded strings in search widgets
- [x] 6.1 Replace strings in `world_settings_card.dart` (World Settings, World Seed, hints, validation)
- [x] 6.2 Replace strings in `search_center_card.dart` (Search Center, coordinate labels, radius, validation)
- [x] 6.3 Replace strings in `ore_selection_card.dart` (Ore Type, Include Ores, Netherite, Include Nether Gold, legend labels)
- [x] 6.4 Replace strings in `structure_selection_card.dart` (Structure Search, Include Structures, Select All, Clear All, structures selected)
- [x] 6.5 Replace strings in `search_buttons.dart` (Find, Find All Netherite, Searching..., info box text)
- [x] 6.6 Replace strings in `recent_seeds_widget.dart` (Recent Seeds)

## Task 7: Extract and replace hardcoded strings in results and content widgets
- [x] 7.1 Replace strings in `results_tab.dart` (loading messages, empty states, filter labels, result counts, copy tooltip)
- [x] 7.2 Replace strings in `guide_tab.dart` (all ore guide content, section titles, Pro Tip)
- [x] 7.3 Replace strings in `bedwars_guide_tab.dart` (all bedwars guide content)
- [x] 7.4 Replace strings in `app_info_dialog.dart` (About dialog, section titles, steps, features, support section)
- [x] 7.5 Replace strings in `release_notes_tab.dart` (release notes content)

## Task 8: Japanese font support
- [x] 8.1 Ensure the app includes or references fonts supporting CJK characters for Japanese locale
- [x] 8.2 Test Japanese text rendering across all screens

## Task 9: Write property-based and widget tests
- [x] 9.1 Write property test for translation completeness (Property 1): all keys × all locales return non-empty strings
- [x] 9.2 Write property test for locale persistence round-trip (Property 2): save then load returns same locale
- [x] 9.3 Write widget test for UI locale reactivity (Property 3): selecting each locale updates visible strings
- [x] 9.4 Write property test for parameterized string interpolation (Property 4): random params appear in output
- [x] 9.5 Write widget test for error message localization (Property 5): errors display in active locale
- [x] 9.6 Write widget test verifying language switcher presence and menu contents
