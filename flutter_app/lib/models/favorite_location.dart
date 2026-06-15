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

  int get x {
    if (type == FavoriteType.ore) {
      if (oreLocation == null) {
        throw StateError('FavoriteLocation of type ore has null oreLocation');
      }
      return oreLocation!.x;
    }
    if (structureLocation == null) {
      throw StateError('FavoriteLocation of type structure has null structureLocation');
    }
    return structureLocation!.x;
  }

  int get y {
    if (type == FavoriteType.ore) {
      if (oreLocation == null) {
        throw StateError('FavoriteLocation of type ore has null oreLocation');
      }
      return oreLocation!.y;
    }
    if (structureLocation == null) {
      throw StateError('FavoriteLocation of type structure has null structureLocation');
    }
    return structureLocation!.y;
  }

  int get z {
    if (type == FavoriteType.ore) {
      if (oreLocation == null) {
        throw StateError('FavoriteLocation of type ore has null oreLocation');
      }
      return oreLocation!.z;
    }
    if (structureLocation == null) {
      throw StateError('FavoriteLocation of type structure has null structureLocation');
    }
    return structureLocation!.z;
  }

  String get displayName {
    if (label.isNotEmpty) return label;
    if (type == FavoriteType.ore) {
      if (oreLocation == null) return 'ore ($x, $y, $z)';
      return '${oreLocation!.oreType.name} ($x, $y, $z)';
    }
    if (structureLocation == null) return 'structure ($x, $y, $z)';
    return '${structureLocation!.structureType.name} ($x, $y, $z)';
  }

  factory FavoriteLocation.fromJson(Map<String, dynamic> json) {
    final type = json['type'] == 'ore' ? FavoriteType.ore : FavoriteType.structure;
    final oreLocation = json['oreLocation'] != null
        ? OreLocation.fromJson(json['oreLocation'] as Map<String, dynamic>)
        : null;
    final structureLocation = json['structureLocation'] != null
        ? StructureLocation.fromJson(
            json['structureLocation'] as Map<String, dynamic>)
        : null;

    // Validate that the location matching the type is present
    assert(
      type != FavoriteType.ore || oreLocation != null,
      'FavoriteLocation of type ore must have a non-null oreLocation',
    );
    assert(
      type != FavoriteType.structure || structureLocation != null,
      'FavoriteLocation of type structure must have a non-null structureLocation',
    );

    return FavoriteLocation(
      id: json['id'] as String,
      type: type,
      oreLocation: oreLocation,
      structureLocation: structureLocation,
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
