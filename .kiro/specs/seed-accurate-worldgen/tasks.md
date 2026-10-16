# Implementation Plan: Seed-Accurate World Generation

## Overview

This plan builds the seed-accurate world generation engine behind the existing `SearchRunner` boundary, following the design's staged roadmap: **Spike → M1 Java structures (1.18–1.20) → M2 Java biomes → M3 Java ores → M4 version expansion → M5 Bedrock → M6 UX**.

All implementation and test code is Dart under `flutter_app/`, with native C/Cubiomes bound via `dart:ffi`. Each milestone builds on the previous: foundational contracts and the spike land first, then one accurate capability area per milestone, then UX. Later milestones (M4 version expansion, M5 Bedrock) and research-heavy pieces are marked optional (`*`) so the required set — foundation + spike + M1/M2/M3 Java + core UX — forms a coherent first deliverable.

Property tests reference the 20 correctness properties from the design and run ≥ 100 iterations each; RNG conformance additionally runs on the web/JS target. The existing `test/models/search_version_gating_test.dart` is retained unchanged throughout.

## Tasks

- [x] 1. Foundation: engine contracts, queries, and result types
  - [x] 1.1 Define the WorldGenEngine interface and query/result types
    - Create `flutter_app/lib/models/worldgen/worldgen_engine.dart` with the `WorldGenEngine` interface (`findStructures`, `findOres`)
    - Define `StructureQuery`/`OreQuery` mirroring today's `StructureSearchParams`/`OreSearchParams` plus a `MinecraftVersion version` field
    - Define the sealed `EngineResult<T>` hierarchy (`EngineOk`, `EngineUnavailable`, `EngineUnsupportedVersion`), plus `ResultMeta` (veinSize, structureVariant, biome) and `FallbackReason` enum with human-readable text
    - Keep the file pure Dart (no Flutter imports) so it runs inside the `compute` isolate
    - _Requirements: 1.1, 1.4_

  - [x]* 1.2 Write interface-conformance unit tests
    - Assert both engine types satisfy `WorldGenEngine`; assert `EngineResult` values are isolate-serializable primitives/enums/model objects
    - _Requirements: 1.1, 1.4_

  - [x] 1.3 Add MinecraftVersion and MinecraftEdition value types
    - Create `flutter_app/lib/models/worldgen/minecraft_version.dart` with `MinecraftVersion` (`id` e.g. "java-1.20") and reuse/extend the edition enum
    - Provide mapping from `MinecraftVersion` down to the legacy `VersionEra` for the Simulated path
    - _Requirements: 1.3, 4.1_

- [x] 2. SimulatedEngine adapter over existing finders
  - [x] 2.1 Implement SimulatedEngine
    - Create `flutter_app/lib/models/worldgen/simulated_engine.dart` delegating `findStructures`/`findOres` to `StructureFinder`/`OreFinder`
    - Map `MinecraftVersion` → `VersionEra` and always return `EngineOk` (supports any version)
    - _Requirements: 1.3_

  - [x]* 2.2 Write property test for faithful delegation
    - **Property 2: Simulated engine delegates faithfully**
    - **Validates: Requirements 1.3**
    - For random ore/structure queries, assert `SimulatedEngine` output equals the direct legacy `OreFinder`/`StructureFinder` call

- [x] 3. Version strategy abstraction and registry
  - [x] 3.1 Define VersionStrategy and supporting config types
    - Create `flutter_app/lib/models/worldgen/version_strategy.dart` with the `VersionStrategy` interface (`placementFor`, `strongholdRings`, `biomeParams`, `oreFeatureFor`, `rngParams`) and the config types (`StructurePlacement`, `StrongholdRingConfig`, `BiomeParams`, `OreFeature`, `RngParams`)
    - _Requirements: 4.2, 4.3_

  - [x] 3.2 Implement VersionStrategyRegistry
    - Create `flutter_app/lib/models/worldgen/version_strategy_registry.dart` mapping `(version, edition) → VersionStrategy`, answering `isSupported` and `isVerified` (verification driven by golden-fixture status)
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [x]* 3.3 Write property tests for strategy resolution and completeness
    - **Property 7: Version strategy resolution is complete for supported versions**
    - **Validates: Requirements 4.2, 4.3**
    - **Property 8: Unsupported versions report, not crash** (assert `EngineUnsupportedVersion` for unregistered versions)
    - **Validates: Requirements 4.4**

  - [x] 3.4 Expand VersionAvailability with an explicit version-list API
    - Extend `version_availability.dart` with a version-list API sourced from the registry while keeping existing era-based methods for the Simulated path and the retained gating test
    - _Requirements: 4.1, 13.7_

