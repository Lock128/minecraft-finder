# Seed-Accurate World Generation — Specification (Future Work)

> Status: **Planned / not started.** This document specifies the work required
> to turn the current *statistical simulation* into a *seed-accurate*
> reproduction of Minecraft world generation. It is intentionally scoped as its
> own project — it is a large undertaking and is independent of the UX and
> version-gating work already shipped.

## 1. Why this exists

### What the app does today
The current finder is an **approximation**. For a given seed it:
1. Converts the seed string with a Java-compatible `String.hashCode()`.
2. Builds a Java LCG (`JavaRandom`) or Bedrock MT19937 (`BedrockRandom`) RNG.
3. Samples a coarse 3D grid and scores each point with Perlin noise ×
   per-ore triangular/uniform Y-profiles × biome modifiers × a random factor ×
   a vein-noise factor.
4. Ranks the highest-scoring points and calls them "locations."

This produces **plausible-looking hot spots**, not the actual ore blocks or
structures that the real game would place. It cannot answer "is there a diamond
at (x, y, z) in seed S" correctly, and its "probability %" is a fabricated
score, not a real likelihood.

### What "seed-accurate" means
A seed-accurate implementation reproduces Minecraft's world generation closely
enough that, for a given **seed + version + edition**, it returns the **same
structure positions and the same ore/vein placements** the game itself would
generate (within the layers the game actually computes deterministically).

This is a well-understood but non-trivial problem. The reference
implementations are [Cubiomes](https://github.com/Cubitect/cubiomes) (C, biomes
+ structures) and the various decompiled-source projects. We would port or bind
to that body of knowledge rather than re-derive it.

## 2. Goals and non-goals

### Goals
- Accurate **structure positions** per seed/version/edition (region-grid seeds,
  salts, biome checks, ring placement for strongholds).
- Accurate **biome generation** per seed/version (multi-noise climate for 1.18+,
  layered biome generation for legacy).
- Accurate **ore / feature placement** per chunk using the real
  `count × tries` feature loops and placement RNG, for the versions we claim.
- A clearly versioned engine: a specific list of supported Minecraft versions,
  each verified against known seeds.

### Non-goals (at least initially)
- Full terrain height / block-by-block chunk generation (surface shaping, cave
  carving geometry). We only need what is required to locate ores and
  structures, not to render the world.
- Mob spawning, loot tables, light, redstone, etc.
- Bedrock parity on day one (see §6 — Bedrock is a separate RNG + algorithm
  track and should be a follow-up milestone).

## 3. Scope of accurate versions

Rather than two coarse eras (`legacy` / `modern`), the accurate engine targets
an explicit version list. Proposed first milestones, in priority order:

1. **Java 1.18 – 1.20** (multi-noise biomes, 1.18 ore overhaul). Highest user
   value and best-documented.
2. **Java 1.16 – 1.17** (Nether update, Caves & Cliffs part 1 ores).
3. **Java 1.21+** including the Third Drop content the app already references.
4. **Bedrock** equivalents (separate milestone, see §6).

Each supported version is a first-class entry with its own placement tables,
salts, and a golden-seed test fixture.

## 4. Technical approach

Two viable strategies; recommend evaluating both with a spike before committing.

### Option A — Port Cubiomes concepts to Dart (pure Dart)
- Reimplement the needed pieces of Cubiomes in Dart: biome noise, structure
  region seeding, placement checks.
- **Pros:** no native toolchain, runs everywhere Flutter runs (incl. web via
  the existing `compute` isolates), single language.
- **Cons:** large porting effort; must track Cubiomes updates by hand; Dart
  int is 64-bit on native but **web `int` is JS number (53-bit)** — the LCG and
  64-bit seed mixing must be done with explicit 64-bit emulation (e.g.
  `fixnum`'s `Int64`) or it will silently diverge on web. This is the single
  biggest correctness trap.

### Option B — FFI to Cubiomes (native) + fallback
- Compile Cubiomes and call it via `dart:ffi` on mobile/desktop.
- **Pros:** proven correctness, fast.
- **Cons:** no web support (FFI is unavailable on web); per-platform build
  pipeline (iOS/Android/macOS/Windows/Linux); the app currently ships web, so
  we'd need Option A as a web fallback anyway.

**Recommendation:** start with **Option A (pure Dart)** so one implementation
covers every platform including web, using `Int64` for all seed/RNG math.
Revisit FFI only if performance becomes a problem on large scans.

### Architecture fit
The current code already isolates the heavy work behind `SearchRunner`
(`compute`) and `GameRandom`. The accurate engine should slot in behind the
same `SearchRunner` boundary:
- Introduce a `WorldGenEngine` interface with `findStructures` / `findOres`.
- `SimulatedEngine` = today's code (kept as a fast "estimate" mode).
- `AccurateEngine` = the new seed-accurate implementation.
- A per-version strategy object selects placement tables and RNG salts.
- `VersionAvailability` (already added) expands from two eras to the explicit
  version list.

## 5. Correctness: 64-bit math on web

Non-negotiable for a pure-Dart port: Minecraft's RNG and seed mixing rely on
64-bit two's-complement overflow (`java.util.Random`: 48-bit state, multiplier
`0x5DEECE66D`). On native Dart `int` is 64-bit and wraps correctly; on **web**
`int` is a double and loses precision above 2^53.

