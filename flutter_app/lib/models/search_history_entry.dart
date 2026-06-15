import 'game_random.dart';
import 'ore_location.dart';
import 'structure_location.dart';

/// A record of a past search that can be replayed.
class SearchHistoryEntry {
  final String seed;
  final int centerX;
  final int centerY;
  final int centerZ;
  final int radius;
  final Set<OreType> oreTypes;
  final Set<StructureType> structures;
  final MinecraftEdition edition;
  final VersionEra versionEra;
  final DateTime timestamp;
  final int resultCount;
  final bool includeOres;
  final bool includeStructures;

  SearchHistoryEntry({
    required this.seed,
    required this.centerX,
    required this.centerY,
    required this.centerZ,
    required this.radius,
    required this.oreTypes,
    required this.structures,
    required this.edition,
    required this.versionEra,
    required this.timestamp,
    required this.resultCount,
    required this.includeOres,
    required this.includeStructures,
  });

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SearchHistoryEntry(
      seed: json['seed'] as String,
      centerX: json['centerX'] as int,
      centerY: json['centerY'] as int,
      centerZ: json['centerZ'] as int,
      radius: json['radius'] as int,
      oreTypes: (json['oreTypes'] as List<dynamic>)
          .map((e) => OreType.values.firstWhere(
                (o) => o.name == e,
                orElse: () => OreType.diamond,
              ))
          .toSet(),
      structures: (json['structures'] as List<dynamic>)
          .map((e) => StructureType.values.firstWhere(
                (s) => s.name == e,
                orElse: () => StructureType.village,
              ))
          .toSet(),
      edition: json['edition'] == 'bedrock'
          ? MinecraftEdition.bedrock
          : MinecraftEdition.java,
      versionEra:
          json['versionEra'] == 'legacy' ? VersionEra.legacy : VersionEra.modern,
      timestamp: DateTime.parse(json['timestamp'] as String),
      resultCount: json['resultCount'] as int,
      includeOres: json['includeOres'] as bool? ?? true,
      includeStructures: json['includeStructures'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seed': seed,
      'centerX': centerX,
      'centerY': centerY,
      'centerZ': centerZ,
      'radius': radius,
      'oreTypes': oreTypes.map((e) => e.name).toList(),
      'structures': structures.map((e) => e.name).toList(),
      'edition': edition.name,
      'versionEra': versionEra.name,
      'timestamp': timestamp.toIso8601String(),
      'resultCount': resultCount,
      'includeOres': includeOres,
      'includeStructures': includeStructures,
    };
  }
}