- [x] 4. Int64 web RNG (64-bit math foundation)
  - [x] 4.1 Implement JavaRandomInt64
    - Create `flutter_app/lib/models/worldgen/java_random_int64.dart` using `package:fixnum` `Int64` for all seed-mixing and RNG state arithmetic; mirror `nextInt/nextLong/nextFloat/nextDouble` from `java.util.Random`; convert only reduced results that fit in 2^53 to Dart `int`
    - Confirm `BedrockRandom` (MT19937) is web-safe as-is and reuse it for the web Bedrock path
    - _Requirements: 3.2, 3.5_

  - [x]* 4.2 Write RNG conformance property test on the web/JS target
    - **Property 4: Web RNG reproduces java.util.Random**
    - **Validates: Requirements 3.5, 13.5**
    - Compare the Int64 web RNG stream against a stored reference `java.util.Random` sequence for random 64-bit seeds; MUST run on the web/JS target (`flutter test --platform chrome`) in addition to the VM; assert no divergence above 2^53

- [x] 5. Accurate engine core and backend selection
  - [x] 5.1 Define the WorldGenBackend contract and BackendSelector
    - Create `flutter_app/lib/models/worldgen/worldgen_backend.dart` with the internal `WorldGenBackend` contract (`computeStructures`, `computeOres`, `computeBiome`) and a pure `selectBackend(Platform)` function (web → DartWebBackend, else → NativeFfiBackend) with injected platform detection
    - _Requirements: 2.1, 3.1_

  - [x] 5.2 Implement AccurateEngine
    - Create `flutter_app/lib/models/worldgen/accurate_engine.dart` owning a `BackendSelector` and the `VersionStrategyRegistry`; return `EngineUnsupportedVersion` when no strategy exists and `EngineUnavailable` when the backend cannot run
    - _Requirements: 1.4, 2.1, 3.1, 4.4_

  - [x]* 5.3 Write property test for backend selection
    - **Property 3: Backend selection matches platform**
    - **Validates: Requirements 2.1, 3.1**

- [x] 6. SearchRunner selection and degradation seam
  - [x] 6.1 Implement EngineSelector
    - Add a pure `selectEngine(EngineSelectionContext)` to the search layer: Estimate → Simulated; Accurate → Simulated when unverified or web-cannot-run, otherwise Accurate
    - _Requirements: 1.5_

  - [x] 6.2 Wire degradation and SearchMeta into SearchRunner
    - Route ore/structure searches exclusively through `WorldGenEngine`, preserving the existing `compute()` isolate offloading; branch on `EngineOk`/`EngineUnavailable`/`EngineUnsupportedVersion`; on any fallback run Simulated and attach a non-null, non-empty `SearchMeta.fallbackReason`
    - Define `SearchMeta { mode, version, verified, fallbackReason? }`
    - _Requirements: 1.2, 1.5, 1.6, 5.1, 5.2, 5.3, 5.4, 11.3_

  - [x]* 6.3 Write property tests for selection and degradation
    - **Property 1: Engine selection is total and singular**
    - **Validates: Requirements 1.5**
    - **Property 9: Accurate requests that cannot run degrade to Estimate**
    - **Validates: Requirements 5.1, 5.2, 5.3, 11.3**
    - **Property 10: Every fallback carries its reason**
    - **Validates: Requirements 5.4**

  - [x]* 6.4 Write runner-seam unit test
    - Inject a spy engine; assert the runner dispatches through `WorldGenEngine` only and still offloads via `compute`
    - _Requirements: 1.2, 1.6_

