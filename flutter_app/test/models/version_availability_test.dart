// Unit tests for VersionAvailability — the single source of truth for which
// ores/structures exist in a given Minecraft version era and edition.
//
// These lock down the content-gating rules so the edition/version selectors
// stay honest: a pre-1.18 ("legacy") world must not offer 1.16+/1.17+/1.19+
// content (Netherite, Copper, Ancient City, Bastion, Ruined Portal, Abandoned
// Camp), while everything older remains available in both eras.

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/version_availability.dart';

void main() {
  group('VersionAvailability — ores', () {
    test('Legacy excludes Netherite (1.16) and Copper (1.17)', () {
      for (final edition in MinecraftEdition.values) {
        expect(
          VersionAvailability.isOreAvailable(OreType.netherite,
              era: VersionEra.legacy, edition: edition),
          isFalse,
          reason: 'Netherite did not exist pre-1.18',
        );
        expect(
          VersionAvailability.isOreAvailable(OreType.copper,
              era: VersionEra.legacy, edition: edition),
          isFalse,
          reason: 'Copper did not exist pre-1.18',
        );
      }
    });

    test('Legacy still includes the classic ores', () {
      const classic = [
        OreType.diamond,
        OreType.gold,
        OreType.redstone,
        OreType.iron,
        OreType.coal,
        OreType.lapis,
        OreType.emerald,
      ];
      for (final ore in classic) {
        expect(
          VersionAvailability.isOreAvailable(ore,
              era: VersionEra.legacy, edition: MinecraftEdition.java),
          isTrue,
          reason: '${ore.name} predates 1.18',
        );
      }
    });

    test('Modern includes every ore type', () {
      for (final ore in OreType.values) {
        expect(
          VersionAvailability.isOreAvailable(ore,
              era: VersionEra.modern, edition: MinecraftEdition.bedrock),
          isTrue,
        );
      }
    });

    test('availableOres preserves canonical order and filters legacy', () {
      final legacy = VersionAvailability.availableOres(
          era: VersionEra.legacy, edition: MinecraftEdition.java);
      expect(legacy, isNot(contains(OreType.netherite)));
      expect(legacy, isNot(contains(OreType.copper)));
      // Order matches OreType.values order for the surviving entries.
      final expectedOrder =
          OreType.values.where((o) => legacy.contains(o)).toList();
      expect(legacy, equals(expectedOrder));

      final modern = VersionAvailability.availableOres(
          era: VersionEra.modern, edition: MinecraftEdition.java);
      expect(modern, equals(OreType.values));
    });
  });

  group('VersionAvailability — structures', () {
    test('Legacy excludes 1.16+/1.19+/Third-Drop structures', () {
      const modernOnly = [
        StructureType.ancientCity,
        StructureType.bastionRemnant,
        StructureType.ruinedPortal,
        StructureType.abandonedCamp,
      ];
      for (final s in modernOnly) {
        expect(
          VersionAvailability.isStructureAvailable(s,
              era: VersionEra.legacy, edition: MinecraftEdition.java),
          isFalse,
          reason: '${s.name} should not appear in a pre-1.18 world',
        );
      }
    });

    test('Legacy keeps the classic structures', () {
      const classic = [
        StructureType.village,
        StructureType.stronghold,
        StructureType.endCity,
        StructureType.netherFortress,
        StructureType.oceanMonument,
        StructureType.woodlandMansion,
        StructureType.pillagerOutpost,
        StructureType.shipwreck,
        StructureType.buriedTreasure,
        StructureType.desertTemple,
        StructureType.jungleTemple,
        StructureType.witchHut,
      ];
      for (final s in classic) {
        expect(
          VersionAvailability.isStructureAvailable(s,
              era: VersionEra.legacy, edition: MinecraftEdition.java),
          isTrue,
          reason: '${s.name} predates 1.18',
        );
      }
    });

    test('Modern includes every structure type', () {
      for (final s in StructureType.values) {
        expect(
          VersionAvailability.isStructureAvailable(s,
              era: VersionEra.modern, edition: MinecraftEdition.bedrock),
          isTrue,
        );
      }
    });

    test('availableStructures filters legacy and keeps order', () {
      final legacy = VersionAvailability.availableStructures(
          era: VersionEra.legacy, edition: MinecraftEdition.java);
      expect(legacy, isNot(contains(StructureType.ancientCity)));
      expect(legacy, isNot(contains(StructureType.abandonedCamp)));
      final expectedOrder =
          StructureType.values.where((s) => legacy.contains(s)).toList();
      expect(legacy, equals(expectedOrder));
    });
  });
}
