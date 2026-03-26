# Implementation Plan: Bedwars Guide

## Overview

Add a Bedwars Guide tab to the Flutter app with three skill tiers (Starters, Practitioners, Experts). The implementation builds incrementally: data model and static content first, then the UI widgets, then integration into the existing tab navigation.

## Tasks

- [x] 1. Create the SkillTier enum and GuideSection data model
  - Create `flutter_app/lib/models/bedwars_guide_data.dart`
  - Define the `SkillTier` enum with values: `starters`, `practitioners`, `experts`
  - Map each tier to a display label and accent color (`GamerColors.neonGreen`, `GamerColors.neonCyan`, `GamerColors.neonPink`)
  - Define the `GuideSection` class with fields: `title` (String), `emoji` (String), `accentColor` (Color), `content` (List<String>)
  - Define static `List<GuideSection>` constants for each tier containing the 5 sections per tier as specified in the design
    - Starters: Game Objective & Rules, Basic Resource Gathering, Purchasing Essential Items, Basic Bed Defense, Basic Combat Tips
    - Practitioners: Efficient Resource Management & Upgrades, Intermediate Bed Defense, Team Coordination Strategies, Bridge-Building Techniques, Mid-Game Combat Tactics
    - Experts: Advanced PvP Combat, Speed-Bridging & Advanced Movement, Rush Strategies & Timing, Endgame Tactics & Resource Prioritization, Counter-Strategies Against Common Plays
  - _Requirements: 3.1, 3.2, 4.1, 4.2, 5.1, 5.2_

- [x] 2. Build the BedwarsGuideTab widget and TierSelector
  - [x] 2.1 Create the TierSelector widget
    - Create `flutter_app/lib/widgets/bedwars_guide_tab.dart`
    - Implement `TierSelector` as a `StatelessWidget` with props: `selectedTier`, `onTierChanged`, `isDarkMode`
    - Render three selectable chips/buttons for each `SkillTier` value
    - Highlight the selected tier using the tier's accent color from `GamerColors`
    - _Requirements: 2.1, 2.2, 6.3_

  - [x] 2.2 Create the BedwarsGuideTab StatefulWidget
    - Implement `BedwarsGuideTab` with `isDarkMode` parameter
    - Manage `_selectedTier` state, defaulting to `SkillTier.starters`
    - Layout: `TierSelector` pinned at top (not scrollable), guide content in a `SingleChildScrollView` below
    - Render guide sections as `GamerCard` widgets using the same card-building pattern from `GuideTab._buildGuideCard()`
    - Apply gradient background consistent with existing Guide tab styling
    - Support both dark and light mode via `isDarkMode`
    - _Requirements: 2.3, 2.4, 2.5, 3.3, 4.3, 5.3, 6.1, 6.2, 7.1, 7.2_

  - [x] 2.3 Write property test: All guide sections have required fields
    - **Property 1: All guide sections have required fields**
    - For any skill tier, every guide section must have non-empty `title`, non-empty `emoji`, and non-empty `content` list with at least one non-empty string
    - **Validates: Requirements 3.2, 4.2, 5.2**

  - [x] 2.4 Write property test: Tier selection displays correct content
    - **Property 2: Tier selection displays correct content**
    - For any `SkillTier` value, the guide sections returned must exactly match the predefined static content list for that tier (same length, same titles, same content)
    - **Validates: Requirements 2.3**

- [x] 3. Integrate BedwarsGuideTab into main navigation
  - In `flutter_app/lib/main.dart`:
    - Import `bedwars_guide_tab.dart`
    - Change `TabController(length: 4)` to `TabController(length: 5)`
    - Add `Tab(icon: Icon(Icons.sports_esports, size: 18), text: 'Bedwars', height: 48)` to the `TabBar` tabs list
    - Add `BedwarsGuideTab(isDarkMode: widget.isDarkMode)` to the `TabBarView` children
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 4. Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Write widget tests for the Bedwars Guide
  - [x] 5.1 Write unit tests for tab presence and navigation
    - Create `flutter_app/test/bedwars_guide_test.dart`
    - Verify the Bedwars tab appears in the TabBar with the correct icon (`Icons.sports_esports`) and "Bedwars" label
    - Verify tapping the Bedwars tab displays the guide content area
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 5.2 Write unit tests for tier selector and content
    - Verify all three tier options ("Starters", "Practitioners", "Experts") are displayed
    - Verify Starters is selected by default on first navigation
    - Verify each tier contains the correct 5 topic sections
    - Verify the widget builds without errors in both dark and light mode
    - _Requirements: 2.1, 2.4, 3.1, 4.1, 5.1, 6.1_

- [x] 6. Final checkpoint
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- The feature is purely presentational with static content — no services, state management, or data fetching needed
- Reuses existing `GamerCard` and `GamerSectionHeader` widgets from the theme
