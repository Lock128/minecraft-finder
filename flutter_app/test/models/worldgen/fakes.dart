// Shared test doubles for the worldgen engine suite.

import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/version_strategy.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_backend.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';

/// A minimal [VersionStrategy] exposing non-trivial config so resolution tests
/// can assert the placement tables, salts, biome, ore, and RNG params exist.
class FakeVersionStrategy implements VersionStrategy {
  FakeVersionStrategy(this.version);

  @override
  final MinecraftVersion version;

  @override
  MinecraftEdition get edition => version.edition;

  @override
  StructurePlacement placementFor(StructureType type) =>
      StructurePlacement(spacing: 34, separation: 8, salt: type.index);

  @override
  StrongholdRingConfig get strongholdRings =>
      const StrongholdRingConfig(count: 128, distance: 32, spread: 3);

  @override
  BiomeParams get biomeParams => const BiomeParams(hasMultiNoise: true);

  @override
  OreFeature oreFeatureFor(OreType ore) => OreFeature(
        countPerChunk: 7,
        tries: 4,
        minY: -64,
        maxY: 16,
        minVeinSize: 1,
        maxVeinSize: 10,
      );

  @override
  RngParams get rngParams =>
      RngParams(usesMt19937: edition == MinecraftEdition.bedrock);
}

/// A [WorldGenBackend] that can run and returns canned, non-empty output. Used
/// to prove the engine wiring reaches the backend and surfaces [EngineOk].
class RunnableFakeBackend implements WorldGenBackend {
  @override
  bool canRun(VersionStrategy strategy) => true;

  @override
  Future<List<StructureLocation>> computeStructures(
      StructureQuery query, VersionStrategy strategy) async {
    return [
      StructureLocation(
        x: query.centerX,
        y: 72,
        z: query.centerZ,
        chunkX: query.centerX >> 4,
        chunkZ: query.centerZ >> 4,
        probability: 1.0,
        structureType: query.structureTypes.first,
        biome: 'plains',
      ),
    ];
  }

  @override
  Future<List<OreLocation>> computeOres(
      OreQuery query, VersionStrategy strategy) async {
    return [
      OreLocation(
        x: query.centerX,
        y: query.centerY,
        z: query.centerZ,
        chunkX: query.centerX >> 4,
        chunkZ: query.centerZ >> 4,
        probability: 1.0,
        oreType: query.oreType,
      ),
    ];
  }

  @override
  Future<String> computeBiome(
          int seed, int x, int z, VersionStrategy strategy) async =>
      'plains';
}

/// A [WorldGenBackend] whose compute methods throw, to prove the engine
/// converts failures into [EngineUnavailable].
class ThrowingFakeBackend implements WorldGenBackend {
  @override
  bool canRun(VersionStrategy strategy) => true;

  @override
  Future<List<StructureLocation>> computeStructures(
          StructureQuery query, VersionStrategy strategy) async =>
      throw StateError('boom');

  @override
  Future<List<OreLocation>> computeOres(
          OreQuery query, VersionStrategy strategy) async =>
      throw StateError('boom');

  @override
  Future<String> computeBiome(
          int seed, int x, int z, VersionStrategy strategy) async =>
      throw StateError('boom');
}
