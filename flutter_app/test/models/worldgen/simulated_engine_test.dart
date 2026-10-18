// Property 2: Simulated engine delegates faithfully (spec task 2.2).
// Feature: seed-accurate-worldgen, Property 2: SimulatedEngine returns results
// identical to the corresponding legacy OreFinder/StructureFinder call.
// Validates: Requirements 1.3

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_finder.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_finder.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/simulated_engine.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';

void main() {
  const engine = SimulatedEngine();

  const oreTypes = OreType.values;
  const structureTypes = StructureType.values;

  test(
    'Property 2: SimulatedEngine ore output equals direct OreFinder output',
    () async {
      final rng = Random(2024);
      for (int i = 0; i < 100; i++) {
        final seed = 'prop2-ore-$i-${rng.nextInt(1 << 30)}';
        final centerX = rng.nextInt(2000) - 1000;
        final centerZ = rng.nextInt(2000) - 1000;
        final centerY = rng.nextInt(200) - 60;
        final radius = 16 + rng.nextInt(48);
        final oreType = oreTypes[rng.nextInt(oreTypes.length)];
        final edition = rng.nextBool()
            ? MinecraftEdition.java
            : MinecraftEdition.bedrock;
        final era = rng.nextBool() ? VersionEra.legacy : VersionEra.modern;
        final version = MinecraftVersion.of(
            edition, era == VersionEra.legacy ? '1.16' : '1.20');
        final maxResults = 50 + rng.nextInt(100);

        final direct = await OreFinder().findOres(
          seed: seed,
          centerX: centerX,
          centerY: centerY,
          centerZ: centerZ,
          radius: radius,
          oreType: oreType,
          edition: edition,
          versionEra: era,
          maxResults: maxResults,
        );

        final viaEngine = await engine.findOres(OreQuery(
          seed: seed,
          centerX: centerX,
          centerY: centerY,
          centerZ: centerZ,
          radius: radius,
          oreType: oreType,
          includeNether: false,
          edition: edition,
          version: version,
          maxResults: maxResults,
        ));

        expect(viaEngine, isA<EngineOk<OreLocation>>());
        final results = (viaEngine as EngineOk<OreLocation>).results;
        expect(_oreKeys(results), _oreKeys(direct),
            reason: 'iteration $i ($oreType, $edition, $era)');
      }
    },
  );

  test(
    'Property 2: SimulatedEngine structure output equals direct finder output',
    () async {
      final rng = Random(7);
      for (int i = 0; i < 100; i++) {
        final seed = 'prop2-struct-$i-${rng.nextInt(1 << 30)}';
        final centerX = rng.nextInt(4000) - 2000;
        final centerZ = rng.nextInt(4000) - 2000;
        final radius = 500 + rng.nextInt(1500);
        final edition = rng.nextBool()
            ? MinecraftEdition.java
            : MinecraftEdition.bedrock;
        final era = rng.nextBool() ? VersionEra.legacy : VersionEra.modern;
        final version = MinecraftVersion.of(
            edition, era == VersionEra.legacy ? '1.16' : '1.20');
        final maxResults = 50 + rng.nextInt(100);

        // Pick 1-3 random structure types.
        final types = <StructureType>{};
        final n = 1 + rng.nextInt(3);
        for (int k = 0; k < n; k++) {
          types.add(structureTypes[rng.nextInt(structureTypes.length)]);
        }

        final direct = await StructureFinder().findStructures(
          seed: seed,
          centerX: centerX,
          centerZ: centerZ,
          radius: radius,
          structureTypes: types,
          maxResults: maxResults,
          edition: edition,
          versionEra: era,
        );

        final viaEngine = await engine.findStructures(StructureQuery(
          seed: seed,
          centerX: centerX,
          centerZ: centerZ,
          radius: radius,
          structureTypes: types,
          maxResults: maxResults,
          edition: edition,
          version: version,
        ));

        expect(viaEngine, isA<EngineOk<StructureLocation>>());
        final results = (viaEngine as EngineOk<StructureLocation>).results;
        expect(_structKeys(results), _structKeys(direct),
            reason: 'iteration $i ($types, $edition, $era)');
      }
    },
  );
}

List<String> _oreKeys(List<OreLocation> list) => list
    .map((o) => '${o.oreType}:${o.x},${o.y},${o.z}:${o.probability}')
    .toList();

List<String> _structKeys(List<StructureLocation> list) => list
    .map((s) => '${s.structureType}:${s.x},${s.y},${s.z}:${s.probability}')
    .toList();
