/*
 * mc_finder_ffi.h
 *
 * Thin, flat C API over the vendored Cubiomes core, designed to be mapped by
 * `dart:ffi` / `package:ffigen`. Every function returns plain structs/arrays
 * (no callbacks, no opaque handles) so the generated Dart bindings stay simple.
 *
 * Exposed entry points:
 *   - mcf_find_structures
 *   - mcf_find_ores
 *   - mcf_get_biome
 */
#ifndef MC_FINDER_FFI_H
#define MC_FINDER_FFI_H

#include <stdint.h>

#if defined(_WIN32)
#  define MCF_EXPORT __declspec(dllexport)
#else
#  define MCF_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* A single structure placement result (exact chunk + block coordinates). */
typedef struct {
    int32_t structure_type; /* mirrors the Dart StructureType index */
    int32_t chunk_x;
    int32_t chunk_z;
    int32_t block_x;
    int32_t block_y;
    int32_t block_z;
    int32_t biome;
} McfStructure;

/* A single ore placement result (exact block coordinates + vein size). */
typedef struct {
    int32_t ore_type; /* mirrors the Dart OreType index */
    int32_t block_x;
    int32_t block_y;
    int32_t block_z;
    int32_t vein_size;
} McfOre;

/* Query parameters for a structure search over a region window. */
typedef struct {
    int64_t world_seed;
    int32_t structure_type;
    int32_t center_x;
    int32_t center_z;
    int32_t radius;
    int32_t spacing;
    int32_t separation;
    int32_t salt;
} McfStructureQuery;

/* Query parameters for an ore search over a region window. */
typedef struct {
    int64_t world_seed;
    int32_t ore_type;
    int32_t center_x;
    int32_t center_y;
    int32_t center_z;
    int32_t radius;
    int32_t count_per_chunk;
    int32_t tries;
    int32_t min_y;
    int32_t max_y;
    int32_t min_vein;
    int32_t max_vein;
    int64_t decoration_salt;
} McfOreQuery;

/*
 * Find structures of one type within the query radius. Writes up to `max_out`
 * results into `out` and returns the number written (never more than max_out).
 */
MCF_EXPORT int mcf_find_structures(
    const McfStructureQuery *query, McfStructure *out, int max_out);

/*
 * Find ore placements within the query radius. Writes up to `max_out` results
 * into `out` and returns the number written.
 */
MCF_EXPORT int mcf_find_ores(
    const McfOreQuery *query, McfOre *out, int max_out);

/* Return the biome id at a block coordinate for a seed. */
MCF_EXPORT int32_t mcf_get_biome(
    int64_t world_seed, int32_t block_x, int32_t block_z);

/* Returns a small positive ABI version so loaders can sanity-check the lib. */
MCF_EXPORT int32_t mcf_abi_version(void);

#ifdef __cplusplus
}
#endif

#endif /* MC_FINDER_FFI_H */
