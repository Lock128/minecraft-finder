enum StructureType {
  village,
  stronghold,
  endCity,
  netherFortress,
  bastionRemnant,
  ancientCity,
  oceanMonument,
  woodlandMansion,
  pillagerOutpost,
  ruinedPortal,
  shipwreck,
  buriedTreasure,
  desertTemple,
  jungleTemple,
  witchHut,
}

class StructureLocation {
  final int x;
  final int y;
  final int z;
  final int chunkX;
  final int chunkZ;
  final double probability;
  final StructureType structureType;
  final String? biome;

  StructureLocation({
    required this.x,
    required this.y,
    required this.z,
    required this.chunkX,
    required this.chunkZ,
    required this.probability,
    required this.structureType,
    this.biome,
  });

  factory StructureLocation.fromJson(Map<String, dynamic> json) {
    return StructureLocation(
      x: json['x'] as int,
      y: json['y'] as int,
      z: json['z'] as int,
      chunkX: json['chunkX'] as int,
      chunkZ: json['chunkZ'] as int,
      probability: (json['probability'] as num).toDouble(),
      structureType: StructureType.values.firstWhere(
        (e) => e.toString().split('.').last == json['structureType'],
        orElse: () => StructureType.village,
      ),
      biome: json['biome'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'chunkX': chunkX,
      'chunkZ': chunkZ,
      'probability': probability,
      'structureType': structureType.toString().split('.').last,
      'biome': biome,
    };
  }

  @override
  String toString() {
    return 'StructureLocation(x: $x, y: $y, z: $z, type: ${structureType.toString().split('.').last}, probability: ${(probability * 100).toStringAsFixed(1)}%)';
  }
}