# Design Document

## Overview

This design introduces a **seed-accurate world generation engine** behind the existing `SearchRunner` boundary in the Flutter app. Today, `ore_finder.dart` and `structure_finder.dart` produce a statistical *estimate* (noise scoring + fabricated probability %). This feature keeps that simulation as a fast "Estimate" mode and adds an "Accurate" mode that reproduces the real game's structure positions, biomes, and ore placements for a given **seed + version + edition**.

Accuracy is delivered through two code paths that must stay in lock-step:

- **Native FFI path** — a `dart:ffi` binding to compiled [Cubiomes](https://github.com/Cubitect/cubiomes) on iOS, Android, macOS, Windows, and Linux.
- **Pure-Dart web path** — a Dart reimplementation of the needed Cubiomes concepts that performs all 64-bit seed/RNG math with `Int64` from `package:fixnum`, avoiding the web 53-bit precision trap.

Both paths are validated against shared **golden-seed fixtures** per version, and the web path additionally runs RNG-conformance tests on the JS target. When Accurate mode cannot run — web limitation, unsupported/unverified version, or an FFI load failure — the `SearchRunner` auto-falls back to the Simulated engine and the UI surfaces a visible notice explaining why.

Delivery is staged: **Spike → M1 Java structures (1.18–1.20) → M2 Java biomes → M3 Java ores → M4 version expansion (1.16/1.17, 1.21+) → M5 Bedrock → M6 UX.**

### Design goals

- The search layer calls **one** engine interface; engines are interchangeable.
- The two accurate backends produce **identical** output for the same inputs, proven by fixtures and parity tests.
- Fallback is automatic, honest, and always explains itself.
- Version support is an explicit, extensible list — adding a version is adding a `VersionStrategy` and a fixture set.

### Non-goals (carried from the planning doc)

- Full block-by-block terrain/cave geometry, mob spawning, loot tables, lighting.
- Bedrock parity before the Java track lands (M5 is a distinct milestone).

## Architecture

### Component boundaries

```
UI (version picker, Accurate/Estimate toggle, result cards)
        │  mode, version, edition, platform, search params
        ▼
SearchRunner  ──────────────────────────────────────────────┐
  • EngineSelector: pick exactly one engine                  │  preserves existing
  • Degradation: fall back to Simulated + attach reason      │  compute() isolate
        │                                                    │  offloading
        ▼                                                    ▼
WorldGenEngine (interface)                        [ background isolate ]
  ├── SimulatedEngine ── wraps OreFinder / StructureFinder (today's code)
  └── AccurateEngine
          │  BackendSelector by platform
          ├── NativeFfiBackend ── dart:ffi ──▶ libcubiomes (per-platform .so/.dylib/.dll/.a)
          └── DartWebBackend  ── pure Dart ──▶ Int64 RNG + ported placement logic
                  │
                  ▼
          VersionStrategy (per version+edition: placement tables, salts, RNG params)
                  │
                  ▼
          RNG primitives: JavaRandom / BedrockRandom (MT19937) / Int64 web RNG
```

The new code lives in `flutter_app/lib/models/worldgen/`. The existing `SearchRunner`, `GameRandom`, `JavaRandom`, `BedrockRandom`, `ore_finder.dart`, and `structure_finder.dart` stay in place; `SimulatedEngine` is a thin adapter over the last two.

### Layering rules

- `WorldGenEngine` and its implementations stay **pure Dart** (no Flutter imports) so they run inside the `compute` isolate and are unit-testable in isolation, matching the existing `VersionAvailability` convention.
- Platform/FFI detection is injected, not read from global state, so selection is a testable pure function.
- The UI depends only on `SearchRunner` output (results + a small `SearchMeta`), never on which engine ran — except to read the fallback reason and verification flag for display.

## Components and Interfaces

### WorldGenEngine interface

A single interface the search layer calls (Req 1.1, 1.3, 1.4). Signatures mirror the existing finder parameters so `SimulatedEngine` is a direct delegate, but the version input is the new explicit `MinecraftVersion` rather than the coarse `VersionEra`.

```dart
/// Outcome wrapper: either results, or a signal that the engine could not run.
sealed class EngineResult<T> {}
class EngineOk<T> extends EngineResult<T> {
  EngineOk(this.results, {this.meta = const ResultMeta.empty()});
  final List<T> results;
  final ResultMeta meta; // vein size, structure variant, biome, etc.
}
class EngineUnavailable<T> extends EngineResult<T> {
  EngineUnavailable(this.reason); // FFI load failure, web limitation
  final FallbackReason reason;
}
class EngineUnsupportedVersion<T> extends EngineResult<T> {
  EngineUnsupportedVersion(this.version, this.edition);
  final MinecraftVersion version;
  final MinecraftEdition edition;
}

abstract interface class WorldGenEngine {
  Future<EngineResult<StructureLocation>> findStructures(StructureQuery q);
  Future<EngineResult<OreLocation>> findOres(OreQuery q);
}
```

`StructureQuery` / `OreQuery` carry the same fields as today's `StructureSearchParams` / `OreSearchParams` (seed, center, radius, types, maxResults, edition) plus a `MinecraftVersion version`. Returning a `sealed` `EngineResult` (rather than throwing) lets the `SearchRunner` branch on unavailable/unsupported without exception control flow and keeps the value isolate-serializable.

- **SimulatedEngine** delegates to `OreFinder`/`StructureFinder` and always returns `EngineOk` (it supports any version). It maps a `MinecraftVersion` down to the legacy `VersionEra` the finders already understand (Req 1.3).
- **AccurateEngine** owns a `BackendSelector` and a `VersionStrategyRegistry`. It returns `EngineUnsupportedVersion` when no strategy exists (Req 4.4) and `EngineUnavailable` when the backend cannot run (Req 2.5, 3.1 on unsupported web versions).

### SearchRunner: selection and degradation

`SearchRunner` keeps its current public shape and its `compute()` isolate offloading (Req 1.6). It gains two pure helpers.

**EngineSelector** — chooses exactly one engine from `(mode, version, edition, platform)` (Req 1.5):

```dart
enum SearchMode { accurate, estimate }

WorldGenEngine selectEngine(EngineSelectionContext ctx) {
  if (ctx.mode == SearchMode.estimate) return simulated;
  // Accurate requested:
  if (!registry.isVerified(ctx.version, ctx.edition)) return simulated; // 5.2
  if (ctx.platform == Platform.web &&
      !webPath.canRun(ctx.version, ctx.edition)) return simulated;        // 5.1
  return accurate;
}
```

**Degradation at dispatch** — even when `accurate` is selected, the accurate engine may return `EngineUnavailable`/`EngineUnsupportedVersion` at runtime (e.g. FFI load failure on a device that should support it). The runner retries once through `simulated` and tags the output (Req 5.3, 11.3):

```dart
Future<SearchOutput<StructureLocation>> findStructures(StructureQuery q, mode, platform) async {
  final engine = selectEngine(context(q, mode, platform));
  if (engine is AccurateEngine) {
    final r = await compute(_runAccurateStructures, _pack(q)); // isolate preserved
    switch (r) {
      case EngineOk ok: return SearchOutput(ok.results, meta: SearchMeta.accurate(q.version));
      case EngineUnavailable u:        return _fallback(q, reason: u.reason);
      case EngineUnsupportedVersion _: return _fallback(q, reason: FallbackReason.unsupportedVersion);
    }
  }
  return _fallback-or-estimate via compute(_runSimulatedStructures, ...);
}
```

`SearchMeta` carries `{ mode, version, verified, fallbackReason? }`. Whenever a fallback occurs, `fallbackReason` is non-null and non-empty (Req 5.4) so the UI can render the notice. All objects crossing the isolate boundary remain primitives/enums/model-objects, as the current `SearchRunner` doc requires.

### AccurateEngine backend selection

`BackendSelector` is a pure function of platform (Req 2.1, 3.1):

```dart
WorldGenBackend selectBackend(Platform p) =>
    p == Platform.web ? dartWebBackend : nativeFfiBackend;
```

Both backends implement the same internal `WorldGenBackend` contract (`computeStructures`, `computeOres`, `computeBiome`) and both consume the same `VersionStrategy`, so the only difference is *how* they execute the strategy — native C vs Int64 Dart.

### VersionStrategy abstraction

A `VersionStrategy` encapsulates everything version-specific so the engine core is version-agnostic (Req 4.2, 4.3). This replaces the two-value `VersionEra` with explicit versions and is the extension point for M4/M5.

```dart
class MinecraftVersion { final String id; /* e.g. "java-1.20", "bedrock-1.21" */ }

abstract interface class VersionStrategy {
  MinecraftVersion get version;
  MinecraftEdition get edition;

  // Structure placement: region spacing/separation + per-type salt.
  StructurePlacement placementFor(StructureType type);     // region grid, salt
  StrongholdRingConfig get strongholdRings;                 // ring count/radii/spread
  // Biome generation parameters (multi-noise climate for 1.18+).
  BiomeParams get biomeParams;
  // Ore feature loops: per-chunk count × tries, Y range, vein size.
  OreFeature oreFeatureFor(OreType ore);
  // RNG configuration: Java LCG vs Bedrock MT19937, decoration salts.
  RngParams get rngParams;
}
```

`VersionStrategyRegistry` maps `(version, edition) → VersionStrategy` and answers `isSupported` and `isVerified`. `isVerified` is driven by the CI golden-fixture status: a version is *Supported* when a strategy exists and *Verified* when its fixtures pass (Req 4.1–4.4, 10.1–10.3). The registry is also the single source of truth queried by `VersionAvailability` so the UI version picker (Req 12.1) and the content-gating logic stay consistent.

`VersionAvailability` is extended with a version-list API that enumerates registry versions explicitly (Req 4.1) while keeping its existing era-based methods for the Simulated path and `search_version_gating_test.dart` (Req 13.7).

### 64-bit math strategy for web (Dart_Web_Path)

Minecraft RNG relies on 64-bit two's-complement overflow: `java.util.Random` uses a 48-bit state with multiplier `0x5DEECE66D`. On native Dart `int` is 64-bit and wraps correctly (today's `JavaRandom` works on native). On **web**, Dart `int` is a JS `double` and loses precision above 2^53, so the existing `JavaRandom` silently diverges in the browser.