- [x] 7. Native build pipeline and FFI backend
  - [x] 7.1 Vendor Cubiomes and add the C shim
    - Add Cubiomes C sources under `flutter_app/native/cubiomes/` and a thin shim `mc_finder_ffi.c` exposing a flat API (`mcf_find_structures`, `mcf_find_ores`, `mcf_get_biome`) returning plain structs/arrays
    - _Requirements: 2.2, 2.3_

  - [x] 7.2 Add per-platform CMake build wiring
    - Add `CMakeLists.txt` compiling shim + Cubiomes; wire Android (Gradle `externalNativeBuild` → `.so` per ABI), iOS/macOS (CocoaPods/Xcode phase → `.a`/`.framework`), Windows/Linux (CMake → `.dll`/`.so`)
    - _Requirements: 2.4_

  - [x] 7.3 Generate FFI bindings with ffigen
    - Add `package:ffigen` config for the shim header and generate the Dart bindings
    - _Requirements: 2.1_

  - [x] 7.4 Implement NativeFfiBackend with load-failure handling
    - Create `flutter_app/lib/models/worldgen/native_ffi_backend.dart` resolving the library via `DynamicLibrary.open`/`process`, marshalling queries into C structs, returning exact chunk/block coordinates (structures) and exact block coordinates (ores)
    - Wrap lookup; convert any `ArgumentError`/missing-symbol/open failure to `EngineUnavailable(FallbackReason.ffiLoadFailure)`; guard web builds so no `dart:ffi` dependency enters the web bundle (conditional import)
    - _Requirements: 2.1, 2.2, 2.3, 2.5_

  - [x]* 7.5 Write FFI load-failure unit test
    - Inject a loader that throws; assert `EngineUnavailable(ffiLoadFailure)` and that the runner falls back
    - _Requirements: 2.5_

  - [x]* 7.6 Add CI native-build smoke-load job
    - Add a GitHub Actions job (alongside `flutter-ci.yml`) per platform that compiles Cubiomes + shim and smoke-loads the library to confirm symbols resolve
    - _Requirements: 2.4_

- [x] 8. Golden-seed fixtures scaffolding
  - [x] 8.1 Create the fixture layout and loader
    - Create `test/fixtures/worldgen/<edition>-<version>/` JSON structure pairing a seed with authoritative structure positions, biome samples, and ore placements; add a loader and a parameterized suite that auto-discovers every directory
    - _Requirements: 13.1, 13.6, 10.3_

  - [x]* 8.2 Write property test for fixture-set existence
    - **Property 19: Supported versions always have a golden fixture set**
    - **Validates: Requirements 10.3, 13.1**

- [x] 9. Checkpoint - foundation complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 10. Spike: prove Int64 web RNG + one village on both backends (Java 1.20)
  - [x] 10.1 Add the Java 1.20 village golden fixture and minimal strategy
    - Add a Java 1.20 fixture directory with a known seed and its authoritative village position; register a minimal Java 1.20 `VersionStrategy` sufficient for village placement
    - _Requirements: 6.1, 6.2_

  - [x] 10.2 Prove the village position on both backends
    - Compute the village for the known Java 1.20 seed through `NativeFfiBackend` and `DartWebBackend`; both must match the fixture (exit criterion: both green)
    - _Requirements: 6.1, 6.2, 6.3_

  - [x]* 10.3 Write the spike golden test (native + web)
    - Assert the Java 1.20 village position matches the fixture on both the native and web backends — at least one green golden structure test on each path
    - _Requirements: 6.3_

- [x] 11. M1: Java structures 1.18–1.20
  - [x] 11.1 Implement region-grid structure placement (web backend)
    - Implement region spacing/separation + per-type salt placement in `DartWebBackend` using `JavaRandomInt64` and the `VersionStrategy` placement tables for Java 1.18/1.19/1.20
    - _Requirements: 7.1, 10.1, 10.2, 11.1_

  - [x] 11.2 Implement stronghold ring placement
    - Implement stronghold ring count/radii/spread using `strongholdRings` for Java 1.18–1.20
    - _Requirements: 7.2_

  - [x] 11.3 Implement buried treasure placement
    - Implement per-chunk buried-treasure presence/position for Java 1.18–1.20
    - _Requirements: 7.3_

  - [x] 11.4 Add Java 1.18/1.19/1.20 strategies and structure fixtures
    - Register full `VersionStrategy` entries for Java 1.18/1.19/1.20 and add golden structure fixtures (region-grid, stronghold, buried treasure)
    - _Requirements: 7.4, 13.1, 13.2_

  - [x]* 11.5 Write property test for region-grid positions
    - **Property 11: Region-grid structure positions are exact (Java 1.18–1.20)**
    - **Validates: Requirements 7.1, 10.1, 10.2, 11.1**

  - [x]* 11.6 Write property test for stronghold rings
    - **Property 12: Stronghold ring positions are exact (Java 1.18–1.20)**
    - **Validates: Requirements 7.2**

  - [x]* 11.7 Write property test for buried treasure
    - **Property 13: Buried treasure positions are exact (Java 1.18–1.20)**
    - **Validates: Requirements 7.3**

  - [x]* 11.8 Write cross-path parity property test for structures
    - **Property 5: Web and native accurate paths agree on structures**
    - **Validates: Requirements 3.3**
    - Where native is unavailable in CI, compare the web backend against the shared golden fixture

