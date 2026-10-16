# Requirements Document

## Introduction

The Minecraft Finder app currently produces a statistical *estimate* of ore and structure locations: it mixes a Java-compatible seed hash, an LCG or MT19937 RNG, and Perlin-noise scoring to rank "plausible" hot spots. These results are not the blocks or structures the real game would place, and the reported "probability %" is a fabricated score rather than a real likelihood.

This feature introduces a **seed-accurate world generation engine** that reproduces Minecraft's real structure positions, biome generation, and ore/feature placement for a given seed, version, and edition. Accuracy is delivered through a native FFI binding to Cubiomes on mobile and desktop platforms, paired with a pure-Dart engine on web that performs 64-bit math with `Int64` (`package:fixnum`) to avoid the web 53-bit precision trap. The two accurate code paths are kept in sync and validated against golden-seed fixtures per version.

The engine slots in behind the existing `SearchRunner` boundary via a new `WorldGenEngine` interface. The existing simulation is retained as a fast "Estimate" mode. When Accurate mode cannot run — on web where only the FFI path is available, or for a version that is unsupported or unverified — the system automatically falls back to Estimate mode and surfaces a visible notice. Delivery is staged across milestones: a spike, Java structures (1.18–1.20), Java biomes, Java ores, version expansion (1.16/1.17 then 1.21+), a Bedrock track, and UX changes.

## Glossary

- **WorldGen_Engine**: The interface exposing `findStructures` and `findOres`, behind which concrete engines are selected. Replaces direct calls from the search layer.
- **Simulated_Engine**: The existing statistical implementation (`ore_finder.dart`, `structure_finder.dart`), retained as the "Estimate" mode and usable for any version.
- **Accurate_Engine**: The new seed-accurate implementation, delivered as a native FFI binding to Cubiomes and a pure-Dart web engine.
- **Native_FFI_Path**: The `dart:ffi` binding to compiled Cubiomes, available on iOS, Android, macOS, Windows, and Linux.
- **Dart_Web_Path**: The pure-Dart accurate engine used on web, performing all seed and RNG math with `Int64` from `package:fixnum`.
- **Search_Runner**: The existing dispatch boundary (`search_runner.dart`) that routes search work, including isolate/`compute` offloading.
- **Version_Strategy**: A per-version object that supplies placement tables, salts, and RNG parameters for a specific Minecraft version.
- **Version_Availability**: The module (`version_availability.dart`) that enumerates supported versions and content availability, expanded from coarse eras to an explicit version list.
- **Golden_Seed_Fixture**: A stored test fixture pairing a known seed and version with authoritative structure positions, biome values, and ore placements.
- **Accurate_Mode**: User-facing mode that uses the Accurate_Engine for supported, verified versions.
- **Estimate_Mode**: User-facing mode that uses the Simulated_Engine for any version.
- **Supported_Version**: A Minecraft version and edition that has a Version_Strategy and a passing Golden_Seed_Fixture set.
- **Verified_Version**: A Supported_Version whose Accurate_Engine output passes all its Golden_Seed_Fixture tests in CI.

## Requirements

### Requirement 1: Engine abstraction behind the search boundary

**User Story:** As a developer, I want the search layer to call a single engine interface, so that the simulated and accurate engines are interchangeable without changing the search layer.

#### Acceptance Criteria

1. THE WorldGen_Engine SHALL expose a `findStructures` operation and a `findOres` operation.
2. THE Search_Runner SHALL invoke ore and structure searches exclusively through the WorldGen_Engine interface.
3. THE Simulated_Engine SHALL implement the WorldGen_Engine interface using the existing statistical implementation.
4. THE Accurate_Engine SHALL implement the WorldGen_Engine interface.
5. WHEN a search is dispatched, THE Search_Runner SHALL select exactly one WorldGen_Engine implementation based on the requested mode, version, edition, and platform.
6. WHERE the WorldGen_Engine performs a search, THE Search_Runner SHALL preserve the existing isolate offloading used for heavy work.

### Requirement 2: Native FFI accurate engine

**User Story:** As a user on mobile or desktop, I want accurate results computed by a proven native library, so that positions match the real game quickly.

#### Acceptance Criteria

