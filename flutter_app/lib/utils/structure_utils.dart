import 'package:flutter/material.dart';
import '../models/structure_location.dart';

class StructureUtils {
  static String getStructureEmoji(StructureType structureType) {
    switch (structureType) {
      case StructureType.village:
        return '🏘️';
      case StructureType.stronghold:
        return '🏛️';
      case StructureType.endCity:
        return '🌃';
      case StructureType.netherFortress:
        return '🏰';
      case StructureType.bastionRemnant:
        return '🏯';
      case StructureType.ancientCity:
        return '🏛️';
      case StructureType.oceanMonument:
        return '🌊';
      case StructureType.woodlandMansion:
        return '🏚️';
      case StructureType.pillagerOutpost:
        return '🗼';
      case StructureType.ruinedPortal:
        return '🌀';
      case StructureType.shipwreck:
        return '🚢';
      case StructureType.buriedTreasure:
        return '💰';
      case StructureType.desertTemple:
        return '🏜️';
      case StructureType.jungleTemple:
        return '🌿';
      case StructureType.witchHut:
        return '🧙';
      case StructureType.abandonedCamp:
        return '⛺';
    }
  }

  static String getStructureName(StructureType structureType) {
    switch (structureType) {
      case StructureType.village:
        return 'Village';
      case StructureType.stronghold:
        return 'Stronghold';
      case StructureType.endCity:
        return 'End City';
      case StructureType.netherFortress:
        return 'Nether Fortress';
      case StructureType.bastionRemnant:
        return 'Bastion Remnant';
      case StructureType.ancientCity:
        return 'Ancient City';
      case StructureType.oceanMonument:
        return 'Ocean Monument';
      case StructureType.woodlandMansion:
        return 'Woodland Mansion';
      case StructureType.pillagerOutpost:
        return 'Pillager Outpost';
      case StructureType.ruinedPortal:
        return 'Ruined Portal';
      case StructureType.shipwreck:
        return 'Shipwreck';
      case StructureType.buriedTreasure:
        return 'Buried Treasure';
      case StructureType.desertTemple:
        return 'Desert Temple';
      case StructureType.jungleTemple:
        return 'Jungle Temple';
      case StructureType.witchHut:
        return 'Witch Hut';
      case StructureType.abandonedCamp:
        return 'Abandoned Camp';
    }
  }

  static Color getRarityColor(String rarity) {
    switch (rarity) {
      case 'Very Common':
        return Colors.green;
      case 'Common':
        return Colors.lightGreen;
      case 'Uncommon':
        return Colors.orange;
      case 'Rare':
        return Colors.red;
      case 'Very Rare':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static List<Map<String, dynamic>> getAllStructures() {
    return [
      {
        'type': StructureType.village,
        'name': '🏘️ Village',
        'rarity': 'Common'
      },
      {
        'type': StructureType.stronghold,
        'name': '🏛️ Stronghold',
        'rarity': 'Rare'
      },
      {'type': StructureType.endCity, 'name': '🌃 End City', 'rarity': 'Rare'},
      {
        'type': StructureType.netherFortress,
        'name': '🏰 Nether Fortress',
        'rarity': 'Uncommon'
      },
      {
        'type': StructureType.bastionRemnant,
        'name': '🏯 Bastion Remnant',
        'rarity': 'Uncommon'
      },
      {
        'type': StructureType.ancientCity,
        'name': '🏛️ Ancient City',
        'rarity': 'Very Rare'
      },
      {
        'type': StructureType.oceanMonument,
        'name': '🌊 Ocean Monument',
        'rarity': 'Rare'
      },
      {
        'type': StructureType.woodlandMansion,
        'name': '🏚️ Woodland Mansion',
        'rarity': 'Very Rare'
      },
      {
        'type': StructureType.pillagerOutpost,
        'name': '🗼 Pillager Outpost',
        'rarity': 'Common'
      },
      {
        'type': StructureType.abandonedCamp,
        'name': '⛺ Abandoned Camp',
        'rarity': 'Common'
      },
      {
        'type': StructureType.ruinedPortal,
        'name': '🌀 Ruined Portal',
        'rarity': 'Very Common'
      },
      {
        'type': StructureType.shipwreck,
        'name': '🚢 Shipwreck',
        'rarity': 'Common'
      },
      {
        'type': StructureType.buriedTreasure,
        'name': '💰 Buried Treasure',
        'rarity': 'Uncommon'
      },
      {
        'type': StructureType.desertTemple,
        'name': '🏜️ Desert Temple',
        'rarity': 'Uncommon'
      },
      {
        'type': StructureType.jungleTemple,
        'name': '🌿 Jungle Temple',
        'rarity': 'Rare'
      },
      {
        'type': StructureType.witchHut,
        'name': '🧙 Witch Hut',
        'rarity': 'Rare'
      },
    ];
  }
}