The web backend therefore uses an **`Int64`-backed RNG** (`package:fixnum`) for all seed-mixing and RNG state arithmetic (Req 3.2, 3.5):

```dart
class JavaRandomInt64 {
  Int64 _seed;
  static final Int64 _mult = Int64.parseHex('5DEECE66D');
  static final Int64 _mask = (Int64.ONE << 48) - Int64.ONE;
  JavaRandomInt64(Int64 seed) : _seed = (seed ^ _mult) & _mask;

  int _next(int bits) {
    _seed = (_seed * _mult + Int64(0xB)) & _mask;      // exact 48-bit wrap
    return (_seed >> (48 - bits)).toInt();             // top <=32 bits fit in 2^53
  }
  // nextInt/nextLong/nextFloat/nextDouble mirror java.util.Random exactly.
}
```

Key rules:

- All state mixing (world seed → region seed → chunk seed, salts, coordinate mixing like `x*341873128 + z*132897987`) happens in `Int64`. Only the *reduced* result (a value that provably fits in 2^53) is converted to a Dart `int`.
- The native path keeps using the C/Cubiomes RNG; the Int64 Dart RNG is the web-only mirror. The two are held in sync by the RNG-conformance tests (Req 3.5 / 13.5) and by the cross-path parity properties (Req 3.3, 3.4).
- `BedrockRandom` (MT19937) already masks every operation to 32 bits (`& 0xFFFFFFFF`), so it is web-safe as-is; the web Bedrock path reuses it. Only the Java LCG needs the `Int64` treatment.

