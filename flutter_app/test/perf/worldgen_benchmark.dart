// Performance benchmark for the seed-accurate world-gen engine.
//
// Not a pass/fail test — it times the core DartWebBackend algorithm (the
// pure-Dart hot path that runs on web and whose math is held in lock-step with
// the native backend) across a range of search radii, for both ore and
// structure searches.
//
// Run with:
//   flutter test test/perf/worldgen_benchmark.dart --no-pub -r expanded
//
// Output is printed to stdout as a table.

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/java_ore.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/java_placement.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/java_version_strategy.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_backend.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';

const String kSeed = '123456789';
final Int64 kSeedInt = Int64(123456789);

/// Median-of-[runs] async timing of [body] in microseconds, with a warmup pass.
Future<int> _timeMicros(int runs, Future<void> Function() body) async {
  await body(); // warmup (JIT / first-touch)
  final samples = <int>[];
  for (var i = 0; i < runs; i++) {
    final sw = Stopwatch()..start();
    await body();
    sw.stop();
    samples.add(sw.elapsedMicroseconds);
  }
  samples.sort();
  return samples[samples.length ~/ 2];
}

String _ms(int micros) => (micros / 1000.0).toStringAsFixed(2).padLeft(10);

int _chunksForRadius(int radius) {
  final span = (JavaPlacement.blockToChunk(radius) -
          JavaPlacement.blockToChunk(-radius)) +
      1;
  return span * span;
}

void main() {
  final strategy = JavaVersionStrategy.java120();
  const backend = DartWebBackend();

  // Radii to sweep. 50 is the free-tier cap; the rest represent Pro / power
  // users and the kind of large search a backend cache would target.
  const radii = [50, 100, 250, 500, 1000, 2000, 4000];

  test('BENCH: ore search (DartWebBackend.computeOres) vs radius', () async {
    print('\n=== Ore search: diamond, Java 1.20, seed=$kSeed ===');
    print('${"radius".padLeft(8)} ${"chunks".padLeft(10)} '
        '${"median(ms)".padLeft(10)} ${"results".padLeft(8)}  us/chunk');
    for (final r in radii) {
      final q = OreQuery(
        seed: kSeed,
        centerX: 0,
        centerY: -59,
        centerZ: 0,
        radius: r,
        oreType: OreType.diamond,
        includeNether: false,
        edition: MinecraftEdition.java,
        version: const MinecraftVersion('java-1.20'),
        maxResults: 1 << 30, // no cap — measure full scan cost
      );
      var count = 0;
      final micros = await _timeMicros(5, () async {
        final out = await backend.computeOres(q, strategy);
        count = out.length;
      });
      final chunks = _chunksForRadius(r);
      final perChunk = (micros / chunks).toStringAsFixed(2);
      print('${r.toString().padLeft(8)} ${chunks.toString().padLeft(10)} '
          '${_ms(micros)} ${count.toString().padLeft(8)}  $perChunk');
    }
  });

  test('BENCH: structure search (region grid + buried treasure) vs radius',
      () async {
    print('\n=== Structure search: village + buried treasure, Java 1.20 ===');
    print('${"radius".padLeft(8)} ${"chunks".padLeft(10)} '
        '${"median(ms)".padLeft(10)} ${"results".padLeft(8)}');
    for (final r in radii) {
      final q = StructureQuery(
        seed: kSeed,
        centerX: 0,
        centerZ: 0,
        radius: r,
        structureTypes: {
          StructureType.village,
          StructureType.buriedTreasure,
        },
        maxResults: 1 << 30,
        edition: MinecraftEdition.java,
        version: const MinecraftVersion('java-1.20'),
      );
      var count = 0;
      final micros = await _timeMicros(5, () async {
        final out = await backend.computeStructures(q, strategy);
        count = out.length;
      });
      final chunks = _chunksForRadius(r);
      print('${r.toString().padLeft(8)} ${chunks.toString().padLeft(10)} '
          '${_ms(micros)} ${count.toString().padLeft(8)}');
    }
  });

  test('BENCH: raw per-chunk ore cost (veinsInChunk)', () async {
    print('\n=== Raw per-chunk ore cost (diamond feature) ===');
    final feature = strategy.oreFeatureFor(OreType.diamond);
    const iterations = 200000;
    final sw = Stopwatch()..start();
    var sink = 0;
    for (var i = 0; i < iterations; i++) {
      final veins = JavaOre.veinsInChunk(
        worldSeed: kSeedInt,
        chunkX: i & 0xFFFF,
        chunkZ: (i >> 16) & 0xFFFF,
        feature: feature,
        featureIndex: OreType.diamond.index,
      );
      sink += veins.length;
    }
    sw.stop();
    final nsPerChunk = (sw.elapsedMicroseconds * 1000) / iterations;
    print('  $iterations chunks in ${_ms(sw.elapsedMicroseconds)} ms '
        '=> ${nsPerChunk.toStringAsFixed(1)} ns/chunk (sink=$sink)');
    // Project to large radii (single ore type).
    for (final r in [1000, 4000, 10000]) {
      final chunks = _chunksForRadius(r);
      final projMs = (chunks * nsPerChunk) / 1e6;
      print('  projected radius=$r => $chunks chunks '
          '=> ${projMs.toStringAsFixed(1)} ms (single ore type)');
    }
  });
}
