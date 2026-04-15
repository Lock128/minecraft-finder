# Implementation Plan: Edition & Version Selection

## Overview

Add Minecraft edition (Java/Bedrock) and version era (Legacy pre-1.18 / Modern 1.18+) selection to the ore finder app. This involves creating an RNG strategy abstraction, a Bedrock-compatible RNG, a legacy density function, a new UI card with segmented buttons, preference persistence, and wiring everything into OreFinder and PerlinNoise.

## Tasks

- [x] 1. Define enums and GameRandom abstract interface
  - [x] 1.1 Create `flutter_app/lib/models/game_random.dart` with `MinecraftEdition` and `VersionEra` enums, and the `GameRandom` abstract class with `forEdition` factory
    - Define `MinecraftEdition { java, bedrock }` and `VersionEra { legacy, modern }`
    - Define abstract methods: `setSeed`, `nextInt`, `nextLong`, `nextDouble`, `nextFloat`, `nextBool`
    - Add `factory GameRandom.forEdition(MinecraftEdition edition, int seed)` that returns `JavaRandom` or `BedrockRandom`
    - _Requirements: 3.1, 3.5_

  - [x] 1.2 Refactor `JavaRandom` in `flutter_app/lib/models/java_random.dart` to implement `GameRandom`
    - Add `implements GameRandom` to the class declaration
    - Ensure all abstract methods are satisfied (existing methods already match)
    - Keep `MinecraftRandom` utility class unchanged
    - _Requirements: 3.3, 3.5_

- [x] 2. Implement BedrockRandom
  - [x] 2.1 Create `flutter_app/lib/models/bedrock_random.dart` implementing `GameRandom`
    - Implement MT19937 (32-bit Mersenne Twister) with 624-element state array
    - Implement `setSeed`, `nextInt` (rejection sampling), `nextLong`, `nextDouble`, `nextFloat`, `nextBool`
    - Throw `ArgumentError` for `nextInt(bound)` when `bound <= 0`
    - _Requirements: 3.1, 3.2, 3.4_

  - [x] 2.2 Write property test: GameRandom output range invariants
    - **Property 1: GameRandom output range invariants**
    - For any GameRandom implementation, any valid seed, and any positive bound: `nextInt(bound)` ∈ [0, bound), `nextDouble()` ∈ [0.0, 1.0), `nextFloat()` ∈ [0.0, 1.0)
    - **Validates: Requirements 3.1**

  - [x] 2.3 Write property test: BedrockRandom and JavaRandom produce divergent sequences
    - **Property 2: BedrockRandom and JavaRandom produce divergent sequences**
    - For any seed, calling `nextLong()` three times on each should produce at least one differing value
    - **Validates: Requirements 3.4**

  - [x] 2.4 Write unit tests for BedrockRandom
    - Verify known MT19937 output values for specific seeds against C++ reference values
    - Test `ArgumentError` on `nextInt(0)` and `nextInt(-1)`
    - _Requirements: 3.1, 3.4_

- [x] 3. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Implement LegacyDensityFunction and update PerlinNoise
  - [x] 4.1 Create `flutter_app/lib/models/legacy_density_function.dart`
    - Implement `LegacyDensityFunction` with `getOreDensity(double x, double y, double z, String oreType)`
    - Use uniform distribution within fixed Y ranges: diamond 1–15, gold 1–31, iron 1–63, coal 1–127, redstone 1–15, lapis 14–30
    - Return 0.0 for Y values outside the valid range
    - Accept optional `GameRandom` for PerlinNoise construction
    - _Requirements: 4.1, 4.4, 4.5_

  - [x] 4.2 Update `PerlinNoise` in `flutter_app/lib/models/noise.dart` to accept optional `GameRandom`
    - Add optional `GameRandom? rng` parameter to constructor
    - Update `_generatePermutation` to use provided `GameRandom` or fall back to `JavaRandom`
    - _Requirements: 5.1, 5.2, 5.3_

  - [x] 4.3 Write property test: LegacyDensityFunction uniform range correctness
    - **Property 3: LegacyDensityFunction uniform range correctness**
    - For any ore type and Y coordinate: density > 0 inside legacy range, density == 0 outside; Y-factor is uniform within range
    - **Validates: Requirements 4.1, 4.4, 4.5**

  - [x] 4.4 Write unit tests for LegacyDensityFunction
    - Test each ore type returns non-zero density within its Y range
    - Test each ore type returns 0.0 outside its Y range
    - Test boundary values (e.g., diamond at Y=1, Y=15, Y=0, Y=16)
    - _Requirements: 4.1, 4.4, 4.5_