### Fallback / notice flow

```
User picks Accurate + version V + edition E on platform P
        │
        ▼
selectEngine(mode=accurate, V, E, P)
   ├── not verified ─────────────┐
   ├── web & web can't run V ─────┤──▶ SimulatedEngine  (reason set up front)
   └── else ─▶ AccurateEngine     │
        │                         │
        ▼ (runtime)               │
   EngineOk ─────────────▶ show Accurate results (no probability %, real metadata)
   EngineUnavailable ────────────┤
   EngineUnsupportedVersion ─────┘──▶ SimulatedEngine, reason = runtime cause
        │
        ▼
   SearchMeta.fallbackReason != null  ──▶ UI renders Estimate-mode notice stating the reason
```

`FallbackReason` is an enum with human-readable text: `webUnsupported`, `unverifiedVersion`, `unsupportedVersion`, `ffiLoadFailure`, `bedrockNoStrategy`. The result card reads `SearchMeta` to decide whether to show the notice (Req 5.4), whether to omit the probability % (Accurate only, Req 12.3), whether to show the estimate disclaimer (hidden only for verified Accurate, Req 12.5), and which real metadata to render (Req 12.4).

### Native build / FFI integration

- **Vendoring**: Cubiomes C sources live under `flutter_app/native/cubiomes/` with a thin C shim (`mc_finder_ffi.c`) exposing a stable, flat API (`mcf_find_structures`, `mcf_find_ores`, `mcf_get_biome`) that returns plain structs/arrays easy to map with `dart:ffi` and `package:ffigen`.
- **Build pipeline** (Req 2.4): a `CMakeLists.txt` compiles the shim + Cubiomes into a shared/static library per platform, wired through Flutter's native build hooks:
  - Android: `android/` CMake via Gradle `externalNativeBuild` → `.so` per ABI.
  - iOS/macOS: CocoaPods/Xcode build phase → `.a`/`.framework`.
  - Windows/Linux: CMake → `.dll`/`.so`.
  CI (GitHub Actions, alongside the existing `flutter-ci.yml`) builds each platform artifact and runs a **smoke load** to confirm the symbol table resolves.
