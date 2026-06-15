import 'ore_location.dart';
import 'structure_location.dart';

enum FavoriteType { ore, structure }

/// A bookmarked location wrapping either an OreLocation or StructureLocation
/// with additional user metadata.
class FavoriteLocation {
  final String id;
  final FavoriteType type;
  final OreLocation? oreLocation;
  final StructureLocation? structureLocation;
  final String seed;
  final DateTime timestamp;
  String label;

  FavoriteLocation({
    required this.id,
    required this.type,
    this.oreLocation,
    this.structureLocation,
    required this.seed,
    required this.timestamp,
    this.label = '',
  });

  int get x => type == FavoriteType.ore ? oreLocation!.x : structureLocation!.x;
  int get y => type == FavoriteType.ore ? oreLocation!.y : structureLocation!.y;
  int get z => type == FavoriteType.ore ? oreLocation!.z : structureLocation!.z;

  String get displayName {
    if (label.isNotEmpty) return label;
    if (type == FavoriteType.ore) {
      return '${oreLocation!.oreType.name} ($x, $y, $z)';
    }
    return '${structureLocation!.structureType.name} ($x, $y, $z)';
  }

  factory FavoriteLocation.fromJson(Map<String, dynamic> json) {
    return FavoriteLocation(
      id: json['id'] as String,
      type: json['type'] == 'ore' ? FavoriteType.ore : FavoriteType.structure,
      oreLocation: json['oreLocation'] != null
          ? OreLocation.fromJson(json['oreLocation'] as Map<String, dynamic>)
          : null,
      structureLocation: json['structureLocation'] != null
          ? StructureLocation.fromJson(
              json['structureLocation'] as Map<String, dynamic>)
          : null,
      seed: json['seed'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == FavoriteType.ore ? 'ore' : 'structure',
      'oreLocation': oreLocation?.toJson(),
      'structureLocation': structureLocation?.toJson(),
      'seed': seed,
      'timestamp': timestamp.toIso8601String(),
      'label': label,
    };
  }
}
