// Feature: edition-version-selection, Property 6: Modern mode restricts ore locations to modern Y ranges
// **Validates: Requirements 8.5**
//
// For any MinecraftEdition and for any ore type, when versionEra is
// VersionEra.modern, all ore locations returned by OreFinder.findOres SHALL
// have Y coordinates within the modern 1.18+ Y range for that ore type
// (within world depth -64 to 320).

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_finder.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';

void main() {
  group('Property 6: Modern mode restricts ore locations to modern Y ranges',
      () {
    final inputRng = Random(42);

    /// All ore types to test in modern mode.
    const allOreTypes = OreType.values;

    const editions = MinecraftEdition.values;

    /// Modern Y ranges per ore type (from OreFinder._getYRange and
    /// _isValidOreLayer). We use the widest valid range for each ore type
    /// since biome can shift gold's range.
    final Map<OreType, List<int>> modernYRanges = {
      OreType.diamond: [-64, 16],
      OreType.gold: [-64, 256], // widest (badlands); normal is -64..32
      OreType.netherite: [8, 22],
      OreType.redstone: [-64, 15],
      OreType.iron: [-64, 320],
      OreType.coal: [0, 192],
      OreType.lapis: [-64, 64],
    };

    for (final edition in editions) {
      for (final oreType in allOreTypes) {
        final range = modernYRanges[oreType]!;
        final minY = range[0];
        final maxY = range[1];

        test(
            'All ${oreType.name} locations in modern mode (${edition.name}) '
            'have Y within $minY–$maxY and world depth -64 to 320', () async {
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
            versionEra: VersionEra.modern,
          );

          for (final loc in locations) {
            expect(loc.y, greaterThanOrEqualTo(-64),
                reason:
                    '${oreType.name} at y=${loc.y}: below modern world depth -64');
            expect(loc.y, lessThanOrEqualTo(320),
                reason:
                    '${oreType.name} at y=${loc.y}: above modern world height 320');
            expect(loc.y, greaterThanOrEqualTo(minY),
                reason:
                    '${oreType.name} at y=${loc.y}: below modern min $minY');
            expect(loc.y, lessThanOrEqualTo(maxY),
                reason:
                    '${oreType.name} at y=${loc.y}: above modern max $maxY');
          }
        });
      }
    }
  });
}
