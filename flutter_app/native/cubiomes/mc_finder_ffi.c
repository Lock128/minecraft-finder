/*
 * mc_finder_ffi.c
 *
 * Implementation of the flat FFI shim declared in mc_finder_ffi.h. Delegates
 * placement math to the vendored Cubiomes core (cubiomes_core.h).
 */
#include "mc_finder_ffi.h"
#include "cubiomes_core.h"

#define MCF_ABI_VERSION 1

MCF_EXPORT int32_t mcf_abi_version(void) {
    return MCF_ABI_VERSION;
}

MCF_EXPORT int mcf_find_structures(
    const McfStructureQuery *query, McfStructure *out, int max_out) {
    if (query == 0 || out == 0 || max_out <= 0) {
        return 0;
    }

    int32_t spacing = query->spacing > 0 ? query->spacing : 1;

    /* Region window covering the query radius (radius is in blocks). */
    int32_t region_blocks = spacing * 16;
    int32_t min_x = query->center_x - query->radius;
    int32_t max_x = query->center_x + query->radius;
    int32_t min_z = query->center_z - query->radius;
    int32_t max_z = query->center_z + query->radius;

    int32_t min_region_x = min_x / region_blocks - (min_x < 0 ? 1 : 0);
    int32_t max_region_x = max_x / region_blocks + (max_x > 0 ? 1 : 0);
    int32_t min_region_z = min_z / region_blocks - (min_z < 0 ? 1 : 0);
    int32_t max_region_z = max_z / region_blocks + (max_z > 0 ? 1 : 0);

    int written = 0;
    for (int32_t rz = min_region_z; rz <= max_region_z && written < max_out;
         rz++) {
        for (int32_t rx = min_region_x; rx <= max_region_x && written < max_out;
             rx++) {
            int32_t chunk_x = 0;
            int32_t chunk_z = 0;
            cb_region_structure_chunk(
                query->world_seed, rx, rz, spacing, query->separation,
                query->salt, &chunk_x, &chunk_z);

            int32_t block_x = chunk_x * 16 + 8;
            int32_t block_z = chunk_z * 16 + 8;

            int32_t dx = block_x - query->center_x;
            int32_t dz = block_z - query->center_z;
            if ((int64_t)dx * dx + (int64_t)dz * dz >
                (int64_t)query->radius * query->radius) {
                continue;
            }

            out[written].structure_type = query->structure_type;
            out[written].chunk_x = chunk_x;
            out[written].chunk_z = chunk_z;
            out[written].block_x = block_x;
            out[written].block_y = 0;
            out[written].block_z = block_z;
            out[written].biome =
                cb_biome_at(query->world_seed, block_x, block_z);
            written++;
        }
    }
    return written;
}

MCF_EXPORT int mcf_find_ores(
    const McfOreQuery *query, McfOre *out, int max_out) {
    if (query == 0 || out == 0 || max_out <= 0) {
        return 0;
    }

    int32_t min_x = query->center_x - query->radius;
    int32_t max_x = query->center_x + query->radius;
    int32_t min_z = query->center_z - query->radius;
    int32_t max_z = query->center_z + query->radius;

    int32_t min_chunk_x = (min_x >> 4);
    int32_t max_chunk_x = (max_x >> 4);
    int32_t min_chunk_z = (min_z >> 4);
    int32_t max_chunk_z = (max_z >> 4);

    /* Bounded scratch for per-chunk feature hits. */
    enum { MCF_CHUNK_SCRATCH = 256 };
    CbOreHit scratch[MCF_CHUNK_SCRATCH];

    int written = 0;
    for (int32_t cz = min_chunk_z; cz <= max_chunk_z && written < max_out;
         cz++) {
        for (int32_t cx = min_chunk_x; cx <= max_chunk_x && written < max_out;
             cx++) {
            int hits = cb_chunk_ores(
                query->world_seed, cx, cz, query->count_per_chunk,
                query->tries, query->min_y, query->max_y, query->min_vein,
                query->max_vein, query->decoration_salt, scratch,
                MCF_CHUNK_SCRATCH);
            for (int i = 0; i < hits && written < max_out; i++) {
                int32_t dx = scratch[i].x - query->center_x;
                int32_t dz = scratch[i].z - query->center_z;
                if ((int64_t)dx * dx + (int64_t)dz * dz >
                    (int64_t)query->radius * query->radius) {
                    continue;
                }
                out[written].ore_type = query->ore_type;
                out[written].block_x = scratch[i].x;
                out[written].block_y = scratch[i].y;
                out[written].block_z = scratch[i].z;
                out[written].vein_size = scratch[i].vein_size;
                written++;
            }
        }
    }
    return written;
}

MCF_EXPORT int32_t mcf_get_biome(
    int64_t world_seed, int32_t block_x, int32_t block_z) {
    return cb_biome_at(world_seed, block_x, block_z);
}
