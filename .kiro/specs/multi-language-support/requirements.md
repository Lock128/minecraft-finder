# Requirements Document

## Introduction

This feature adds multi-language support to the Gem, Ore & Struct Finder for MC Flutter application. Users will be able to switch the app's display language between English (default), German, Spanish, Japanese, and French from any screen. The selected language preference will persist across app restarts. Flutter's built-in localization framework (`flutter_localizations` and `intl` with ARB files) will be used to manage translations.

## Glossary

- **App**: The Gem, Ore & Struct Finder for MC Flutter application
- **Locale**: A combination of language and optional country code (e.g., `en`, `de`, `es`, `ja`, `fr`) that determines which translations the App displays
- **Language_Switcher**: A persistent UI control accessible from the AppBar on every screen that allows the user to change the active Locale
- **Localization_System**: The subsystem responsible for loading, resolving, and providing translated strings to all widgets, built on Flutter's `flutter_localizations` and `intl` packages with ARB files
- **Preferences_Service**: The existing `PreferencesService` class that persists user settings via `shared_preferences`
- **Supported_Languages**: English (en), German (de), Spanish (es), Japanese (ja), and French (fr)

## Requirements

### Requirement 1: Localization Infrastructure

**User Story:** As a developer, I want a localization infrastructure using Flutter's official localization framework, so that all user-facing strings can be translated and maintained in ARB files.

#### Acceptance Criteria

1. THE Localization_System SHALL provide translated strings for all five Supported_Languages (en, de, es, ja, fr)
2. THE Localization_System SHALL use ARB files as the source of truth for all translatable strings
3. THE Localization_System SHALL fall back to English when a translation key is missing for the active Locale
4. THE App SHALL declare `flutter_localizations` and `intl` as dependencies
5. THE App SHALL configure `localizationsDelegates` and `supportedLocales` in the MaterialApp widget

### Requirement 2: Language Switcher Accessibility

**User Story:** As a user, I want to change the app language from any screen, so that I do not have to navigate away from my current task to switch languages.

#### Acceptance Criteria

1. THE Language_Switcher SHALL be visible in the AppBar on every screen of the App
2. WHEN the user taps the Language_Switcher, THE App SHALL display a selection menu listing all five Supported_Languages with their native names (English, Deutsch, Español, 日本語, Français)
3. THE Language_Switcher SHALL indicate the currently active Locale in the selection menu
4. THE Language_Switcher SHALL use a globe icon or language icon that fits the existing gamer theme

### Requirement 3: Language Selection and Application

**User Story:** As a user, I want the entire app UI to update immediately when I select a new language, so that I can use the app in my preferred language without restarting.

#### Acceptance Criteria

1. WHEN the user selects a language from the Language_Switcher, THE App SHALL update all visible user-facing strings to the selected Locale without requiring a restart or navigation change
2. WHEN the user selects a language from the Language_Switcher, THE App SHALL rebuild the widget tree with the new Locale so that all tabs (Search, Results, User Guide, Bedwars, Updates) reflect the change
3. THE App SHALL set the active Locale on the MaterialApp widget so that Material component localizations (e.g., date pickers, back button semantics) also reflect the selected language

### Requirement 4: Language Preference Persistence

**User Story:** As a user, I want my language choice to be remembered, so that the app opens in my preferred language every time.

#### Acceptance Criteria

1. WHEN the user selects a language, THE Preferences_Service SHALL persist the selected Locale code to local storage
2. WHEN the App starts, THE Preferences_Service SHALL load the previously saved Locale code from local storage
3. IF no saved Locale exists, THEN THE App SHALL default to English (en)
4. WHEN the App starts with a saved Locale, THE App SHALL apply the saved Locale before rendering the first frame

### Requirement 5: String Extraction and Translation Coverage

**User Story:** As a developer, I want all hardcoded user-facing strings extracted into localization files, so that every piece of text in the app can be translated.

#### Acceptance Criteria

1. THE Localization_System SHALL provide translation keys for all user-facing strings in the following widgets: main.dart, search_tab.dart, search_buttons.dart, results_tab.dart, guide_tab.dart, bedwars_guide_tab.dart, app_info_dialog.dart, release_notes_tab.dart, ore_selection_card.dart, structure_selection_card.dart, world_settings_card.dart, search_center_card.dart, recent_seeds_widget.dart
2. THE Localization_System SHALL support parameterized strings for dynamic content (e.g., result counts, coordinate values, error messages)
3. THE English ARB file SHALL serve as the template containing all translation keys with descriptions
4. THE German, Spanish, Japanese, and French ARB files SHALL contain translations for all keys defined in the English template

### Requirement 6: Japanese Text Rendering

**User Story:** As a Japanese-speaking user, I want the app to render Japanese characters correctly, so that I can read all content without display issues.

#### Acceptance Criteria

1. WHEN the active Locale is Japanese (ja), THE App SHALL render all Japanese characters (Hiragana, Katakana, Kanji) without fallback glyphs or missing character indicators
2. THE App SHALL use fonts that support CJK (Chinese, Japanese, Korean) character sets when the active Locale is Japanese

### Requirement 7: Tab and Navigation Label Localization

**User Story:** As a user, I want the tab labels and navigation elements to be translated, so that I can navigate the app in my preferred language.

#### Acceptance Criteria

1. THE App SHALL display translated labels for all five tabs: Search, Results, User Guide, Bedwars, and Updates
2. THE App SHALL display a translated app title in the AppBar
3. WHEN the active Locale changes, THE App SHALL update all tab labels and the AppBar title to the new language

### Requirement 8: Error and Validation Message Localization

**User Story:** As a user, I want error messages and validation prompts to appear in my selected language, so that I can understand issues without knowing English.

#### Acceptance Criteria

1. WHEN a validation error occurs (e.g., empty seed, invalid coordinates), THE App SHALL display the error message in the active Locale
2. WHEN a search error occurs, THE App SHALL display the error SnackBar message in the active Locale
3. THE App SHALL display all SnackBar messages (warnings, errors, confirmations) in the active Locale