1. WHERE the platform is iOS, Android, macOS, Windows, or Linux, THE Accurate_Engine SHALL compute results through the Native_FFI_Path bound to Cubiomes.
2. THE Native_FFI_Path SHALL return structure positions as exact chunk and block coordinates for each Supported_Version.
3. THE Native_FFI_Path SHALL return ore placements as exact block coordinates for each Supported_Version.
4. THE build pipeline SHALL compile the Cubiomes native library for iOS, Android, macOS, Windows, and Linux.
5. IF the Native_FFI_Path library fails to load, THEN THE Accurate_Engine SHALL report an engine-unavailable condition to the Search_Runner.

### Requirement 3: Pure-Dart web accurate engine with 64-bit math

**User Story:** As a user on web, I want accurate results without native code, so that the app stays accurate in the browser where FFI is unavailable.

#### Acceptance Criteria

1. WHERE the platform is web, THE Accurate_Engine SHALL compute results through the Dart_Web_Path.
2. THE Dart_Web_Path SHALL perform all seed-mixing and RNG state arithmetic using `Int64` from `package:fixnum`.
3. WHEN the Dart_Web_Path and the Native_FFI_Path process the same seed, version, and edition, THE Accurate_Engine SHALL produce identical structure positions.
4. WHEN the Dart_Web_Path and the Native_FFI_Path process the same seed, version, and edition, THE Accurate_Engine SHALL produce identical ore placements.
5. THE Dart_Web_Path SHALL reproduce the `java.util.Random` sequence for a given seed without precision loss above 2^53.

### Requirement 4: Versioned engine and version availability

**User Story:** As a user, I want to pick a specific Minecraft version, so that results match the version I play.

#### Acceptance Criteria

1. THE Version_Availability module SHALL enumerate Supported_Versions as an explicit version list rather than coarse eras.
2. THE Accurate_Engine SHALL select a Version_Strategy that supplies placement tables, salts, and RNG parameters for the requested version and edition.
3. WHERE a requested version is a Supported_Version, THE Accurate_Engine SHALL compute results using that version's Version_Strategy.
4. IF a requested version has no Version_Strategy, THEN THE Accurate_Engine SHALL report an unsupported-version condition to the Search_Runner.

### Requirement 5: Automatic degradation to Estimate mode

**User Story:** As a user, I want the app to fall back gracefully and tell me why, so that I always get a result and understand its accuracy.

#### Acceptance Criteria

1. IF Accurate_Mode is requested on web and the Dart_Web_Path cannot run the requested version, THEN THE Search_Runner SHALL route the search through the Simulated_Engine.
2. IF Accurate_Mode is requested for a version that is not a Verified_Version, THEN THE Search_Runner SHALL route the search through the Simulated_Engine.
3. IF the Accurate_Engine reports an engine-unavailable condition, THEN THE Search_Runner SHALL route the search through the Simulated_Engine.
4. WHEN the Search_Runner routes an Accurate_Mode request through the Simulated_Engine, THE application SHALL display an Estimate-mode notice that states the reason for the fallback.

### Requirement 6: Spike validation

**User Story:** As a developer, I want a proof that 64-bit RNG and one structure match a golden seed on both native and web, so that the approach is validated before full build-out.

#### Acceptance Criteria

1. THE spike SHALL produce a village position for a known Java 1.20 seed that matches its Golden_Seed_Fixture on the Native_FFI_Path.
2. THE spike SHALL produce a village position for the same Java 1.20 seed that matches its Golden_Seed_Fixture on the Dart_Web_Path.
3. WHEN the spike runs, THE Accurate_Engine SHALL pass at least one green golden structure test on both the Native_FFI_Path and the Dart_Web_Path.

### Requirement 7: Java structures for 1.18–1.20 (M1)

**User Story:** As a user on Java 1.18–1.20, I want exact structure positions, so that I can navigate to real structures.

#### Acceptance Criteria

1. WHERE the requested version is Java 1.18, 1.19, or 1.20, THE Accurate_Engine SHALL return exact positions for region-grid structures.
2. WHERE the requested version is Java 1.18, 1.19, or 1.20, THE Accurate_Engine SHALL return exact stronghold ring positions.
3. WHERE the requested version is Java 1.18, 1.19, or 1.20, THE Accurate_Engine SHALL return exact buried treasure positions.
4. WHEN the Accurate_Engine returns a structure for a Golden_Seed_Fixture in Java 1.18–1.20, THE returned chunk and block position SHALL match the fixture position.

### Requirement 8: Java biomes for 1.18–1.20 (M2)

