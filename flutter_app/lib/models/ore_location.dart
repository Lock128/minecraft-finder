enum OreType { diamond, gold, netherite, redstone, iron, coal, lapis }

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
      oreType: _parseOreType(json['oreType'] as String),
      biome: json['biome'] as String?,
    );
  }

  static OreType _parseOreType(String oreTypeStr) {
    switch (oreTypeStr) {
      case 'diamond':
        return OreType.diamond;
      case 'gold':
        return OreType.gold;
      case 'netherite':
        return OreType.netherite;
      case 'redstone':
        return OreType.redstone;
      case 'iron':
        return OreType.iron;
      case 'coal':
        return OreType.coal;
      case 'lapis':
        return OreType.lapis;
      default:
        return OreType.diamond;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'chunkX': chunkX,
      'chunkZ': chunkZ,
      'probability': probability,
      'oreType': _oreTypeToString(oreType),
      'biome': biome,
    };
  }

  static String _oreTypeToString(OreType oreType) {
    switch (oreType) {
      case OreType.diamond:
        return 'diamond';
      case OreType.gold:
        return 'gold';
      case OreType.netherite:
        return 'netherite';
      case OreType.redstone:
        return 'redstone';
      case OreType.iron:
        return 'iron';
      case OreType.coal:
        return 'coal';
      case OreType.lapis:
        return 'lapis';
    }
  }

  @override
  String toString() {
    return 'OreLocation(x: $x, y: $y, z: $z, probability: ${(probability * 100).toStringAsFixed(1)}%)';
  }
}
