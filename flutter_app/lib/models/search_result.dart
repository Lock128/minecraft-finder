import 'ore_location.dart';
import 'structure_location.dart';

enum SearchResultType { ore, structure }

class SearchResult {
  final SearchResultType type;
  final double probability;
  final int x;
  final int y;
  final int z;
  final int chunkX;
  final int chunkZ;
  final String? biome;
  final OreLocation? oreLocation;
  final StructureLocation? structureLocation;

  SearchResult._({
    required this.type,
    required this.probability,
    required this.x,
    required this.y,
    required this.z,
    required this.chunkX,
    required this.chunkZ,
    this.biome,
    this.oreLocation,
    this.structureLocation,
  });

  factory SearchResult.fromOre(OreLocation ore) {
    return SearchResult._(
      type: SearchResultType.ore,
      probability: ore.probability,
      x: ore.x,
      y: ore.y,
      z: ore.z,
      chunkX: ore.chunkX,
      chunkZ: ore.chunkZ,
      biome: ore.biome,
      oreLocation: ore,
    );
  }

  factory SearchResult.fromStructure(StructureLocation structure) {
    return SearchResult._(
      type: SearchResultType.structure,
      probability: structure.probability,
      x: structure.x,
      y: structure.y,
      z: structure.z,
      chunkX: structure.chunkX,
      chunkZ: structure.chunkZ,
      biome: structure.biome,
      structureLocation: structure,
    );
  }
}