- [x] 5. Extend PreferencesService for edition and version era persistence
  - [x] 5.1 Add edition and version era methods to `flutter_app/lib/utils/preferences_service.dart`
    - Add `_editionKey` and `_versionEraKey` constants
    - Implement `getEdition()` returning `MinecraftEdition` (default: `java`)
    - Implement `saveEdition(MinecraftEdition edition)`
    - Implement `getVersionEra()` returning `VersionEra` (default: `modern`)
    - Implement `saveVersionEra(VersionEra era)`
    - Handle invalid/corrupt stored strings by returning defaults
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

  - [x] 5.2 Write property test: Edition and version era preference round-trip
    - **Property 4: Edition and version era preference round-trip**
    - For any `MinecraftEdition` value, save then load returns the same value; same for `VersionEra`
    - **Validates: Requirements 6.1, 6.2**

- [x] 6. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Update OreFinder to accept edition and version era
  - [x] 7.1 Update `OreFinder.findOres` in `flutter_app/lib/models/ore_finder.dart`
    - Add `MinecraftEdition edition` and `VersionEra versionEra` parameters with defaults (`java`, `modern`)
    - Create `GameRandom` via `GameRandom.forEdition(edition, worldSeed)`
    - Pass `GameRandom` to `PerlinNoise` and density function constructors
    - Select `DensityFunction` (modern) or `LegacyDensityFunction` (legacy) based on `versionEra`
    - When legacy, restrict world height to 0–256 and use legacy Y ranges in `_getYRange`
    - Update `findAllNetherite` and `getNetheriteStats` similarly
    - Update `_calculateOreProbability` to use the selected `GameRandom` instead of hardcoded `JavaRandom`
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 4.2, 4.3, 4.6_

  - [x] 7.2 Write property test: Legacy mode restricts ore locations to legacy Y ranges
    - **Property 5: Legacy mode restricts ore locations to legacy Y ranges**
    - For any edition and ore type in legacy mode, all returned ore locations have Y within legacy range and world height 0–256
    - **Validates: Requirements 4.6, 8.4**

  - [x] 7.3 Write property test: Modern mode restricts ore locations to modern Y ranges
    - **Property 6: Modern mode restricts ore locations to modern Y ranges**
    - For any edition and ore type in modern mode, all returned ore locations have Y within modern 1.18+ range (-64 to 320)
    - **Validates: Requirements 8.5**

- [x] 8. Create EditionVersionCard widget
  - [x] 8.1 Create `flutter_app/lib/widgets/edition_version_card.dart`
    - Use `GamerCard` with `GamerColors.neonOrange` accent
    - Add `GamerSectionHeader` with emoji `🎮` and title "Edition & Version"
    - Add `SegmentedButton<MinecraftEdition>` with "Java Edition" / "Bedrock Edition" segments
    - Add `SegmentedButton<VersionEra>` with "Pre-1.18 (Legacy)" / "1.18+ (Modern)" segments
    - Add conditional info box when Bedrock is selected (approximate accuracy warning)
    - Add conditional info box when Legacy is selected (uniform distribution info with classic Y-level sweet spots)
    - Hide info boxes when Java + Modern is selected
    - Style info boxes like `SearchButtons._buildInfoBox`
    - Accept callbacks for selection changes and `isDarkMode` parameter
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 7.1, 7.2, 7.3, 7.4, 9.3, 9.4_

  - [x] 8.2 Write widget tests for EditionVersionCard
    - Test default selections (Java, Modern)
    - Test segment label text and selection state changes
    - Test info box visibility for each edition/version combination
    - Test dark mode and light mode rendering
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 7.1, 7.2, 7.3, 7.4_

- [x] 9. Integrate EditionVersionCard into SearchTab and wire to OreFinder
  - [x] 9.1 Update `flutter_app/lib/widgets/search_tab.dart` to include EditionVersionCard
    - Add `MinecraftEdition` and `VersionEra` state/parameters to `SearchTab`
    - Place `EditionVersionCard` above `WorldSettingsCard` in the column
    - Load saved preferences on init via `PreferencesService`
    - Save preferences on selection change
    - Pass edition and version era through to the search callback / `OreFinder.findOres`
    - _Requirements: 9.1, 9.2, 6.1, 6.2, 6.3_

  - [x] 9.2 Update the parent widget that calls `SearchTab` to pass edition and version era to `OreFinder.findOres`
    - Thread `edition` and `versionEra` from SearchTab state through to the `findOres` call site
    - _Requirements: 8.1, 8.2, 8.3_

  - [x] 9.3 Write integration tests
    - Test selecting Bedrock + Legacy, running a search, verifying results use legacy Y ranges
    - Test selecting Java + Modern (default), verifying results match current behavior
    - Test preference persistence across simulated app restart
    - _Requirements: 8.4, 8.5, 6.3_

- [x] 10. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- The existing `JavaRandom` and `DensityFunction` behavior is preserved as the default (backward compatible)
