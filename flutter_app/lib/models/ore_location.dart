enum OreType { diamond, gold, netherite, redstone, iron, coal, lapis, copper, emerald }

/// Vein size parameters per ore type: [minSize, maxSize, averageSize]
/// Values based on Minecraft Java Edition 1.18+ ore generation.
const Map<OreType, List<int>> oreVeinSizes = {
  OreType.diamond: [1, 10, 4],      // Small veins, avg ~4
  OreType.gold: [1, 9, 5],          // Medium veins
  OreType.netherite: [1, 3, 2],     // Very small (ancient debris)
  OreType.redstone: [1, 10, 6],     // Medium-large veins
  OreType.iron: [1, 13, 7],         // Large veins
  OreType.coal: [1, 17, 10],        // Largest veins
  OreType.lapis: [1, 7, 4],         // Small-medium veins
  OreType.copper: [1, 20, 10],      // Very large veins (1.17+)
  OreType.emerald: [1, 1, 1],       // Single blocks only
};

class OreLocation {
  final int x;
  final int y;
  final int z;
  final int chunkX;
  final int chunkZ;
  final double probability;
  final OreType oreType;
  final String? biome;
  
  /// Estimated number of ore blocks in the vein at this location.
  /// Calculated based on ore type vein sizes and local probability.
  final int estimatedVeinSize;
  
  /// Minimum possible vein size for this ore type.
  final int minVeinSize;
  
  /// Maximum possible vein size for this ore type.
  final int maxVeinSize;

  OreLocation({
    required this.x,
    required this.y,
    required this.z,
    required this.chunkX,
    required this.chunkZ,
    required this.probability,
    required this.oreType,
    this.biome,
    int? estimatedVeinSize,
    int? minVeinSize,
    int? maxVeinSize,
  }) : estimatedVeinSize = estimatedVeinSize ?? _calculateVeinSize(oreType, probability),
       minVeinSize = minVeinSize ?? (oreVeinSizes[oreType]?[0] ?? 1),
       maxVeinSize = maxVeinSize ?? (oreVeinSizes[oreType]?[1] ?? 10);

  /// Calculate estimated vein size based on ore type and probability.
  /// Higher probability locations tend to have larger veins.
  static int _calculateVeinSize(OreType oreType, double probability) {
    final veinParams = oreVeinSizes[oreType];
    if (veinParams == null) return 1;
    
    final int minSize = veinParams[0];
    final int maxSize = veinParams[1];
    final int avgSize = veinParams[2];
    
    // Scale vein size with probability:
    // - Low probability (0.0-0.3): closer to min size
    // - Medium probability (0.3-0.6): around average
    // - High probability (0.6-1.0): closer to max size
    double scaleFactor = probability.clamp(0.0, 1.0);
    
    // Use a weighted calculation that favors the average but shifts with probability
    double weightedSize = avgSize + (scaleFactor - 0.5) * (maxSize - minSize) * 0.6;
    
    return weightedSize.round().clamp(minSize, maxSize);
  }

  factory OreLocation.fromJson(Map<String, dynamic> json) {
    final oreType = _parseOreType(json['oreType'] as String);
    final probability = (json['probability'] as num).toDouble();
    return OreLocation(
      x: json['x'] as int,
      y: json['y'] as int,
      z: json['z'] as int,
      chunkX: json['chunkX'] as int,
      chunkZ: json['chunkZ'] as int,
      probability: probability,
      oreType: oreType,
      biome: json['biome'] as String?,
      estimatedVeinSize: json['estimatedVeinSize'] as int?,
      minVeinSize: json['minVeinSize'] as int?,
      maxVeinSize: json['maxVeinSize'] as int?,
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
      case 'copper':
        return OreType.copper;
      case 'emerald':
        return OreType.emerald;
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
      'estimatedVeinSize': estimatedVeinSize,
      'minVeinSize': minVeinSize,
      'maxVeinSize': maxVeinSize,
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
      case OreType.copper:
        return 'copper';
      case OreType.emerald:
        return 'emerald';
    }
  }

  @override
  String toString() {
    return 'OreLocation(x: $x, y: $y, z: $z, probability: ${(probability * 100).toStringAsFixed(1)}%, veinSize: ~$estimatedVeinSize blocks)';
  }
}