- [x] 12. Checkpoint - M1 structures verified
  - Ensure all tests pass, ask the user if questions arise.

- [x] 13. M2: Java biomes 1.18–1.20 (multi-noise climate)
  - [x] 13.1 Implement multi-noise climate biome computation
    - Implement multi-noise climate sampling in the backends using `biomeParams` for Java 1.18/1.19/1.20
    - _Requirements: 8.1_

  - [x] 13.2 Wire biome gating into structure emission
    - Emit a biome-gated structure candidate iff the computed biome at its position is in the structure's allowed biome set
    - _Requirements: 8.2_

  - [x] 13.3 Add biome golden fixtures for Java 1.18–1.20
    - Add biome sample fixtures to the Java 1.18/1.19/1.20 directories
    - _Requirements: 8.3, 13.3_

  - [x]* 13.4 Write property test for computed biomes
    - **Property 14: Computed biomes match the reference (Java 1.18–1.20)**
    - **Validates: Requirements 8.1**

  - [x]* 13.5 Write property test for biome gating
    - **Property 15: Biome gating uses the computed biome**
    - **Validates: Requirements 8.2**

- [x] 14. M3: Java ores 1.18–1.20 (feature loops + vein metadata)
  - [x] 14.1 Implement real per-chunk count × tries ore feature loops
    - Implement ore feature placement using the real `count × tries` loops, Y range, and vein size from `oreFeatureFor` for Java 1.18/1.19/1.20, returning exact block coordinates
    - _Requirements: 9.1_

  - [x] 14.2 Attach vein-size metadata to emitted veins
    - Populate `ResultMeta.veinSize` (present and ≥ 1) for every emitted vein
    - _Requirements: 9.3_

  - [x] 14.3 Add ore golden fixtures for Java 1.18–1.20
    - Add ore placement fixtures to the Java 1.18/1.19/1.20 directories
    - _Requirements: 9.2, 13.4_

  - [x]* 14.4 Write property test for ore feature placement
    - **Property 16: Ore feature placement matches the real loops (Java 1.18–1.20)**
    - **Validates: Requirements 9.1**

  - [x]* 14.5 Write property test for vein-size metadata
    - **Property 17: Every accurate vein reports its size**
    - **Validates: Requirements 9.3**

  - [x]* 14.6 Write cross-path parity property test for ores
    - **Property 6: Web and native accurate paths agree on ores**
    - **Validates: Requirements 3.4**
    - Where native is unavailable in CI, compare the web backend against the shared golden fixture

- [x] 15. Checkpoint - Java track (M1–M3) complete and verified
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 16. M6: UX for version selection and accurate results
  - [ ] 16.1 Add the version picker from the registry list
    - Add a version picker populated from the `VersionAvailability` version list
    - _Requirements: 12.1_

  - [ ] 16.2 Add the Accurate/Estimate mode toggle
    - Add a mode toggle wired to the search request mode
    - _Requirements: 12.2_

  - [ ] 16.3 Render accurate result cards and fallback notice
    - Read `SearchMeta`: omit the fabricated probability % in Accurate mode; show real metadata (vein size, structure variant) where available; render the Estimate-mode notice stating the reason when `fallbackReason` is set; omit the estimate disclaimer only for Verified_Version Accurate results
    - _Requirements: 12.3, 12.4, 12.5, 5.4_

  - [ ]* 16.4 Write property test for disclaimer/probability visibility
    - **Property 20: Disclaimer visibility follows mode and verification**
    - **Validates: Requirements 12.3, 12.5**

  - [ ]* 16.5 Write UI widget tests
    - Version picker populated from the registry list; mode toggle present and functional; accurate cards render real metadata
    - _Requirements: 12.1, 12.2, 12.4_

