import '../models/ore_location.dart';
import '../models/structure_location.dart';

class OreUtils {
  static String getOreEmoji(OreType oreType) {
    switch (oreType) {
      case OreType.diamond:
        return '💎';
      case OreType.gold:
        return '🏅';
      case OreType.netherite:
        return '🔥';
      case OreType.redstone:
        return '🔴';
      case OreType.iron:
        return '⚪';
      case OreType.coal:
        return '⚫';
    }
  }

  static String getSearchDescription(
    Set<OreType> selectedOreTypes,
    bool includeOres,
    bool includeStructures,
    Set<StructureType> selectedStructures,
  ) {
    List<String> searchItems = [];

    // Add ore types if ore search is enabled
    if (includeOres) {
      if (selectedOreTypes.contains(OreType.diamond)) {
        searchItems.add('diamonds');
      }
      if (selectedOreTypes.contains(OreType.gold)) {
        searchItems.add('gold');
      }
      if (selectedOreTypes.contains(OreType.netherite)) {
        searchItems.add('netherite');
      }
      if (selectedOreTypes.contains(OreType.redstone)) {
        searchItems.add('redstone');
      }
      if (selectedOreTypes.contains(OreType.iron)) {
        searchItems.add('iron');
      }
      if (selectedOreTypes.contains(OreType.coal)) {
        searchItems.add('coal');
      }
    }

    // Add structure info if structure search is enabled
    if (includeStructures) {
      if (selectedStructures.isEmpty) {
        searchItems.add('all structures');
      } else {
        searchItems.add('${selectedStructures.length} structure types');
      }
    }

    if (searchItems.isEmpty) return 'No search items selected';
    if (searchItems.length == 1) return 'Searching for ${searchItems[0]} only';
    if (searchItems.length == 2) {
      return 'Searching for ${searchItems[0]} and ${searchItems[1]}';
    }
    return 'Searching for ${searchItems.sublist(0, searchItems.length - 1).join(', ')}, and ${searchItems.last}';
  }
}
