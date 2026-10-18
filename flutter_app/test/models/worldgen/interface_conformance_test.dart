// Interface-conformance tests for the WorldGenEngine layer (spec task 1.2).
//
// Asserts both engine types satisfy WorldGenEngine and that EngineResult
// values are isolate-serializable (only primitives/enums/model objects).

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/accurate_engine.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/native_ffi_backend.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/simulated_engine.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/version_strategy_registry.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_backend.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';

void main() {
  group('WorldGenEngine conformance', () {
    test('SimulatedEngine satisfies WorldGenEngine', () {
      const WorldGenEngine engine = SimulatedEngine();
      expect(engine, isA<WorldGenEngine>());
    });

    test('AccurateEngine satisfies WorldGenEngine', () {
      final WorldGenEngine engine = AccurateEngine(
        registry: VersionStrategyRegistry(),
        platform: Platform.linux,
        selectBackend: (p) => selectBackend(
          p,
          dartWebBackend: const DartWebBackend(),
          nativeFfiBackend: NativeFfiBackend(),
        ),
      );
      expect(engine, isA<WorldGenEngine>());
    });
  });

  group('EngineResult is isolate-serializable', () {
    test('EngineOk holds a list of model objects and a ResultMeta', () {
      final ok = EngineOk<OreLocation>(
        [
          OreLocation(
            x: 1,
            y: 2,
            z: 3,
            chunkX: 0,
            chunkZ: 0,
            probability: 0.5,
            oreType: OreType.diamond,
          ),
        ],
        meta: const ResultMeta(veinSize: 4, biome: 'plains'),
      );
      expect(ok.results, hasLength(1));
      expect(ok.meta.veinSize, 4);
      expect(ok.meta.biome, 'plains');
      // Model objects expose a JSON map of primitives.
      expect(ok.results.first.toJson(), isA<Map<String, dynamic>>());
    });

    test('ResultMeta.empty carries nothing', () {
      const meta = ResultMeta.empty();
      expect(meta.veinSize, isNull);
      expect(meta.structureVariant, isNull);
      expect(meta.biome, isNull);
    });

    test('EngineUnavailable carries an enum reason with text', () {
      for (final reason in FallbackReason.values) {
        final r = EngineUnavailable<StructureLocation>(reason);
        expect(r.reason, isA<FallbackReason>());
        expect(r.reason.text, isNotEmpty);
      }
    });

    test('EngineUnsupportedVersion carries version + edition', () {
      final r = EngineUnsupportedVersion<StructureLocation>(
        const MinecraftVersion('java-9.99'),
        MinecraftEdition.java,
      );
      expect(r.version.id, 'java-9.99');
      expect(r.edition, MinecraftEdition.java);
    });
  });
}
