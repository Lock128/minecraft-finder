// Fixture generator for the seed-accurate worldgen golden suite.
//
// IMPORTANT: the values this emits are ALGORITHM-DERIVED. They are produced by
// the pure-Dart placement math in `lib/models/worldgen/` and are marked as
// such via the `"source"` field in each fixture. They are NOT externally
// authoritative (Cubiomes/Chunkbase) values. They give the parameterized
// golden suite deterministic, self-consistent references that lock the web
// backend's behaviour against regression and that a later live native run can
// replace with externally-verified coordinates.
//
// Run with: dart run tool/gen_worldgen_fixtures.dart

import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/java_biome.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/java_version_strategy.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_backend.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';

Future<void> main() async {
  const backend = DartWebBackend();
  final versions = <String, JavaVersionStrategy>{
    'java-1.18': JavaVersionStrategy.java118(),
    'java-1.19': JavaVersionStrategy.java119(),
    'java-1.20': JavaVersionStrategy.java120(),
  };

  // One seed per version (distinct so fixtures are not trivially identical).
  final seeds = <String, int>{
    'java-1.18': 3257840388504953787,
    'java-1.19': -4172144997902289642,
    'java-1.20': 123456789,
  };

  for (final entry in versions.entries) {
    final dir = entry.key;
    final strategy = entry.value;
    final release = dir.split('-').last;
    final seedInt = seeds[dir]!;
    final seed = Int64(seedInt);
    final mcVersion = MinecraftVersion(dir);

    StructureQuery structQuery(Set<StructureType> types, int radius) =>
        StructureQuery(
          seed: '$seedInt',
          centerX: 0,
          centerZ: 0,
          radius: radius,
          structureTypes: types,
          maxResults: 1,
          edition: MinecraftEdition.java,
          version: mcVersion,
        );

    // --- Structures: driven through the backend so fixtures match emission
    // (including biome gating) exactly. ---
    final structures = <Map<String, dynamic>>[];

    final villageOut = await backend.computeStructures(
        structQuery({StructureType.village}, 6000), strategy);
    if (villageOut.isNotEmpty) {
      structures.add(_structJson(villageOut.first));
    }

    final strongholdOut = await backend.computeStructures(
        structQuery({StructureType.stronghold}, 12000), strategy);
    if (strongholdOut.isNotEmpty) {
      structures.add(_structJson(strongholdOut.first));
    }

    // Buried treasure: widen the radius until the backend finds one.
    for (final r in const [1600, 4000, 8000]) {
      final btOut = await backend.computeStructures(
          structQuery({StructureType.buriedTreasure}, r), strategy);
      if (btOut.isNotEmpty) {
        structures.add(_structJson(btOut.first));
        break;
      }
    }

    // --- Biome samples at a few coordinates (via the backend). ---
    final biomeSamples = <Map<String, dynamic>>[];
    for (final coord in const [
      [0, 0],
      [1000, -1000],
      [-2000, 2000],
    ]) {
      biomeSamples.add({
        'x': coord[0],
        'z': coord[1],
        'biome': JavaBiome.computeBiome(
          worldSeed: seed,
          x: coord[0],
          z: coord[1],
          params: strategy.biomeParams,
        ),
      });
    }

    // --- Ores: first diamond vein near origin (via the backend). ---
    final ores = <Map<String, dynamic>>[];
    final oreOut = await backend.computeOres(
      OreQuery(
        seed: '$seedInt',
        centerX: 0,
        centerY: 0,
        centerZ: 0,
        radius: 256,
        oreType: OreType.diamond,
        includeNether: false,
        edition: MinecraftEdition.java,
        version: mcVersion,
        maxResults: 1,
      ),
      strategy,
    );
    if (oreOut.isNotEmpty) {
      final o = oreOut.first;
      ores.add({
        'oreType': 'diamond',
        'x': o.x,
        'y': o.y,
        'z': o.z,
        'veinSize': o.estimatedVeinSize,
      });
    }

    final fixture = <String, dynamic>{
      'edition': 'java',
      'version': release,
      'seed': '$seedInt',
      'source': 'algorithm-derived',
      'description':
          'Golden fixture for Java $release. Reference values are ALGORITHM-'
              'DERIVED by the pure-Dart DartWebBackend placement math (region-'
              'grid salted placement, stronghold ring LCG walk, multi-noise '
              'climate, count x tries ore loops) and marked "source": '
              '"algorithm-derived". They are deterministic and self-consistent '
              'but NOT externally verified against Cubiomes/Chunkbase; a later '
              'live native run should replace them with externally-authoritative '
              'coordinates and flip the registry isVerified flag.',
      'structures': structures,
      'biomeSamples': biomeSamples,
      'ores': ores,
    };

    final outDir = Directory('test/fixtures/worldgen/$dir');
    outDir.createSync(recursive: true);
    final file = File('${outDir.path}/fixture.json');
    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync('${encoder.convert(fixture)}\n');
    stdout.writeln('wrote ${file.path} '
        '(${structures.length} structures, ${biomeSamples.length} biomes, '
        '${ores.length} ores)');
  }
}

Map<String, dynamic> _structJson(StructureLocation s) => {
      'structureType': s.structureType.toString().split('.').last,
      'x': s.x,
      'y': s.y,
      'z': s.z,
      'chunkX': s.chunkX,
      'chunkZ': s.chunkZ,
      'biome': s.biome,
    };
