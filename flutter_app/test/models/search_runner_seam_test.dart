// Runner-seam unit test (spec task 6.4).
//
// Feature: seed-accurate-worldgen
//   - Dispatch routes through the WorldGenEngine layer only.
//   - SearchRunner still offloads to a background isolate via compute().
//   - Any EngineUnavailable/EngineUnsupportedVersion degrades to a Simulated
//     fallback carrying a non-null, non-empty SearchMeta.fallbackReason
//     (Property 9 / Property 10 at the dispatch layer).
//   Validates: Requirements 1.2, 1.6, 5.1-5.4, 11.3

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/search_runner.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/engine_selector.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';

/// Records every dispatch call so the test can assert the runner reaches the
/// engine exclusively through the [WorldGenEngine] interface.
class SpyEngine implements WorldGenEngine {
  SpyEngine(this._oreResult, this._structureResult);

  final EngineResult<OreLocation> _oreResult;
  final EngineResult<StructureLocation> _structureResult;

  int oreCalls = 0;
  int structureCalls = 0;
  OreQuery? lastOreQuery;
  StructureQuery? lastStructureQuery;

  @override
  Future<EngineResult<OreLocation>> findOres(OreQuery q) async {
    oreCalls++;
    lastOreQuery = q;
    return _oreResult;
  }

  @override
  Future<EngineResult<StructureLocation>> findStructures(
      StructureQuery q) async {
    structureCalls++;
    lastStructureQuery = q;
    return _structureResult;
  }
}

