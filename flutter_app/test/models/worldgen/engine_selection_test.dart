// Feature: seed-accurate-worldgen
//   Property 1: Engine selection is total and singular.
//     Validates: Requirements 1.5
//   Property 9: Accurate requests that cannot run degrade to Estimate.
//     Validates: Requirements 5.1, 5.2, 5.3, 11.3
//   Property 10: Every fallback carries its reason.
//     Validates: Requirements 5.4

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/accurate_engine.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/engine_selector.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/simulated_engine.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/version_strategy_registry.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_backend.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';

import 'fakes.dart';

void main() {
  const simulated = SimulatedEngine();

  // The versions we treat as supported for selection.
  final verifiedVersion = const MinecraftVersion('java-1.20');
  final unverifiedVersion = const MinecraftVersion('java-1.19');
  final unsupportedVersion = const MinecraftVersion('java-9.99');

  VersionStrategyRegistry buildRegistry() {
    final r = VersionStrategyRegistry();
    r.register(FakeVersionStrategy(verifiedVersion), verified: true);
    r.register(FakeVersionStrategy(unverifiedVersion));
    return r;
  }

  AccurateEngine buildAccurate(VersionStrategyRegistry registry, Platform p) {
    return AccurateEngine(
      registry: registry,
      platform: p,
      selectBackend: (_) => RunnableFakeBackend(),
    );
  }

  EngineSelectionContext ctx({
    required SearchMode mode,
    required MinecraftVersion version,
    required Platform platform,
    required VersionStrategyRegistry registry,
    required AccurateEngine accurate,
    bool Function(MinecraftVersion, MinecraftEdition)? webCanRun,
  }) {
    return EngineSelectionContext(
      mode: mode,
      version: version,
      edition: version.edition,
      platform: platform,
      registry: registry,
      simulated: simulated,
      accurate: accurate,
      webCanRun: webCanRun ??
          (v, e) => false, // default: web cannot run -> degrade on web
    );
  }

  group('Property 1: engine selection is total and singular', () {
    test('every (mode, version, platform) resolves to exactly one engine', () {
      final registry = buildRegistry();
      final rng = Random(1);
      final versions = [
        verifiedVersion,
        unverifiedVersion,
        unsupportedVersion,
      ];
      for (int i = 0; i < 200; i++) {
        final mode = SearchMode.values[rng.nextInt(SearchMode.values.length)];
        final version = versions[rng.nextInt(versions.length)];
        final platform =
            Platform.values[rng.nextInt(Platform.values.length)];
        // Web can run only the verified version in this scenario.
        final accurate = buildAccurate(registry, platform);
        final engine = selectEngine(ctx(
          mode: mode,
          version: version,
          platform: platform,
          registry: registry,
          accurate: accurate,
          webCanRun: (v, e) => v == verifiedVersion,
        ));

        // Totality + singularity: result is one of the two provided engines.
        final isSim = identical(engine, simulated);
        final isAcc = identical(engine, accurate);
        expect(isSim ^ isAcc, isTrue,
            reason: 'exactly one engine for ($mode,$version,$platform)');

        // Routing table checks.
        if (mode == SearchMode.estimate) {
          expect(isSim, isTrue, reason: 'Estimate -> Simulated');
        } else {
          // Accurate requested.
          if (version == unverifiedVersion ||
              version == unsupportedVersion) {
            expect(isSim, isTrue, reason: 'unverified -> Simulated');
          } else if (platform == Platform.web &&
              version != verifiedVersion) {
            expect(isSim, isTrue, reason: 'web cannot run -> Simulated');
          } else {
            expect(isAcc, isTrue, reason: 'verified + runnable -> Accurate');
          }
        }
      }
    });

    test('Estimate always resolves to Simulated regardless of version', () {
      final registry = buildRegistry();
      for (final p in Platform.values) {
        final accurate = buildAccurate(registry, p);
        final engine = selectEngine(ctx(
          mode: SearchMode.estimate,
          version: verifiedVersion,
          platform: p,
          registry: registry,
          accurate: accurate,
        ));
        expect(identical(engine, simulated), isTrue);
      }
    });

    test('Accurate + unverified version degrades to Simulated (Req 5.2)', () {
      final registry = buildRegistry();
      final accurate = buildAccurate(registry, Platform.linux);
      final engine = selectEngine(ctx(
        mode: SearchMode.accurate,
        version: unverifiedVersion,
        platform: Platform.linux,
        registry: registry,
        accurate: accurate,
      ));
      expect(identical(engine, simulated), isTrue);
    });

    test('Accurate + web-cannot-run degrades to Simulated (Req 5.1)', () {
      final registry = buildRegistry();
      final accurate = buildAccurate(registry, Platform.web);
      final engine = selectEngine(ctx(
        mode: SearchMode.accurate,
        version: verifiedVersion,
        platform: Platform.web,
        registry: registry,
        accurate: accurate,
        webCanRun: (v, e) => false,
      ));
      expect(identical(engine, simulated), isTrue);
    });

    test('Accurate + verified + native runs Accurate', () {
      final registry = buildRegistry();
      final accurate = buildAccurate(registry, Platform.android);
      final engine = selectEngine(ctx(
        mode: SearchMode.accurate,
        version: verifiedVersion,
        platform: Platform.android,
        registry: registry,
        accurate: accurate,
      ));
      expect(identical(engine, accurate), isTrue);
    });
  });

  group('Property 9: accurate requests that cannot run degrade (dispatch)', () {
    // When the AccurateEngine itself returns EngineUnavailable at runtime (e.g.
    // FFI load failure on a device that should support it), the dispatch layer
    // must fall back and the result must carry a reason (Property 10).
    final version = verifiedVersion;

    OreQuery oreQuery() => OreQuery(
          seed: '42',
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

    test('EngineUnavailable from a throwing backend is surfaced', () async {
      final registry = buildRegistry();
      final engine = AccurateEngine(
        registry: registry,
        platform: Platform.linux,
        selectBackend: (_) => ThrowingFakeBackend(),
      );
      final r = await engine.findOres(oreQuery());
      expect(r, isA<EngineUnavailable<OreLocation>>());
      expect((r as EngineUnavailable<OreLocation>).reason,
          FallbackReason.ffiLoadFailure);
    });
  });

  group('Property 10: every fallback reason has non-empty text', () {
    test('all FallbackReason values carry non-empty display text', () {
      for (final reason in FallbackReason.values) {
        expect(reason.text, isNotEmpty, reason: '$reason must have text');
      }
    });
  });
}