- **Loading & FFI** (Req 2.1–2.3): `NativeFfiBackend` resolves the library via `DynamicLibrary.open`/`DynamicLibrary.process`, looks up the shim functions, and marshals queries into the C structs. Results come back as exact chunk/block coordinates (structures, Req 2.2) and exact block coordinates (ores, Req 2.3).
- **Load failure** (Req 2.5): the lookup is wrapped; any `ArgumentError`/missing-symbol/`open` failure is caught and converted to `EngineUnavailable(FallbackReason.ffiLoadFailure)` rather than crashing the search. Web builds never reference the FFI code (conditional import / platform guard), so the web bundle has no `dart:ffi` dependency.

## Data Models

Existing `OreLocation` and `StructureLocation` are reused, with accurate-mode semantics layered on via `ResultMeta`/`SearchMeta` rather than new location classes:

- In Accurate mode the fabricated `probability` field is **not displayed** (Req 12.3); `ResultMeta` carries real values: `veinSize` (Req 9.3 — present and ≥ 1 for every emitted vein), `structureVariant`, and the computed `biome` (Req 8.2).
- `MinecraftVersion` (new) replaces `VersionEra` at the query boundary. `VersionEra` remains internally for the Simulated path and the retained gating test.
- **Golden fixtures**: JSON under `test/fixtures/worldgen/<edition>-<version>/` pairing a seed with authoritative structure positions, biome samples, and ore placements (sourced from Cubiomes output / Chunkbase). One directory per Supported_Version (Req 13.1, 10.3).

## Error Handling

- **FFI load failure** → caught in `NativeFfiBackend`, surfaced as `EngineUnavailable(ffiLoadFailure)`; runner falls back to Simulated with a notice (Req 2.5, 5.3).
- **Unsupported version** → `AccurateEngine` returns `EngineUnsupportedVersion`; runner falls back (Req 4.4, 5.3). Bedrock with no strategy is the same path with `bedrockNoStrategy` (Req 11.3).
- **Unverified version / web-can't-run** → decided *before* dispatch by `selectEngine`, so no accurate work is attempted (Req 5.1, 5.2).
- **Invalid RNG bounds** → existing `ArgumentError` behavior in `JavaRandom`/`BedrockRandom` is preserved and mirrored in `JavaRandomInt64`.
- Fallback never produces an empty/opaque result: the user always gets Estimate results plus a reason (Req 5.4).

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Engine selection is total and singular

*For any* combination of `(mode, version, edition, platform)`, `selectEngine` resolves to exactly one `WorldGenEngine` instance, and the choice obeys the routing table (Estimate → Simulated; Accurate → Simulated when unverified or web-cannot-run, otherwise Accurate).

**Validates: Requirements 1.5**

### Property 2: Simulated engine delegates faithfully

*For any* ore or structure query, `SimulatedEngine` returns results identical to the corresponding legacy `OreFinder`/`StructureFinder` call for the same inputs.

**Validates: Requirements 1.3**

### Property 3: Backend selection matches platform