void main() {
  final version = MinecraftVersion.of(MinecraftEdition.java, '1.20');

  OreQuery oreQuery() => OreQuery(
        seed: '12345',
        centerX: 0,
        centerY: -59,
        centerZ: 0,
        radius: 48,
        oreType: OreType.diamond,
        includeNether: false,
        edition: MinecraftEdition.java,
        version: version,
        maxResults: 50,
      );

  StructureQuery structQuery() => StructureQuery(
        seed: '12345',
        centerX: 0,
        centerZ: 0,
        radius: 512,
        structureTypes: {StructureType.village},
        maxResults: 50,
        edition: MinecraftEdition.java,
        version: version,
      );

  group('dispatch routes through WorldGenEngine only', () {
    test('ore dispatch calls the injected engine exactly once', () async {
      final ore = OreLocation(
        x: 1,
        y: -59,
        z: 2,
        chunkX: 0,
        chunkZ: 0,
        probability: 1.0,
        oreType: OreType.diamond,
      );
      final spy = SpyEngine(
        EngineOk<OreLocation>([ore]),
        const EngineOk<StructureLocation>([]),
      );

      final out = await dispatchOreSearch(spy, oreQuery(), VersionEra.modern);

      expect(spy.oreCalls, 1, reason: 'dispatch must reach the engine once');
      expect(spy.structureCalls, 0);
      expect(spy.lastOreQuery, isNotNull);
      expect(out.results, hasLength(1));
      expect(out.meta, isNotNull);
    });

    test('structure dispatch calls the injected engine exactly once',
        () async {
      final structure = StructureLocation(
        x: 16,
        y: 72,
        z: 32,
        chunkX: 1,
        chunkZ: 2,
        probability: 1.0,
        structureType: StructureType.village,
      );
      final spy = SpyEngine(
        const EngineOk<OreLocation>([]),
        EngineOk<StructureLocation>([structure]),
      );

      final out = await dispatchStructureSearch(
          spy, structQuery(), VersionEra.modern);

      expect(spy.structureCalls, 1);
      expect(spy.oreCalls, 0);
      expect(out.results, hasLength(1));
    });
  });

  group('degradation attaches a non-null fallback reason', () {
    test('EngineUnavailable degrades and tags the reason (Req 5.3/5.4)',
        () async {
      final spy = SpyEngine(
        const EngineUnavailable<OreLocation>(FallbackReason.ffiLoadFailure),
        const EngineOk<StructureLocation>([]),
      );
      final out = await dispatchOreSearch(spy, oreQuery(), VersionEra.modern);

      expect(spy.oreCalls, 1);
      expect(out.meta, isNotNull);
      expect(out.meta!.fallbackReason, FallbackReason.ffiLoadFailure);
      expect(out.meta!.fallbackReason!.text, isNotEmpty);
      expect(out.meta!.didFallback, isTrue);
    });

    test('EngineUnsupportedVersion degrades with unsupportedVersion reason',
        () async {
      final spy = SpyEngine(
        const EngineOk<OreLocation>([]),
        EngineUnsupportedVersion<StructureLocation>(
            version, MinecraftEdition.java),
      );
      final out = await dispatchStructureSearch(
          spy, structQuery(), VersionEra.modern);

      expect(out.meta, isNotNull);
      expect(out.meta!.fallbackReason, FallbackReason.unsupportedVersion);
      expect(out.meta!.fallbackReason!.text, isNotEmpty);
    });

    test(
        'unregistered Bedrock version degrades with bedrockNoStrategy '
        '(Req 11.3)', () async {
      final bedrockVersion =
          MinecraftVersion.of(MinecraftEdition.bedrock, '9.99');
      final spy = SpyEngine(
        EngineUnsupportedVersion<OreLocation>(
            bedrockVersion, MinecraftEdition.bedrock),
        EngineUnsupportedVersion<StructureLocation>(
            bedrockVersion, MinecraftEdition.bedrock),
      );
      final oreOut = await dispatchOreSearch(
          spy,
          OreQuery(
            seed: '12345',
            centerX: 0,
            centerY: -59,
            centerZ: 0,
            radius: 48,
            oreType: OreType.diamond,
            includeNether: false,
            edition: MinecraftEdition.bedrock,
            version: bedrockVersion,
            maxResults: 50,
          ),
          VersionEra.modern);
      expect(oreOut.meta!.fallbackReason, FallbackReason.bedrockNoStrategy);
      expect(oreOut.meta!.mode, SearchMode.estimate);

      final structOut = await dispatchStructureSearch(
          spy,
          StructureQuery(
            seed: '12345',
            centerX: 0,
            centerZ: 0,
            radius: 512,
            structureTypes: {StructureType.village},
            maxResults: 50,
            edition: MinecraftEdition.bedrock,
            version: bedrockVersion,
          ),
          VersionEra.modern);
      expect(structOut.meta!.fallbackReason, FallbackReason.bedrockNoStrategy);
    });

    test('EngineOk from a non-accurate engine carries estimate meta, no reason',
        () async {
      final spy = SpyEngine(
        const EngineOk<OreLocation>([]),
        const EngineOk<StructureLocation>([]),
      );
      final out = await dispatchOreSearch(spy, oreQuery(), VersionEra.modern);
      expect(out.meta!.fallbackReason, isNull);
      expect(out.meta!.mode, SearchMode.estimate);
    });
  });

  group('SearchRunner still offloads via compute', () {
    tearDown(SearchRunner.resetComputeImpl);

    test('findOres dispatches through computeImpl (isolate offload preserved)',
        () async {
      var computeCalls = 0;
      SearchRunner.computeImpl = <M, R>(
        ComputeCallback<M, R> callback,
        M message, {
        String? debugLabel,
      }) {
        computeCalls++;
        // Delegate to the real compute so the search still runs off-isolate.
        return compute(callback, message, debugLabel: debugLabel);
      };

      final out = await SearchRunner.findOres(OreSearchParams(
        seed: 'kiro-seam-seed',
        centerX: 0,
        centerY: -59,
        centerZ: 0,
        radius: 32,
        oreType: OreType.diamond,
        includeNether: false,
        edition: MinecraftEdition.java,
        versionEra: VersionEra.modern,
        maxResults: 50,
      ));

      expect(computeCalls, 1, reason: 'search must be offloaded via compute');
      expect(out.meta, isNotNull);
      expect(out.meta!.mode, SearchMode.estimate,
          reason: 'default callers stay on the Estimate path');
    });

    test('findStructures dispatches through computeImpl', () async {
      var computeCalls = 0;
      SearchRunner.computeImpl = <M, R>(
        ComputeCallback<M, R> callback,
        M message, {
        String? debugLabel,
      }) {
        computeCalls++;
        return compute(callback, message, debugLabel: debugLabel);
      };

      await SearchRunner.findStructures(StructureSearchParams(
        seed: 'kiro-seam-seed',
        centerX: 0,
        centerZ: 0,
        radius: 512,
        structureTypes: {StructureType.village},
        maxResults: 50,
        edition: MinecraftEdition.java,
        versionEra: VersionEra.modern,
      ));

      expect(computeCalls, 1);
    });
  });
}
