// FFI load-failure unit test (spec task 7.5).
//
// Feature: seed-accurate-worldgen
//   Inject a native-library loader that throws; assert the NativeFfiBackend
//   surfaces the failure so AccurateEngine returns
//   EngineUnavailable(FallbackReason.ffiLoadFailure), and that the runner-level
//   dispatch falls back to the Simulated finder with that reason attached.
//   Validates: Requirements 2.5, 5.3

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/search_runner.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/accurate_engine.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/engine_selector.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/native_ffi_backend.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/native_library_loader.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/version_strategy_registry.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_backend.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';

import 'fakes.dart';

/// A loader that reports it should be available but throws on load, simulating
/// a device that should support native but fails at `DynamicLibrary.open` /
/// symbol lookup.
class ThrowingLoader implements NativeLibraryLoader {
  const ThrowingLoader(this.error);
  final Object error;

  @override
  bool get isAvailable => true;

  @override
  NativeWorldGen load() => throw error;
}

void main() {
  final version = const MinecraftVersion('java-1.20');

  VersionStrategyRegistry registryWith() {
    final r = VersionStrategyRegistry();
    r.register(FakeVersionStrategy(version), verified: true);
    return r;
  }

  OreQuery oreQuery() => OreQuery(
        seed: '777',
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

  StructureQuery structQuery() => StructureQuery(
        seed: '777',
        centerX: 0,
        centerZ: 0,
        radius: 512,
        structureTypes: {StructureType.village},
        maxResults: 10,
        edition: MinecraftEdition.java,
        version: version,
      );

  group('NativeFfiBackend converts load failures to FfiUnavailable', () {
    test('computeOres throws FfiUnavailable when the loader throws', () async {
      final backend =
          NativeFfiBackend.withLoader(const ThrowingLoader('open failed'));
      final strategy = FakeVersionStrategy(version);
      expect(
        () => backend.computeOres(oreQuery(), strategy),
        throwsA(isA<FfiUnavailable>()),
      );
    });

    test('ArgumentError (bad library path) is wrapped too', () async {
      final backend = NativeFfiBackend.withLoader(
          ThrowingLoader(ArgumentError('no such library')));
      final strategy = FakeVersionStrategy(version);
      expect(
        () => backend.computeStructures(structQuery(), strategy),
        throwsA(isA<FfiUnavailable>()),
      );
    });

    test('canRun flips to false after a failed load', () async {
      final backend =
          NativeFfiBackend.withLoader(const ThrowingLoader('boom'));
      final strategy = FakeVersionStrategy(version);
      // First call triggers the (failed) load.
      await expectLater(
        backend.computeOres(oreQuery(), strategy),
        throwsA(isA<FfiUnavailable>()),
      );
      expect(backend.canRun(strategy), isFalse,
          reason: 'a failed load must disable the backend');
    });
  });

  group('AccurateEngine surfaces EngineUnavailable(ffiLoadFailure)', () {
    test('findOres returns EngineUnavailable(ffiLoadFailure)', () async {
      final backend =
          NativeFfiBackend.withLoader(const ThrowingLoader('dlopen failed'));
      final engine = AccurateEngine(
        registry: registryWith(),
        platform: Platform.linux,
        selectBackend: (_) => backend,
      );
      final r = await engine.findOres(oreQuery());
      expect(r, isA<EngineUnavailable<OreLocation>>());
      expect((r as EngineUnavailable<OreLocation>).reason,
          FallbackReason.ffiLoadFailure);
    });

    test('findStructures returns EngineUnavailable(ffiLoadFailure)', () async {
      final backend =
          NativeFfiBackend.withLoader(const ThrowingLoader('missing symbol'));
      final engine = AccurateEngine(
        registry: registryWith(),
        platform: Platform.linux,
        selectBackend: (_) => backend,
      );
      final r = await engine.findStructures(structQuery());
      expect(r, isA<EngineUnavailable<StructureLocation>>());
      expect((r as EngineUnavailable<StructureLocation>).reason,
          FallbackReason.ffiLoadFailure);
    });
  });

  group('runner falls back to Simulated with the ffi reason', () {
    test('dispatchOreSearch degrades and tags ffiLoadFailure', () async {
      final backend =
          NativeFfiBackend.withLoader(const ThrowingLoader('dlopen failed'));
      final engine = AccurateEngine(
        registry: registryWith(),
        platform: Platform.linux,
        selectBackend: (_) => backend,
      );

      final out =
          await dispatchOreSearch(engine, oreQuery(), VersionEra.modern);

      // Simulated fallback produced output (diamonds near spawn) and the meta
      // carries the FFI load-failure reason.
      expect(out.meta, isNotNull);
      expect(out.meta!.fallbackReason, FallbackReason.ffiLoadFailure);
      expect(out.meta!.fallbackReason!.text, isNotEmpty);
      expect(out.meta!.mode, SearchMode.estimate);
    });
  });
}
