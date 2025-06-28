enum OreType { diamond, gold }

class OreLocation {
  final int x;
  final int y;
  final int z;
  final int chunkX;
  final int chunkZ;
  final double probability;
  final OreType oreType;
  final String? biome;

  OreLocation({
    required this.x,
    required this.y,
    required this.z,
    required this.chunkX,
    required this.chunkZ,
    required this.probability,
    required this.oreType,
    this.biome,
  });

  factory OreLocation.fromJson(Map<String, dynamic> json) {
    return OreLocation(
      x: json['x'] as int,
      y: json['y'] as int,
      z: json['z'] as int,
      chunkX: json['chunkX'] as int,
      chunkZ: json['chunkZ'] as int,
      probability: (json['probability'] as num).toDouble(),
      oreType: json['oreType'] == 'diamond' ? OreType.diamond : OreType.gold,
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
      'oreType': oreType == OreType.diamond ? 'diamond' : 'gold',
      'biome': biome,
    };
  }

  @override
  String toString() {
    return 'OreLocation(x: $x, y: $y, z: $z, probability: ${(probability * 100).toStringAsFixed(1)}%)';
  }
}