Plan:
- Wrap all seed/RNG state in `Int64` (package:fixnum) or a small hand-rolled
  64-bit type, OR
- Gate the accurate engine to native and keep the simulated engine on web.

Decide this in the spike; it determines the whole implementation style.

## 6. Bedrock track (separate milestone)

Bedrock uses a different RNG (C++ `std::mt19937`), different seed handling, and
in places different structure/ore distributions. The current app already has a
`BedrockRandom` (MT19937), but accurate Bedrock worldgen is its own research
effort with less community tooling than Java. Treat it as a distinct milestone
after Java accuracy lands; do not block Java accuracy on it.

## 7. Testing strategy (the part that makes it real)

Accuracy is meaningless without golden tests against the actual game.

- **Golden seed fixtures:** for each supported version, capture a set of known
  seeds and the real coordinates of several structures (village, stronghold,
  ancient city, etc.) and a handful of ore veins, generated by the actual game
  or an authoritative tool (e.g. Chunkbase / Cubiomes output). Store as test
  fixtures.
- **Structure position tests:** assert the engine returns the exact chunk/block
  position for each fixture structure.
- **Biome tests:** assert biome at known coordinates matches.
- **RNG conformance tests:** assert `JavaRandom`/seed-mixing output matches
  known `java.util.Random` sequences, including on web (if targeted).
- **Cross-version regression:** each new supported version adds its own fixture
  set; CI runs all of them.
- Keep the existing determinism / version-gating characterization tests
  (`test/models/search_version_gating_test.dart`) — they remain valid for the
  simulated engine.

## 8. UX implications

- Replace the two-value era selector with a version picker (the version-aware
  `VersionAvailability` plumbing added in the UX pass makes this incremental).
- Offer a mode toggle: **Accurate** (slower, exact, only for supported
  versions) vs **Estimate** (today's fast simulation, any version).
- Drop the fabricated "probability %" in Accurate mode — a location either
  generates or it does not. Reuse the slot for real metadata (vein size,
  structure variant).
- Remove the remaining "estimates" disclaimers for versions where Accurate mode
  is verified.

## 9. Suggested milestones

1. **Spike (1–2 wk):** prove 64-bit RNG + one structure (village) position
   matches a golden seed on Java 1.20, on native **and** web. Decide Option A
   vs B and the 64-bit approach. Exit criterion: one green golden test.
2. **M1 — Java structures (1.18–1.20):** all region-grid structures + strongholds
   + buried treasure, golden-tested.
3. **M2 — Java biomes (1.18–1.20):** multi-noise climate, biome-gated structures
   use real biomes.
4. **M3 — Java ores (1.18–1.20):** real feature placement for the ore set.
5. **M4 — Version expansion:** 1.16/1.17, then 1.21+.
6. **M5 — Bedrock track.**
7. **M6 — UX:** Accurate/Estimate toggle, version picker, remove disclaimers.

## 10. References
- Cubiomes — biome/structure generation in C: https://github.com/Cubitect/cubiomes
- Minecraft Wiki — ore and structure generation pages (per-version placement
  tables, spacing/separation, salts).
- `java.util.Random` algorithm (LCG constants) — for RNG conformance.

---

### Appendix: current simulated engine (what we keep as "Estimate" mode)
Entry points: `lib/models/ore_finder.dart` (`findOres`, `findAllNetherite`),
`lib/models/structure_finder.dart` (`findStructures`), dispatched via
`lib/models/search_runner.dart`. Content availability per era/edition is
centralized in `lib/models/version_availability.dart`. The simulated engine is
honest about being an estimate (see the `algorithmVersion` label in
`getNetheriteStats`) and stays useful as the any-version fast path.
