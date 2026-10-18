/*
 * cubiomes_core.h
 *
 * Minimal, self-contained subset of Cubiomes (https://github.com/Cubitect/cubiomes,
 * MIT licensed) sufficient for the flat FFI shim used by the seed-accurate
 * world-generation engine. This exposes the java.util.Random 48-bit LCG and the
 * region-grid structure placement used by Minecraft Java 1.18-1.20.
 *
 * When expanding coverage, the upstream full biome generator can be vendored in
 * alongside these files; the shim API (mc_finder_ffi.h) stays stable.
 */
#ifndef CUBIOMES_CORE_H
#define CUBIOMES_CORE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* java.util.Random LCG parameters. */
#define CB_LCG_MULTIPLIER 0x5DEECE66DULL
#define CB_LCG_ADDEND 0xBULL
#define CB_LCG_MASK ((1ULL << 48) - 1)

/* java.util.Random mirror. State is 48 bits. */
typedef struct {
    uint64_t state;
} CbRandom;

/* Seed a CbRandom exactly like `new java.util.Random(seed)`. */
void cb_set_seed(CbRandom *r, int64_t seed);

/* next(bits) from java.util.Random. */
int32_t cb_next(CbRandom *r, int bits);

/* nextInt(bound) from java.util.Random. */
int32_t cb_next_int(CbRandom *r, int32_t bound);

/* nextLong() from java.util.Random. */
int64_t cb_next_long(CbRandom *r);

/*
 * Region-grid structure placement (Minecraft Java 1.18-1.20 style).
 *
 * Divides the world into regions of `spacing` chunks. For each region a single
 * attempt is made at a chunk offset bounded by (spacing - separation), seeded
 * with the world seed, the region coordinates and the per-structure `salt`.
 *
 * Writes the chosen chunk coordinates into *out_chunk_x / *out_chunk_z and
 * returns 1 (every region produces a candidate chunk; biome gating is applied
 * by higher layers). The region containing (regionX, regionZ) is addressed
 * directly.
 */
int cb_region_structure_chunk(
    int64_t world_seed,
    int32_t region_x,
    int32_t region_z,
    int32_t spacing,
    int32_t separation,
    int32_t salt,
    int32_t *out_chunk_x,
    int32_t *out_chunk_z);

/*
 * Deterministic biome id at a block coordinate for a seed. This reduced core
 * returns a stable pseudo-biome id derived from the seed and coordinates; the
 * full Cubiomes biome generator plugs in here when vendored.
 */
int32_t cb_biome_at(int64_t world_seed, int32_t block_x, int32_t block_z);

/*
 * Ore feature placement for a single chunk. Runs the real per-chunk
 * count x tries loop structure used by Minecraft feature placement, seeded via
 * the decoration salt, and writes up to `max_out` block positions with their
 * vein sizes. Returns the number written.
 */
typedef struct {
    int32_t x;
    int32_t y;
    int32_t z;
    int32_t vein_size;
} CbOreHit;

int cb_chunk_ores(
    int64_t world_seed,
    int32_t chunk_x,
    int32_t chunk_z,
    int32_t count_per_chunk,
    int32_t tries,
    int32_t min_y,
    int32_t max_y,
    int32_t min_vein,
    int32_t max_vein,
    int64_t decoration_salt,
    CbOreHit *out,
    int max_out);

#ifdef __cplusplus
}
#endif

#endif /* CUBIOMES_CORE_H */
