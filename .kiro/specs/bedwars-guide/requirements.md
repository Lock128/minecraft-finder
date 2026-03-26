# Requirements Document

## Introduction

This feature adds a Bedwars Guide to the Gem, Ore & Struct Finder Flutter application. The guide provides gameplay guidance for Minecraft Bedwars across three skill tiers: Starters, Practitioners, and Experts. Users access the guide through a new tab in the app's main navigation and can select which tier of content to view. The guide content covers strategies, tips, and recommended actions for each skill level.

## Glossary

- **App**: The Gem, Ore & Struct Finder Flutter application
- **Bedwars_Guide_Tab**: The new tab added to the App's main TabBar navigation that hosts the Bedwars guide content
- **Tier_Selector**: A UI control that allows the user to choose between the three skill tiers
- **Skill_Tier**: One of three content categories — Starters, Practitioners, or Experts — representing increasing levels of Bedwars gameplay proficiency
- **Starters_Tier**: The beginner skill tier containing introductory Bedwars guidance for new players
- **Practitioners_Tier**: The intermediate skill tier containing guidance for players with basic Bedwars experience
- **Experts_Tier**: The advanced skill tier containing guidance for experienced Bedwars players
- **Guide_Section**: A distinct topic area within a skill tier (e.g., resource gathering, base defense, combat)
- **TabBar**: The existing horizontal tab navigation bar in the App containing Search, Results, Guide, and Updates tabs

## Requirements

### Requirement 1: Bedwars Guide Tab in Navigation

**User Story:** As a user, I want to see a Bedwars Guide tab in the app navigation, so that I can access Bedwars gameplay guidance alongside the existing features.

#### Acceptance Criteria

1. THE App SHALL display a Bedwars_Guide_Tab in the main TabBar navigation
2. THE Bedwars_Guide_Tab SHALL display an icon and the label "Bedwars" in the TabBar
3. WHEN the user taps the Bedwars_Guide_Tab, THE App SHALL display the Bedwars guide content area
4. THE Bedwars_Guide_Tab SHALL follow the same visual styling as the existing tabs in the TabBar (neon gamer theme, dark/light mode support)

### Requirement 2: Skill Tier Selection

**User Story:** As a user, I want to choose between Starters, Practitioners, and Experts tiers, so that I can view Bedwars guidance appropriate to my skill level.

#### Acceptance Criteria

1. WHEN the user navigates to the Bedwars_Guide_Tab, THE Tier_Selector SHALL display three selectable options: "Starters", "Practitioners", and "Experts"
2. THE Tier_Selector SHALL visually indicate which Skill_Tier is currently selected
3. WHEN the user selects a Skill_Tier, THE Bedwars_Guide_Tab SHALL display the guide content for the selected Skill_Tier
4. WHEN the user first navigates to the Bedwars_Guide_Tab, THE Tier_Selector SHALL have the Starters_Tier selected by default
5. THE Tier_Selector SHALL remain visible while the user scrolls through guide content, allowing the user to switch tiers at any time

### Requirement 3: Starters Tier Content

**User Story:** As a beginner Bedwars player, I want to read introductory guidance, so that I can understand the basics of Bedwars gameplay.

#### Acceptance Criteria

1. THE Starters_Tier SHALL contain Guide_Sections covering: game objective and rules, basic resource gathering (iron and gold), purchasing essential items from the shop, basic bed defense strategies, and basic combat tips
2. EACH Guide_Section in the Starters_Tier SHALL include a title, an icon or emoji, and descriptive text explaining the topic
3. THE Starters_Tier content SHALL be presented in a scrollable list of cards styled consistently with the App's gamer theme

### Requirement 4: Practitioners Tier Content

**User Story:** As an intermediate Bedwars player, I want to read guidance on improving my gameplay, so that I can advance my Bedwars skills.

#### Acceptance Criteria

1. THE Practitioners_Tier SHALL contain Guide_Sections covering: efficient resource management and upgrades, intermediate bed defense techniques (layering, obsidian usage), team coordination strategies, bridge-building techniques, and mid-game combat tactics
2. EACH Guide_Section in the Practitioners_Tier SHALL include a title, an icon or emoji, and descriptive text explaining the topic
3. THE Practitioners_Tier content SHALL be presented in a scrollable list of cards styled consistently with the App's gamer theme

### Requirement 5: Experts Tier Content

**User Story:** As an advanced Bedwars player, I want to read expert-level strategies, so that I can optimize my Bedwars gameplay.

#### Acceptance Criteria

1. THE Experts_Tier SHALL contain Guide_Sections covering: advanced PvP combat techniques (strafing, combos, rod usage), speed-bridging and advanced movement, rush strategies and timing, endgame tactics and resource prioritization, and counter-strategies against common opponent plays
2. EACH Guide_Section in the Experts_Tier SHALL include a title, an icon or emoji, and descriptive text explaining the topic
3. THE Experts_Tier content SHALL be presented in a scrollable list of cards styled consistently with the App's gamer theme

### Requirement 6: Theme Consistency

**User Story:** As a user, I want the Bedwars guide to match the app's visual style, so that the experience feels cohesive.

#### Acceptance Criteria

1. THE Bedwars_Guide_Tab SHALL render correctly in both dark mode and light mode, matching the App's existing GamerTheme styling
2. THE Guide_Section cards SHALL use the GamerCard styling with neon accent colors and appropriate border glow effects
3. THE Tier_Selector SHALL use accent colors consistent with the App's neon color palette (GamerColors)

### Requirement 7: Scrollable Guide Content

**User Story:** As a user, I want to scroll through the guide content smoothly, so that I can read all the guidance for my selected tier.

#### Acceptance Criteria

1. WHEN the selected Skill_Tier contains more content than fits on screen, THE Bedwars_Guide_Tab SHALL allow the user to scroll vertically through the Guide_Sections
2. THE Bedwars_Guide_Tab SHALL display a gradient background consistent with the existing Guide tab styling while the user scrolls
