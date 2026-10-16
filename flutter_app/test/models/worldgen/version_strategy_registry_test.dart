// Property 7 + Property 8: strategy resolution (spec task 3.3).
// Feature: seed-accurate-worldgen
//   Property 7: Version strategy resolution is complete for supported versions.
//     Validates: Requirements 4.2, 4.3
//   Property 8: Unsupported versions report, not crash.
//     Validates: Requirements 4.4

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/accurate_engine.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/version_strategy.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/version_strategy_registry.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_backend.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';

import 'fakes.dart';

void main() {
  final supported = <MinecraftVersion>[
    const MinecraftVersion('java-1.18'),
    const MinecraftVersion('java-1.19'),
    const MinecraftVersion('java-1.20'),
    const MinecraftVersion('bedrock-1.21'),
  ];

  VersionStrategyRegistry buildRegistry() {
    final registry = VersionStrategyRegistry();
    for (final v in supported) {
      registry.register(FakeVersionStrategy(v), verified: v.id == 'java-1.20');
    }
    return registry;
  }

  test(
    'Property 7: strategy resolution is complete for supported versions',
    () {
      final registry = buildRegistry();
      final rng = Random(11);
      for (int i = 0; i < 100; i++) {
        final v = supported[rng.nextInt(supported.length)];
        expect(registry.isSupported(v), isTrue, reason: '$v should be supported');
        final strategy = registry.strategyFor(v);
        expect(strategy, isNotNull);
        // Exposes placement tables, salts, biome, ore, and RNG params.
        final placement = strategy!.placementFor(StructureType.village);
        expect(placement.spacing, greaterThan(0));
        expect(placement.separation, greaterThanOrEqualTo(0));
        expect(strategy.strongholdRings.count, greaterThan(0));
        expect(strategy.oreFeatureFor(OreType.diamond).countPerChunk,
            greaterThan(0));
        expect(strategy.rngParams, isA<RngParams>());
        expect(strategy.biomeParams, isA<BiomeParams>());
      }
    },
  );

  test(
    'Property 8: unsupported versions report EngineUnsupportedVersion',
    () async {
      final registry = buildRegistry();
      final engine = AccurateEngine(
        registry: registry,
        platform: Platform.linux,
        selectBackend: (p) => const NativeFfiBackend(),
      );

      final rng = Random(13);
      for (int i = 0; i < 100; i++) {
        final unsupported =
            MinecraftVersion('java-9.$i.${rng.nextInt(1000)}');
        expect(registry.isSupported(unsupported), isFalse);

        final sResult = await engine.findStructures(StructureQuery(
          seed: 'seed-$i',
          centerX: 0,
          centerZ: 0,
          radius: 1000,
          structureTypes: {StructureType.village},
          maxResults: 10,
          edition: MinecraftEdition.java,
          version: unsupported,
        ));
        expect(sResult, isA<EngineUnsupportedVersion<StructureLocation>>());

        final oResult = await engine.findOres(OreQuery(
          seed: 'seed-$i',
          centerX: 0,
          centerY: -59,
          centerZ: 0,
          radius: 32,
          oreType: OreType.diamond,
          includeNether: false,
          edition: MinecraftEdition.java,
          version: unsupported,
          maxResults: 10,
        ));
        expect(oResult, isA<EngineUnsupportedVersion<OreLocation>>());
      }
    },
  );

  test('isVerified is driven by fixture status', () {
    final registry = buildRegistry();
    expect(registry.isVerified(const MinecraftVersion('java-1.20')), isTrue);
    expect(registry.isVerified(const MinecraftVersion('java-1.18')), isFalse);
    registry.markVerified(const MinecraftVersion('java-1.18'));
    expect(registry.isVerified(const MinecraftVersion('java-1.18')), isTrue);
  });
}
