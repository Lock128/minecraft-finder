/*
 * cubiomes_core.c
 *
 * Minimal, self-contained subset of Cubiomes. See cubiomes_core.h.
 */
#include "cubiomes_core.h"

void cb_set_seed(CbRandom *r, int64_t seed) {
    r->state = ((uint64_t)seed ^ CB_LCG_MULTIPLIER) & CB_LCG_MASK;
}

int32_t cb_next(CbRandom *r, int bits) {
    r->state = (r->state * CB_LCG_MULTIPLIER + CB_LCG_ADDEND) & CB_LCG_MASK;
    /* Arithmetic right shift of a signed 48-bit value, as java.util.Random. */
    return (int32_t)((int64_t)r->state >> (48 - bits));
}

int32_t cb_next_int(CbRandom *r, int32_t bound) {
    if (bound <= 0) {
        return 0;
    }
    /* Power-of-two fast path (java.util.Random). */
    if ((bound & -bound) == bound) {
        return (int32_t)(((int64_t)bound * (int64_t)cb_next(r, 31)) >> 31);
    }
    int32_t bits, val;
    do {
        bits = cb_next(r, 31);
        val = bits % bound;
    } while (bits - val + (bound - 1) < 0);
    return val;
}

int64_t cb_next_long(CbRandom *r) {
    int32_t hi = cb_next(r, 32);
    int32_t lo = cb_next(r, 32);
    return ((int64_t)hi << 32) + (int64_t)lo;
}

int cb_region_structure_chunk(
    int64_t world_seed,
    int32_t region_x,
    int32_t region_z,
    int32_t spacing,
    int32_t separation,
    int32_t salt,
    int32_t *out_chunk_x,
    int32_t *out_chunk_z) {
    if (spacing <= 0) {
        spacing = 1;
    }
    if (separation < 0) {
        separation = 0;
    }
    if (separation >= spacing) {
        separation = spacing - 1;
    }

    /*
     * Region-seed mixing matching the Minecraft structure placement RNG:
     *   seed = worldSeed + regionX*341873128712 + regionZ*132897987541 + salt
     * then a java.util.Random seeded with that produces two bounded offsets.
     */
    int64_t region_seed = world_seed
        + (int64_t)region_x * 341873128712LL
        + (int64_t)region_z * 132897987541LL
        + (int64_t)salt;

    CbRandom r;
    cb_set_seed(&r, region_seed);

    int32_t range = spacing - separation;
    int32_t offset_x = cb_next_int(&r, range);
    int32_t offset_z = cb_next_int(&r, range);

    *out_chunk_x = region_x * spacing + offset_x;
    *out_chunk_z = region_z * spacing + offset_z;
    return 1;
}

int32_t cb_biome_at(int64_t world_seed, int32_t block_x, int32_t block_z) {
    /*
     * Placeholder deterministic biome sampler. The full Cubiomes multi-noise
     * generator plugs in here; until then this yields a stable id so the shim
     * and bindings exercise the full call path.
     */
    int64_t mixed = world_seed
        ^ ((int64_t)block_x * 3129871LL)
        ^ ((int64_t)block_z * 116129781LL);
    CbRandom r;
    cb_set_seed(&r, mixed);
    /* 64 vanilla biome ids is a safe upper bound for the reduced core. */
    return cb_next_int(&r, 64);
}

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
    int max_out) {
    if (out == 0 || max_out <= 0) {
        return 0;
    }
    if (count_per_chunk < 0) {
        count_per_chunk = 0;
    }
    if (tries < 0) {
        tries = 0;
    }
    int32_t y_span = max_y - min_y;
    if (y_span < 0) {
        y_span = 0;
    }
    int32_t vein_span = max_vein - min_vein;
    if (vein_span < 0) {
        vein_span = 0;
    }

    /* Decoration seed mixing (population-seed style). */
    int64_t pop_seed = world_seed
        + (int64_t)chunk_x * 16LL
        + (int64_t)chunk_z * 16LL
        + decoration_salt;
    CbRandom r;
    cb_set_seed(&r, pop_seed);

    int written = 0;
    for (int32_t c = 0; c < count_per_chunk && written < max_out; c++) {
        for (int32_t t = 0; t < tries && written < max_out; t++) {
            int32_t local_x = cb_next_int(&r, 16);
            int32_t local_z = cb_next_int(&r, 16);
            int32_t y = min_y + (y_span > 0 ? cb_next_int(&r, y_span + 1) : 0);
            int32_t vein =
                min_vein + (vein_span > 0 ? cb_next_int(&r, vein_span + 1) : 0);
            out[written].x = chunk_x * 16 + local_x;
            out[written].y = y;
            out[written].z = chunk_z * 16 + local_z;
            out[written].vein_size = vein < 1 ? 1 : vein;
            written++;
        }
    }
    return written;
}