- [ ] 17. Checkpoint - required deliverable (foundation + spike + M1–M3 + UX) complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ]* 18. M4: version expansion (1.16/1.17, then 1.21+)
  - [ ]* 18.1 Add Java 1.16/1.17 strategies, fixtures, and results
    - Register `VersionStrategy` entries for Java 1.16 and 1.17 (research placement tables/salts/RNG params) and add their golden fixture sets; return exact structure, biome, and ore results
    - _Requirements: 10.1, 10.3_

  - [ ]* 18.2 Add Java 1.21+ strategies, fixtures, and results
    - Register `VersionStrategy` entries for Java 1.21 and later (research) with golden fixture sets; return exact structure, biome, and ore results
    - _Requirements: 10.2, 10.3_

- [ ]* 19. M5: Bedrock track (MT19937)
  - [ ]* 19.1 Add Bedrock VersionStrategy and MT19937 seed handling
    - Register a Bedrock `VersionStrategy` (research), compute results using Bedrock seed handling and the existing MT19937 `BedrockRandom`
    - _Requirements: 11.1_

  - [ ]* 19.2 Add Bedrock golden fixtures and verify placement
    - Add Bedrock fixture sets; assert returned positions match
    - _Requirements: 11.2, 10.3_

  - [ ]* 19.3 Write property test for Bedrock MT19937 placement
    - **Property 18: Bedrock uses MT19937 and matches the reference**
    - **Validates: Requirements 11.1**

- [ ] 20. Retain existing characterization tests
  - [ ] 20.1 Verify search_version_gating_test.dart still passes unchanged
    - Confirm `test/models/search_version_gating_test.dart` is retained unchanged and passes against the Simulated engine (determinism, version gating, edition divergence)
    - _Requirements: 13.7_

## Notes

- Tasks marked with `*` are optional. Optional sub-tasks here are either tests (unit/property/integration) or the research-heavy later milestones (M4 version expansion, M5 Bedrock). The required set — foundation (tasks 1–8), spike (10), and M1/M2/M3 Java (11, 13, 14) plus core UX (16) and retained tests (20) — forms a coherent first deliverable.
- Each task references specific requirements for traceability; test tasks reference the exact correctness property they validate.
- Checkpoints (9, 12, 15, 17) ensure incremental validation at milestone boundaries.
- RNG conformance (Property 4) and cross-path parity (Properties 5, 6) are the backbone of keeping the native and web paths in lock-step; conformance MUST run on the web/JS target.
- Golden fixtures grow per Supported_Version; the parameterized suite auto-discovers new directories so CI runs new + existing fixtures together.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.3"] },
    { "id": 1, "tasks": ["1.2", "2.1", "3.1", "4.1", "8.1"] },
    { "id": 2, "tasks": ["2.2", "3.2", "4.2", "5.1", "7.1", "8.2"] },
    { "id": 3, "tasks": ["3.3", "3.4", "5.2", "7.2", "7.3"] },
    { "id": 4, "tasks": ["5.3", "6.1", "7.4", "7.5", "7.6"] },
    { "id": 5, "tasks": ["6.2", "10.1"] },
    { "id": 6, "tasks": ["6.3", "6.4", "10.2"] },
    { "id": 7, "tasks": ["10.3", "11.1", "11.2", "11.3"] },
    { "id": 8, "tasks": ["11.4"] },
    { "id": 9, "tasks": ["11.5", "11.6", "11.7", "11.8", "13.1"] },
    { "id": 10, "tasks": ["13.2", "13.3", "14.1"] },
    { "id": 11, "tasks": ["13.4", "13.5", "14.2", "14.3"] },
    { "id": 12, "tasks": ["14.4", "14.5", "14.6", "16.1", "16.2"] },
    { "id": 13, "tasks": ["16.3", "18.1", "18.2", "19.1"] },
    { "id": 14, "tasks": ["16.4", "16.5", "19.2", "20.1"] },
    { "id": 15, "tasks": ["19.3"] }
  ]
}
```