**User Story:** As a user on Java 1.18–1.20, I want biome-gated structures to use real biomes, so that structure placement reflects the actual world.

#### Acceptance Criteria

1. WHERE the requested version is Java 1.18, 1.19, or 1.20, THE Accurate_Engine SHALL compute multi-noise climate biomes.
2. WHEN the Accurate_Engine evaluates a biome-gated structure in Java 1.18–1.20, THE Accurate_Engine SHALL use the computed biome at the candidate position.
3. WHEN the Accurate_Engine returns a biome at a Golden_Seed_Fixture coordinate in Java 1.18–1.20, THE returned biome SHALL match the fixture biome.

### Requirement 9: Java ores for 1.18–1.20 (M3)

**User Story:** As a user on Java 1.18–1.20, I want real ore and vein placements, so that I can mine at actual ore locations.

#### Acceptance Criteria

1. WHERE the requested version is Java 1.18, 1.19, or 1.20, THE Accurate_Engine SHALL place ore features using the real per-chunk count and tries feature loops.
2. WHEN the Accurate_Engine returns an ore placement for a Golden_Seed_Fixture in Java 1.18–1.20, THE returned block coordinate SHALL match the fixture placement.
3. WHEN the Accurate_Engine returns a vein for a Supported_Version, THE Accurate_Engine SHALL report the vein size as metadata.

### Requirement 10: Version expansion (M4)

**User Story:** As a user on other Java versions, I want accurate results for 1.16/1.17 and 1.21+, so that more versions are supported.

#### Acceptance Criteria

1. WHERE the requested version is Java 1.16 or 1.17, THE Accurate_Engine SHALL return exact structure, biome, and ore results using that version's Version_Strategy.
2. WHERE the requested version is Java 1.21 or later and a Version_Strategy exists, THE Accurate_Engine SHALL return exact structure, biome, and ore results for that version.
3. WHEN a version is added as a Supported_Version, THE version SHALL include its own Golden_Seed_Fixture set.

### Requirement 11: Bedrock track (M5)

**User Story:** As a Bedrock user, I want accurate results for Bedrock seeds, so that Bedrock worlds are supported.

#### Acceptance Criteria

1. WHERE the requested edition is Bedrock and a Bedrock Version_Strategy exists, THE Accurate_Engine SHALL compute results using Bedrock seed handling and the MT19937 RNG.
2. WHEN the Accurate_Engine returns a Bedrock result for a Golden_Seed_Fixture, THE returned position SHALL match the fixture position.
3. IF the requested Bedrock edition and version has no Version_Strategy, THEN THE Search_Runner SHALL route the search through the Simulated_Engine with an Estimate-mode notice.

### Requirement 12: UX for accurate results (M6)

**User Story:** As a user, I want to choose a version and mode and see honest metadata, so that I trust the results.

#### Acceptance Criteria

1. THE application SHALL present a version picker populated from the Version_Availability version list.
2. THE application SHALL present an Accurate and Estimate mode toggle.
3. WHILE the application displays Accurate_Mode results, THE application SHALL omit the fabricated probability percentage.
4. WHILE the application displays Accurate_Mode results, THE application SHALL display real metadata including vein size and structure variant where available.
5. WHERE the displayed results are from a Verified_Version in Accurate_Mode, THE application SHALL omit the estimate disclaimer.

### Requirement 13: Golden-seed and conformance testing

**User Story:** As a developer, I want golden and conformance tests in CI, so that accuracy is proven and protected against regressions.

#### Acceptance Criteria

1. THE test suite SHALL include a Golden_Seed_Fixture set for each Supported_Version.
2. THE test suite SHALL assert that the Accurate_Engine returns the fixture structure positions for each Golden_Seed_Fixture.
3. THE test suite SHALL assert that the Accurate_Engine returns the fixture biome values for each Golden_Seed_Fixture.
4. THE test suite SHALL assert that the Accurate_Engine returns the fixture ore placements for each Golden_Seed_Fixture.
5. THE test suite SHALL assert that the RNG output matches known `java.util.Random` sequences, including on the Dart_Web_Path.
6. WHEN a new Supported_Version is added, THE CI pipeline SHALL run that version's Golden_Seed_Fixture tests alongside all existing versions.
7. THE test suite SHALL retain the existing determinism and version-gating tests in `test/models/search_version_gating_test.dart` for the Simulated_Engine.
