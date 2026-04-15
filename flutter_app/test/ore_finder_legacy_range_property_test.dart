// Feature: edition-version-selection, Property 5: Legacy mode restricts ore locations to legacy Y ranges
// **Validates: Requirements 4.6, 8.4**
//
// For any MinecraftEdition and for any ore type (except netherite, which uses
// the same range in both eras), when versionEra is VersionEra.legacy, all ore
// locations returned by OreFinder.findOres SHALL have Y coordinates within the
// legacy Y range for that ore type and within world height 0–256.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/legacy_density_function.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_finder.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';

void main() {
  group('Property 5: Legacy mode restricts ore locations to legacy Y ranges',
      () {
    final inputRng = Random(99);
    const int iterations = 12; // one per (edition, oreType) combo

    /// Ore types to test — excludes netherite (same range in both eras).
    const legacyOreTypes = [
      OreType.diamond,
      OreType.gold,
      OreType.iron,
      OreType.coal,
      OreType.redstone,
      OreType.lapis,
    ];

    const editions = MinecraftEdition.values;

    /// Map OreType enum to the string key used in LegacyDensityFunction.oreYRanges.
    String oreTypeToString(OreType oreType) {
      switch (oreType) {
        case OreType.diamond:
          return 'diamond';
        case OreType.gold:
          return 'gold';
        case OreType.iron:
          return 'iron';
        case OreType.coal:
          return 'coal';
        case OreType.redstone:
          return 'redstone';
        case OreType.lapis:
          return 'lapis';
        case OreType.netherite:
          return 'netherite';
      }
    }

    for (final edition in editions) {
      for (final oreType in legacyOreTypes) {
        final oreStr = oreTypeToString(oreType);
        final range = LegacyDensityFunction.oreYRanges[oreStr]!;
        final minY = range[0];
        final maxY = range[1];

        test(
            'All $oreStr locations in legacy mode (${edition.name}) '
            'have Y within $minY–$maxY and world height 0–256', () async {
          final seed = inputRng.nextInt(1 << 31).toString();
          final oreFinder = OreFinder();

          final locations = await oreFinder.findOres(
            seed: seed,
            centerX: 0,
            centerY: (minY + maxY) ~/ 2,
            centerZ: 0,
            radius: 25,
            oreType: oreType,
            minProbability: 0.01,
            edition: edition,
            versionEra: VersionEra.legacy,
          );

          for (final loc in locations) {
            expect(loc.y, greaterThanOrEqualTo(0),
                reason: '$oreStr at y=${loc.y}: below world height 0');
            expect(loc.y, lessThanOrEqualTo(256),
                reason: '$oreStr at y=${loc.y}: above world height 256');
            expect(loc.y, greaterThanOrEqualTo(minY),
                reason: '$oreStr at y=${loc.y}: below legacy min $minY');
            expect(loc.y, lessThanOrEqualTo(maxY),
                reason: '$oreStr at y=${loc.y}: above legacy max $maxY');
          }
        });
      }
    }
  });
}