*For any* platform, `AccurateEngine` selects the `NativeFfiBackend` on iOS/Android/macOS/Windows/Linux and the `DartWebBackend` on web.

**Validates: Requirements 2.1, 3.1**

### Property 4: Web RNG reproduces java.util.Random

*For any* 64-bit seed, the `Int64`-backed web RNG stream (nextInt/nextLong/nextFloat/nextDouble) equals the reference `java.util.Random` stream for at least the first N draws, with no divergence above 2^53, when executed on the web/JS target.

**Validates: Requirements 3.5, 13.5**

### Property 5: Web and native accurate paths agree on structures

*For any* seed, supported version, and edition, the structure positions returned by the `DartWebBackend` equal those returned by the `NativeFfiBackend` (or, where native is unavailable in CI, equal the shared golden fixture).

**Validates: Requirements 3.3**

### Property 6: Web and native accurate paths agree on ores

*For any* seed, supported version, and edition, the ore placements returned by the `DartWebBackend` equal those returned by the `NativeFfiBackend` (or the shared golden fixture).

**Validates: Requirements 3.4**

### Property 7: Version strategy resolution is complete for supported versions

*For any* supported `(version, edition)`, the `VersionStrategyRegistry` resolves a non-null `VersionStrategy` that exposes placement tables, salts, and RNG parameters, and the accurate computation uses that strategy.

**Validates: Requirements 4.2, 4.3**

### Property 8: Unsupported versions report, not crash

*For any* `(version, edition)` with no registered `VersionStrategy`, `AccurateEngine` returns `EngineUnsupportedVersion` rather than producing results or throwing.

**Validates: Requirements 4.4**

### Property 9: Accurate requests that cannot run degrade to Estimate

*For any* Accurate request where the version is unverified, the web path cannot run it, the engine reports unavailable, or a Bedrock version lacks a strategy, the `SearchRunner` returns `SimulatedEngine` results.

**Validates: Requirements 5.1, 5.2, 5.3, 11.3**

### Property 10: Every fallback carries its reason

*For any* Accurate request routed through the `SimulatedEngine`, the resulting `SearchMeta.fallbackReason` is non-null and non-empty and identifies the cause of the fallback.

**Validates: Requirements 5.4**

### Property 11: Region-grid structure positions are exact (Java 1.18–1.20)

*For any* seed on Java 1.18–1.20, the `AccurateEngine`'s region-grid structure positions match the reference placement for that seed and version.

**Validates: Requirements 7.1, 10.1, 10.2, 11.1**

### Property 12: Stronghold ring positions are exact (Java 1.18–1.20)

*For any* seed on Java 1.18–1.20, the `AccurateEngine`'s stronghold ring positions match the reference ring placement.

**Validates: Requirements 7.2**

### Property 13: Buried treasure positions are exact (Java 1.18–1.20)

*For any* seed and chunk on Java 1.18–1.20, the `AccurateEngine`'s buried-treasure presence and position match the reference per-chunk placement.

**Validates: Requirements 7.3**

### Property 14: Computed biomes match the reference (Java 1.18–1.20)

*For any* seed and sampled coordinate on Java 1.18–1.20, the multi-noise climate biome computed by the `AccurateEngine` equals the reference biome at that coordinate.

**Validates: Requirements 8.1**

### Property 15: Biome gating uses the computed biome

*For any* biome-gated structure candidate, the `AccurateEngine` emits it if and only if the biome it computed at that candidate position is in the structure's allowed biome set.

**Validates: Requirements 8.2**

### Property 16: Ore feature placement matches the real loops (Java 1.18–1.20)

*For any* seed and chunk on Java 1.18–1.20, the ore placements produced by the `AccurateEngine` match the reference output of the real per-chunk `count × tries` feature loop.

**Validates: Requirements 9.1**

### Property 17: Every accurate vein reports its size

*For any* vein emitted by the `AccurateEngine` for a Supported_Version, the result carries vein-size metadata that is present and at least 1.

**Validates: Requirements 9.3**

### Property 18: Bedrock uses MT19937 and matches the reference

*For any* Bedrock seed with a registered `VersionStrategy`, the `AccurateEngine` computes results using Bedrock seed handling and the MT19937 RNG, and those results match the Bedrock reference for that seed.

**Validates: Requirements 11.1**

