// Property 3: Backend selection matches platform (spec task 5.3).
// Feature: seed-accurate-worldgen, Property 3: AccurateEngine selects the
// NativeFfiBackend on native platforms and the DartWebBackend on web.
// Validates: Requirements 2.1, 3.1

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/accurate_engine.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/version_strategy_registry.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_backend.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';

import 'fakes.dart';

void main() {
  const web = DartWebBackend();
  const native = NativeFfiBackend();

  WorldGenBackend select(Platform p) => selectBackend(
        p,
        dartWebBackend: web,
        nativeFfiBackend: native,
      );

  test('Property 3: selectBackend returns DartWebBackend for web only', () {
    for (final p in Platform.values) {
      final b = select(p);
      if (p == Platform.web) {
        expect(b, same(web), reason: '$p should pick DartWebBackend');
      } else {
        expect(b, same(native), reason: '$p should pick NativeFfiBackend');
      }
    }
  });

  test('Property 3: randomized platforms match the routing table', () {
    final rng = Random(3);
    for (int i = 0; i < 100; i++) {
      final p = Platform.values[rng.nextInt(Platform.values.length)];
      final b = select(p);
      expect(identical(b, web), p == Platform.web);
      expect(identical(b, native), p != Platform.web);
    }
  });

  test('AccurateEngine.backend honours the selector/platform', () {
    for (final p in Platform.values) {
      final engine = AccurateEngine(
        registry: VersionStrategyRegistry(),
        platform: p,
        selectBackend: select,
      );
      if (p == Platform.web) {
        expect(engine.backend, same(web));
      } else {
        expect(engine.backend, same(native));
      }
    }
  });

  group('AccurateEngine runtime outcomes', () {
    final version = const MinecraftVersion('java-1.20');
    VersionStrategyRegistry registryWith() {
      final r = VersionStrategyRegistry();
      r.register(FakeVersionStrategy(version), verified: true);
      return r;
    }

    StructureQuery structQuery() => StructureQuery(
          seed: 's',
          centerX: 0,
          centerZ: 0,
          radius: 1000,
          structureTypes: {StructureType.village},
          maxResults: 10,
          edition: MinecraftEdition.java,
          version: version,
        );

    OreQuery oreQuery() => OreQuery(
          seed: 's',
          centerX: 0,
          centerY: -59,
          centerZ: 0,
          radius: 32,
          oreType: OreType.diamond,
          includeNether: false,
          edition: MinecraftEdition.java,
          version: version,
          maxResults: 10,
        );

    test('EngineOk when backend can run', () async {
      final backend = RunnableFakeBackend();
      final engine = AccurateEngine(
        registry: registryWith(),
        platform: Platform.linux,
        selectBackend: (_) => backend,
      );
      expect(await engine.findStructures(structQuery()),
          isA<EngineOk<StructureLocation>>());
      expect(await engine.findOres(oreQuery()), isA<EngineOk<OreLocation>>());
    });

    test('EngineUnavailable when backend cannot run (web path)', () async {
      final engine = AccurateEngine(
        registry: registryWith(),
        platform: Platform.web,
        selectBackend: (_) => const DartWebBackend(),
      );
      final r = await engine.findStructures(structQuery());
      expect(r, isA<EngineUnavailable<StructureLocation>>());
      expect((r as EngineUnavailable<StructureLocation>).reason,
          FallbackReason.webUnsupported);
    });

    test('EngineUnavailable when backend throws at runtime', () async {
      final engine = AccurateEngine(
        registry: registryWith(),
        platform: Platform.linux,
        selectBackend: (_) => ThrowingFakeBackend(),
      );
      final r = await engine.findOres(oreQuery());
      expect(r, isA<EngineUnavailable<OreLocation>>());
      expect((r as EngineUnavailable<OreLocation>).reason,
          FallbackReason.ffiLoadFailure);
    });
  });
}
