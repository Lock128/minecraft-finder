# Requirements Document

## Introduction

This feature adds Minecraft edition and version era selection to the Gem, Ore & Struct Finder app. The current app exclusively supports Java Edition 1.18+ ore generation, which uses Java's linear congruential generator (LCG) for RNG, Perlin noise with Java-compatible permutation tables, and triangular distribution curves for ore placement across the expanded world depth (-64 to 320). Bedrock Edition uses a different C++ RNG implementation, producing different ore placements for the same seed. Pre-1.18 versions used uniform ore distributions with fixed Y ranges (e.g., Y=12 sweet spot for diamonds) and a world depth of 0–256. This feature lets users select their edition and version era so the ore finder produces accurate results for their world.

## Glossary

- **App**: The Gem, Ore & Struct Finder Flutter application
- **Edition_Selector**: A UI control that allows the user to choose between Java Edition and Bedrock Edition
- **Version_Selector**: A UI control that allows the user to choose between Legacy (pre-1.18) and Modern (1.18+) version eras
- **Java_Edition**: The original Minecraft edition running on Java, using `java.util.Random` (a 48-bit linear congruential generator) for RNG
- **Bedrock_Edition**: The Minecraft edition running on C++, using a different RNG implementation that produces different ore placements for the same seed
- **Legacy_Era**: Minecraft versions before 1.18, which use uniform ore distributions with fixed Y ranges and a world height of 0–256
- **Modern_Era**: Minecraft versions 1.18 and later, which use triangular ore distributions with per-ore peak Y levels and an expanded world depth of -64 to 320
- **JavaRandom**: The existing Java-compatible LCG RNG class used by the App for seed-based random number generation
- **BedrockRandom**: A new RNG class that replicates Bedrock Edition's C++ random number generation behavior
- **RNG_Strategy**: An abstraction that allows the ore finder to use either JavaRandom or BedrockRandom depending on the selected edition
- **Uniform_Distribution**: The ore placement model used in Legacy_Era where ores spawn with equal probability across a fixed Y range
- **Triangular_Distribution**: The ore placement model used in Modern_Era where ore spawn probability peaks at a specific Y level and tapers linearly
- **DensityFunction**: The existing class that calculates ore density using Triangular_Distribution curves for Modern_Era
- **LegacyDensityFunction**: A new density function class that calculates ore density using Uniform_Distribution for Legacy_Era
- **OreFinder**: The existing class that orchestrates ore location searches
- **PreferencesService**: The existing service that persists user settings via SharedPreferences
- **Edition_Version_Card**: A new UI card widget that contains the Edition_Selector and Version_Selector controls
- **World_Settings_Card**: The existing UI card for world seed and coordinate input

## Requirements

### Requirement 1: Edition Selection

**User Story:** As a user, I want to select my Minecraft edition (Java or Bedrock), so that the ore finder uses the correct RNG for my world.

#### Acceptance Criteria

1. THE Edition_Version_Card SHALL display the Edition_Selector with two options: "Java Edition" and "Bedrock Edition"
2. WHEN the user selects Java_Edition, THE Edition_Selector SHALL visually indicate Java_Edition as the active selection
3. WHEN the user selects Bedrock_Edition, THE Edition_Selector SHALL visually indicate Bedrock_Edition as the active selection
4. WHEN the App launches and no saved preference exists, THE Edition_Selector SHALL default to Java_Edition
5. THE Edition_Selector SHALL use a segmented button control styled consistently with the App's GamerTheme

### Requirement 2: Version Era Selection

**User Story:** As a user, I want to select my Minecraft version era (pre-1.18 or 1.18+), so that the ore finder uses the correct distribution model for my world.

#### Acceptance Criteria

1. THE Edition_Version_Card SHALL display the Version_Selector with two options: "Pre-1.18 (Legacy)" and "1.18+ (Modern)"
2. WHEN the user selects Legacy_Era, THE Version_Selector SHALL visually indicate Legacy_Era as the active selection
3. WHEN the user selects Modern_Era, THE Version_Selector SHALL visually indicate Modern_Era as the active selection
4. WHEN the App launches and no saved preference exists, THE Version_Selector SHALL default to Modern_Era
5. THE Version_Selector SHALL use a segmented button control styled consistently with the App's GamerTheme

### Requirement 3: Bedrock-Compatible RNG

**User Story:** As a Bedrock Edition player, I want the ore finder to use Bedrock-compatible random number generation, so that the predicted ore locations match my Bedrock world.

#### Acceptance Criteria

1. THE App SHALL provide a BedrockRandom class that implements the same RNG interface as JavaRandom
2. WHEN Bedrock_Edition is selected, THE OreFinder SHALL use BedrockRandom for all seed-based random number generation
3. WHEN Java_Edition is selected, THE OreFinder SHALL use JavaRandom for all seed-based random number generation
4. THE BedrockRandom class SHALL produce a different sequence of random numbers than JavaRandom for the same seed input
5. THE App SHALL define an RNG_Strategy abstraction that both JavaRandom and BedrockRandom implement, allowing the OreFinder to use either without conditional branching on edition type

