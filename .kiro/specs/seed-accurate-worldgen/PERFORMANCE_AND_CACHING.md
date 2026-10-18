# Seed-Accurate Worldgen — Performance & Backend Caching Design

Status: Draft / proposal (not yet implemented)
Branch reviewed: `feat/seed-accurate-worldgen` (PR #20)
Author: investigation + benchmarks captured 2026-10-17

This document captures (1) how the seed-accurate world-gen algorithm performs,
(2) how the UI currently handles long-running searches, and (3) a concrete
proposal for caching/precomputing results on a backend so we don't re-run the
same expensive computation repeatedly. It is intended as a reference we can
pick up and implement later.

---

## 1. What the algorithm computes

Given `(seed, version, edition, center, radius, targetType)` the engine is a
**pure, deterministic function** — no I/O, no wall clock, no global state. The
same inputs always produce byte-identical output, on both the web (JS) and
native targets. That determinism is enforced by the golden-fixture parity
tests and is the key property that makes caching safe.

Core pieces (all in `flutter_app/lib/models/worldgen/`):

- **`JavaRandomInt64`** — a bit-exact mirror of `java.util.Random` implemented
  in `Int64` (`package:fixnum`) so 64-bit overflow survives on web/JS, where a
  plain Dart `int` is a double and would diverge above 2^53.
- **Ores** (`JavaOre.veinsInRange`) — scans a **chunk grid** of
  `((2·radius)/16 + 1)²` chunks. Per chunk it derives a decoration seed +
  feature seed and runs `countPerChunk × tries` RNG draws to place veins. This
  is the dominant cost: **O(radius²)**.
- **Structures** — region-grid placement (villages, temples, outposts,
  monuments, mansions), concentric-ring strongholds, and a per-chunk
  probability scan for buried treasure. Each emitted candidate also triggers a
  biome computation for gating. Also O(radius²) but with a much larger constant
  divisor (regions are ~32 chunks apart), so far cheaper than ores.
- **Backends** — `DartWebBackend` (pure Dart, used on web and whose math is
  held in lock-step with native), `NativeFfiBackend` (vendored Cubiomes C via
  FFI, native only), `BedrockBackend` (MT19937).

> **Important current caveat:** in the default registry, **no version is marked
> "Verified"**, so in the shipping app every Accurate request deterministically
> degrades to the Simulated estimate path (Req 5.2). The accurate math is
> reachable and fully tested, but not live by default until fixtures are
> cross-checked against an authoritative source.

---

## 2. Benchmark results

Benchmark harness: `flutter_app/test/perf/worldgen_benchmark.dart`
Run with:

```
flutter test test/perf/worldgen_benchmark.dart -r expanded
```

It drives the real `DartWebBackend` for diamond ore and
village + buried-treasure structures, across a sweep of radii. Timings are the
**median of 5 runs after a warmup pass**.

### Measurement environment

- **Dart VM (JIT)** on the dev host (macOS). These are the *fast* numbers.
- The production **web build runs on JS/WASM with `Int64` software emulation**,
  which for this 64-bit-arithmetic-heavy workload is typically **~3–10× slower**.
  Treat the web experience as a multiple of the figures below.
- `maxResults` was set effectively unlimited to measure full-scan cost (the app
  caps display at 50 free / 500 Pro, but the *scan* still visits every chunk).

### Ore search — diamond, Java 1.20, seed=123456789

| radius | chunks  | median (ms) | results   | µs/chunk |
|-------:|--------:|------------:|----------:|---------:|
| 50     | 64      | 0.78        | 282       | 12.13    |
| 100    | 196     | 1.64        | 1,106     | 8.35     |
| 250    | 1,024   | 5.53        | 6,878     | 5.40     |
| 500    | 4,096   | 15.71       | 27,397    | 3.83     |
| 1,000  | 15,876  | 65.06       | 109,490   | 4.10     |
| 2,000  | 63,001  | 253.58      | 437,716   | 4.02     |
| 4,000  | 251,001 | 1,041.36    | 1,750,445 | 4.15     |

### Structure search — village + buried treasure, Java 1.20

| radius | chunks  | median (ms) | results |
|-------:|--------:|------------:|--------:|
| 50     | 64      | 0.02        | 0       |
| 100    | 196     | 0.09        | 3       |
| 250    | 1,024   | 0.36        | 13      |
| 500    | 4,096   | 1.07        | 39      |
| 1,000  | 15,876  | 2.28        | 172     |
| 2,000  | 63,001  | 8.75        | 702     |
| 4,000  | 251,001 | 33.07       | 2,674   |

### Raw per-chunk ore cost (diamond feature, isolated loop)

```
200,000 chunks in 372.49 ms  =>  ~1,862 ns/chunk (VM)
projected radius=1000  => 15,876 chunks  => ~29.6 ms  (single ore type)
projected radius=4000  => 251,001 chunks => ~467.5 ms (single ore type)
projected radius=10000 => 1,565,001 chunks => ~2,914.7 ms (single ore type)
```

### Interpretation

- Cost scales cleanly as **O(radius²)**, ~4 µs/chunk per ore type on the VM.
- **Free tier (radius 50) is effectively instant.** Pain only appears at large
  Pro radii.
- Cost is **per ore type** — the UI loops over each selected ore and awaits a
  separate isolate run. Selecting 9 ores at radius 4,000 ≈ **9 × ~1 s ≈ 9 s**
  on the VM, and materially more on web.
- Structure search is ~30× cheaper than ore search at the same radius.
- The whole-world netherite scan (`findAllNetherite`) is the other expensive
  case and is Pro-only / comprehensive.

**Bottom line:** the only searches worth caching/precomputing are large-radius
multi-ore Pro searches and the whole-world netherite scan. Everything at the
free-tier radius is already fast enough that caching would add complexity for
little gain.

---

## 3. How the UI currently handles long searches

Entry point: `providers/search_state.dart → performSearch`.

What works today:

- **Off the UI thread.** Every search runs on a background isolate via
  Flutter's `compute()` (`SearchRunner.findOres / findStructures /
  findAllNetherite`). The UI thread never blocks, so the app stays responsive
  and the spinner keeps animating even during a multi-second scan.
- **Loading state.** `_isLoading` drives an indeterminate
  `CircularProgressIndicator`:
  - Search button → disabled, label switches to "Searching…"
    (`widgets/search_buttons.dart`).
  - Results tab → full loading view with "Analyzing…" text; for the netherite
    whole-world scan it adds a "this may take a while" hint
    (`widgets/results_tab.dart → _buildLoadingView`).
- **Stale-result protection.** A `_searchGeneration` counter is incremented at
  the start of each search; an in-flight search checks it after every `await`
  and silently discards its results if a newer search (or disposal) happened.
  This prevents an old slow search from overwriting a newer one.
- **Tier limits as a soft performance guard.** Free users are capped at
  `freeRadiusCap = 50` and 1 structure type; display is capped at 50 results.
  Pro is uncapped on radius (500 result display cap, 300 for comprehensive
  netherite).

Current gaps (relevant to performance UX):

- ~~**Sequential ore searches.**~~ ✅ **DONE** (see §3.1) — ore searches and
  the structure search now dispatch concurrently via `Future.wait`.
- **No progress percentage.** The spinner is indeterminate. There is no
  "scanned X of Y chunks" or ETA, even for the long netherite scan.
- **No cancel button.** A user cannot abort a running search; they can only
  start a new one (which supersedes the old via the generation counter, but the
  old isolate keeps running to completion in the background).
- **No timeout.** A pathological large search just runs until done.
- **Everything is recomputed every time.** There is no result cache at all, so
  re-running the same seed/version/area (or nudging the radius) pays full cost
  again.

### Low-effort UI improvements (independent of the backend cache)

These are worth doing regardless of whether we build the backend.

#### 3.1 Parallelize ore + structure searches — ✅ DONE

Status: implemented in `providers/search_state.dart → performSearch`.

The per-ore `compute()` calls and the structure search are now dispatched up
front and awaited together with `Future.wait`, instead of a sequential
`await` loop. On a multi-core device this runs them concurrently, cutting a
multi-ore search toward the cost of the single slowest ore rather than the sum.

Behavior preserved:

- Results are gathered in a fixed order (netherite/ores in `_selectedOreTypes`
  order, then structures) regardless of which isolate finishes first, so the
  combined list and the chosen `SearchMeta` precedence are unchanged.
- The final probability sort is unchanged.
- The `_searchGeneration` stale-check still discards superseded searches.

Verified: `flutter analyze` clean; `search_state_test.dart`,
`search_runner_seam_test.dart`, and `search_version_gating_test.dart` pass.

#### Still open

These require moving the heavy scan off `compute()` onto a managed isolate with
a message channel, so they are larger than a one-line change:

2. **Add a cancel affordance** — track the current generation and let the user
   cancel; combine with isolate kill once we move off `compute()` to a managed
   isolate.
3. **Progress reporting** — have the managed isolate post progress messages
   ("scanned X/Y chunks") and show a determinate progress bar for the
   netherite / large-radius cases.
4. **Timeout + graceful message** — cap runaway searches and surface a "try a
   smaller radius" message.

---

## 4. Backend caching / precompute proposal

Because the algorithm is a deterministic pure function, results are trivially
cacheable. Two levels, from simplest to best:

### Option A — whole-query cache (simplest)

Cache key:

```
(algoVersion, seed, versionId, edition, targetType,
 centerX, centerZ, [centerY], radius, maxResults)
```

Value: the finished result list. First requester pays the compute cost;
everyone with the identical query gets a cache hit.

- ✅ Trivial to build.
- ❌ Overlapping / expanding searches miss entirely (bump radius 500→1000 and
  you recompute everything). Center-dependent, so low reuse.

### Option B — chunk/region tile cache (recommended)

Key insight: **placement is computed per chunk/region independently of the
search center.** The center only affects the final filter + distance sort. So
cache at tile granularity and assemble any query window from tiles.

- **Ore tile key:** `(algoVersion, seed, versionId, chunkX, chunkZ, featureIndex)`
  → list of veins `{x, y, z, size}` in that chunk.
- **Structure tile key:** `(algoVersion, seed, versionId, regionX, regionZ, structureType)`
  → candidate position (+ biome).

A query then:
1. Computes the set of chunk/region tiles overlapping `(center, radius)`.
2. Fetches cached tiles; computes only the missing ones (and writes them back).
3. Filters to the radius box and sorts by distance to center — cheap.

- ✅ Expanding a radius only computes the **new ring** of tiles.
- ✅ Popular seeds can be precomputed server-side and warm the cache.
- ✅ Naturally dedupes across users searching the same seed.
- ✅ Sidesteps the web `Int64` slowdown: compute tiles server-side with the
  fast **native Cubiomes** path, clients just read tiles.

### Suggested architecture

```
Client (Flutter)
  └─ SearchRunner  ──►  CacheClient
                          ├─ hit  ─► return tiles
                          └─ miss ─► POST /tiles  ─► Serverless fn
                                                       ├─ native Cubiomes compute
                                                       └─ write-through to KV store
```

- **Compute tier:** a serverless function (e.g. Lambda / Cloudflare Worker)
  running the **native** engine — far faster than the JS path and the natural
  place to backfill the cache.
- **Store:** a KV / document store (DynamoDB, Redis, Cloudflare KV) keyed as
  above. Tiles are tiny (a handful of `{x,y,z,size}` tuples), so storage and
  wire cost are negligible; JSON is fine, a packed binary is an easy later win.
- **Client wrapper:** a "fetch-or-compute" layer around `SearchRunner`. On a
  cache miss or when offline, fall back to the existing on-device compute so
  the app still works with no network.

### Cache invalidation

- Include **`algoVersion`** in every key and bump it whenever the placement
  math changes — a math fix must never serve stale tiles.
- Include **`versionId` + `edition`** (already in the key): different Minecraft
  versions have different placement tables/salts.
- Tiles for a given `(seed, version, algoVersion)` are immutable, so no TTL is
  strictly required; a TTL can still be used for store hygiene / cost control.

### What NOT to cache

- Free-tier (radius 50) searches — already instant; caching adds complexity for
  no user-visible benefit. If we cache, scope it to Pro large-radius and the
  whole-world netherite scan.

### Open questions / decisions to make before implementing

1. **Verification gate.** The cache only matters once Accurate is actually
   served (today everything degrades to Simulated). Do we cache Simulated
   results too, or wait until a version is marked Verified?
2. **Compute location.** Confirm we're comfortable running the native engine in
   a serverless/container tier and keeping Cubiomes vendored there.
3. **Privacy / cost.** Seeds + search areas would transit to the backend. Fine
   for a game tool, but worth an explicit note; also set a budget alarm on the
   compute/store tier.
4. **Offline-first.** Keep the on-device compute as the fallback so the app is
   never hard-dependent on the backend.

---

## 5. Artifacts produced by this investigation

- `flutter_app/test/perf/worldgen_benchmark.dart` — the benchmark harness used
  for Section 2. Not a pass/fail test; prints a table. Keep it for regression
  tracking of the algorithm's cost over time.
- `flutter_app/lib/providers/search_state.dart` — `performSearch` updated to
  dispatch ore + structure searches concurrently (see §3.1). ✅ implemented.