### Property 19: Supported versions always have a golden fixture set

*For any* version in the `VersionStrategyRegistry`'s supported list, a non-empty golden-seed fixture set exists for it.

**Validates: Requirements 10.3, 13.1**

### Property 20: Disclaimer visibility follows mode and verification

*For any* `(version, mode)`, the estimate disclaimer is hidden if and only if the mode is Accurate and the version is a Verified_Version, and the fabricated probability percentage is omitted whenever the mode is Accurate.

**Validates: Requirements 12.3, 12.5**

## Testing Strategy

Accuracy is meaningless without golden tests against the real game, so the suite combines **property tests** (universal behavior, high iteration) with **example/golden tests** (concrete fixtures and UI), plus **integration/smoke** jobs for the native pipeline.

### Property-based tests

Each property test runs **≥ 100 iterations** with randomized inputs and is tagged `Feature: seed-accurate-worldgen, Property {n}: {text}`. High-value targets:

- **RNG conformance (Property 4)** — generate random 64-bit seeds, compare the Int64 web RNG stream to a stored reference `java.util.Random` sequence. **Must run on the web/JS target** (`flutter test --platform chrome` / `dart test -p chrome`) to catch the 2^53 trap, in addition to the VM.
- **Cross-path parity (Properties 5, 6)** — generate random seeds and compare web-backend vs native-backend output. In CI where the native lib is unavailable for a given job, compare the web backend against the shared golden fixture (the native path is itself asserted against the same fixture), transitively proving agreement.
- **Selection & degradation (Properties 1, 3, 8, 9, 10)** — generate random `(mode, version, edition, platform)` tuples against an injected registry/platform and assert the routing table, exactly-one selection, unsupported signaling, fallback, and reason presence. These are pure, in-memory, and cheap.
- **Placement correctness (Properties 11–16, 18)** — generate random seeds (and chunks/coordinates) per supported version and assert structure/biome/ore output matches the reference. Use mocks/golden references to keep iterations cheap where a live native call would be costly.
- **Metadata & strategy invariants (Properties 7, 17, 19)** — generate across the supported-version set and assert strategy completeness, vein-size presence, and fixture-set existence.
- **Disclaimer logic (Property 20)** — generate `(version, mode)` and assert disclaimer/probability visibility rules at the presentation-model level.

### Example, golden, and edge-case tests

- **Golden-seed fixtures (Req 13.2, 13.3, 13.4)** — one parameterized suite iterates every fixture under `test/fixtures/worldgen/**` and asserts the `AccurateEngine` returns the fixture's structure positions, biome values, and ore placements. Adding a version adds a directory; the suite picks it up automatically, so CI runs new + existing fixtures together (Req 13.6).
- **Spike goldens (Req 6.1, 6.2, 6.3)** — a known Java 1.20 seed's village position is asserted on both the native and web backends; the spike's exit criterion is both green.
- **FFI load failure (Req 2.5)** — inject a loader that throws; assert `EngineUnavailable(ffiLoadFailure)` and that the runner falls back.
- **Interface conformance (Req 1.1, 1.4)** — type/unit tests that both engines satisfy `WorldGenEngine`.
- **Runner seam (Req 1.2, 1.6)** — inject a spy engine; assert the runner dispatches through `WorldGenEngine` only and still offloads via `compute`.
- **UI widget tests (Req 12.1, 12.2, 12.4)** — version picker populated from the registry list, Accurate/Estimate toggle present and functional, accurate result cards render real metadata (vein size, variant).

### Integration and smoke

- **Native build smoke (Req 2.4)** — CI job per platform compiles Cubiomes + shim and smoke-loads the library, confirming symbols resolve.
- **Native golden (Req 2.2, 2.3)** — on platforms where the artifact is available in CI, run a small set of golden fixtures through the native backend directly.

### Retained characterization tests

`test/models/search_version_gating_test.dart` is kept unchanged and continues to run against the Simulated engine, locking determinism, version gating, and edition divergence for the Estimate path (Req 13.7).

### Testing balance

Property tests carry the broad input coverage (RNG, parity, placement, routing). Example/golden tests pin exact real-game coordinates and UI behavior. Unit tests cover error conditions (FFI failure, invalid bounds) and integration seams. Avoid over-unit-testing paths the property and golden suites already cover.