### Requirement 4: Legacy Uniform Ore Distribution

**User Story:** As a player on a pre-1.18 world, I want the ore finder to use the legacy uniform distribution model, so that the predicted ore locations match my older world.

#### Acceptance Criteria

1. THE App SHALL provide a LegacyDensityFunction class that calculates ore density using Uniform_Distribution within fixed Y ranges
2. WHEN Legacy_Era is selected, THE OreFinder SHALL use LegacyDensityFunction for ore density calculations
3. WHEN Modern_Era is selected, THE OreFinder SHALL use the existing DensityFunction (Triangular_Distribution) for ore density calculations
4. THE LegacyDensityFunction SHALL use the following Y ranges for each ore type: diamond (Y 1–15), gold (Y 1–31), iron (Y 1–63), coal (Y 1–127), redstone (Y 1–15), lapis (Y 14–30)
5. THE LegacyDensityFunction SHALL apply equal spawn probability across the entire valid Y range for each ore type (Uniform_Distribution)
6. WHEN Legacy_Era is selected, THE OreFinder SHALL restrict the world height to Y 0–256

### Requirement 5: Perlin Noise Edition Compatibility

**User Story:** As a user, I want the Perlin noise generation to use the correct RNG for my edition, so that terrain-dependent ore calculations are accurate.

#### Acceptance Criteria

1. WHEN Java_Edition is selected, THE PerlinNoise class SHALL generate its permutation table using JavaRandom
2. WHEN Bedrock_Edition is selected, THE PerlinNoise class SHALL generate its permutation table using BedrockRandom
3. THE PerlinNoise class SHALL accept an RNG_Strategy instance for permutation table generation instead of directly instantiating JavaRandom

### Requirement 6: Preference Persistence

**User Story:** As a user, I want my edition and version era selections to be remembered, so that I do not have to re-select them each time I open the app.

#### Acceptance Criteria

1. WHEN the user selects an edition, THE PreferencesService SHALL persist the selected edition value
2. WHEN the user selects a version era, THE PreferencesService SHALL persist the selected version era value
3. WHEN the App launches, THE PreferencesService SHALL load the previously saved edition and version era values
4. WHEN the App launches and no saved edition preference exists, THE PreferencesService SHALL return Java_Edition as the default
5. WHEN the App launches and no saved version era preference exists, THE PreferencesService SHALL return Modern_Era as the default

### Requirement 7: Accuracy Information Display

**User Story:** As a user, I want to see information about accuracy differences between editions and versions, so that I understand the limitations of the ore predictions.

#### Acceptance Criteria

1. WHEN the user selects Bedrock_Edition, THE Edition_Version_Card SHALL display an informational message stating that Bedrock ore prediction accuracy is approximate due to incomplete documentation of Bedrock's RNG internals
2. WHEN the user selects Legacy_Era, THE Edition_Version_Card SHALL display an informational message stating that legacy ore placement uses uniform distribution with the classic Y-level sweet spots
3. THE informational messages SHALL be styled as info boxes consistent with the existing info boxes in the SearchButtons widget
4. WHEN the user selects Java_Edition and Modern_Era, THE Edition_Version_Card SHALL NOT display any warning or informational message

### Requirement 8: OreFinder Edition and Version Integration

**User Story:** As a user, I want the ore search to automatically use the correct algorithms based on my edition and version selections, so that I get accurate results without manual configuration.

#### Acceptance Criteria

1. THE OreFinder.findOres method SHALL accept edition and version era parameters
2. WHEN a search is initiated, THE OreFinder SHALL select the appropriate RNG_Strategy based on the edition parameter
3. WHEN a search is initiated, THE OreFinder SHALL select the appropriate density function (DensityFunction or LegacyDensityFunction) based on the version era parameter
4. WHEN Legacy_Era and any edition are selected, THE OreFinder SHALL use the legacy Y ranges and Uniform_Distribution for ore placement
5. WHEN Modern_Era and any edition are selected, THE OreFinder SHALL use the 1.18+ Y ranges and Triangular_Distribution for ore placement

### Requirement 9: UI Placement and Theme Consistency

**User Story:** As a user, I want the edition and version selection to be visually integrated with the existing search interface, so that the experience feels cohesive.

#### Acceptance Criteria

1. THE Edition_Version_Card SHALL be positioned in the search tab above the World_Settings_Card
2. THE Edition_Version_Card SHALL render correctly in both dark mode and light mode, matching the App's existing GamerTheme styling
3. THE Edition_Version_Card SHALL use the GamerCard styling with a neon accent color and appropriate border glow effects
4. THE Edition_Version_Card SHALL display a section header with an appropriate emoji and the title "Edition & Version"
