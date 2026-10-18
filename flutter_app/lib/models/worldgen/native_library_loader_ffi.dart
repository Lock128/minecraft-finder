import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart' as pkg_ffi;

import 'mc_finder_bindings.dart';
import 'native_library_loader.dart';

/// Native [NativeLibraryLoader] backed by `dart:ffi`. This file is only
/// imported on non-web platforms via the conditional import in
/// `native_ffi_backend.dart`, so `dart:ffi`/`dart:io` never reach the web
/// bundle.
class PlatformNativeLibraryLoader implements NativeLibraryLoader {
  const PlatformNativeLibraryLoader();

  @override
  bool get isAvailable => true;

  @override
  NativeWorldGen load() {
    final lib = _open();
    final bindings = McFinderBindings(lib);
    // Touch a symbol so a missing-symbol lookup fails here (and is caught by
    // NativeFfiBackend) rather than on first real use.
    bindings.mcf_abi_version();
    return _FfiWorldGen(bindings);
  }

  ffi.DynamicLibrary _open() {
    // iOS/macOS link the shim into the app binary (CocoaPods), so resolve from
    // the running process. Other platforms ship a standalone shared library.
    if (Platform.isIOS || Platform.isMacOS) {
      return ffi.DynamicLibrary.process();
    }
    if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('mc_finder_ffi.dll');
    }
    // Android & Linux.
    return ffi.DynamicLibrary.open('libmc_finder_ffi.so');
  }
}

class _FfiWorldGen implements NativeWorldGen {
  _FfiWorldGen(this._bindings);

  final McFinderBindings _bindings;

  @override
  List<NativeStructureHit> findStructures({
    required int worldSeed,
    required int structureType,
    required int centerX,
    required int centerZ,
    required int radius,
    required int spacing,
    required int separation,
    required int salt,
    required int maxOut,
  }) {
    final queryPtr = pkg_ffi.calloc<McfStructureQuery>();
    final outPtr = pkg_ffi.calloc<McfStructure>(maxOut);
    try {
      final q = queryPtr.ref;
      q.world_seed = worldSeed;
      q.structure_type = structureType;
      q.center_x = centerX;
      q.center_z = centerZ;
      q.radius = radius;
      q.spacing = spacing;
      q.separation = separation;
      q.salt = salt;

      final n = _bindings.mcf_find_structures(queryPtr, outPtr, maxOut);
      final hits = <NativeStructureHit>[];
      for (var i = 0; i < n; i++) {
        final s = outPtr[i];
        hits.add(NativeStructureHit(
          chunkX: s.chunk_x,
          chunkZ: s.chunk_z,
          blockX: s.block_x,
          blockY: s.block_y,
          blockZ: s.block_z,
          biome: s.biome,
        ));
      }
      return hits;
    } finally {
      pkg_ffi.calloc.free(queryPtr);
      pkg_ffi.calloc.free(outPtr);
    }
  }

  @override
  List<NativeOreHit> findOres({
    required int worldSeed,
    required int oreType,
    required int centerX,
    required int centerY,
    required int centerZ,
    required int radius,
    required int countPerChunk,
    required int tries,
    required int minY,
    required int maxY,
    required int minVein,
    required int maxVein,
    required int decorationSalt,
    required int maxOut,
  }) {
    final queryPtr = pkg_ffi.calloc<McfOreQuery>();
    final outPtr = pkg_ffi.calloc<McfOre>(maxOut);
    try {
      final q = queryPtr.ref;
      q.world_seed = worldSeed;
      q.ore_type = oreType;
      q.center_x = centerX;
      q.center_y = centerY;
      q.center_z = centerZ;
      q.radius = radius;
      q.count_per_chunk = countPerChunk;
      q.tries = tries;
      q.min_y = minY;
      q.max_y = maxY;
      q.min_vein = minVein;
      q.max_vein = maxVein;
      q.decoration_salt = decorationSalt;

      final n = _bindings.mcf_find_ores(queryPtr, outPtr, maxOut);
      final hits = <NativeOreHit>[];
      for (var i = 0; i < n; i++) {
        final o = outPtr[i];
        hits.add(NativeOreHit(
          blockX: o.block_x,
          blockY: o.block_y,
          blockZ: o.block_z,
          veinSize: o.vein_size,
        ));
      }
      return hits;
    } finally {
      pkg_ffi.calloc.free(queryPtr);
      pkg_ffi.calloc.free(outPtr);
    }
  }

  @override
  int getBiome(int worldSeed, int blockX, int blockZ) =>
      _bindings.mcf_get_biome(worldSeed, blockX, blockZ);
}
