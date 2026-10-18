// Req 9.3 unit coverage: the AccurateEngine surfaces real vein-size metadata on
// EngineOk.meta (and every emitted vein carries its own size) when run through
// the real DartWebBackend for a Java 1.18-1.20 ore query.

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/accurate_engine.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/java_version_strategy.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/version_strategy_registry.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_backend.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';

void main() {
  test('EngineOk.meta carries a vein size >= 1 and every vein reports its size',
      () async {
    final version = const MinecraftVersion('java-1.20');
    final registry = VersionStrategyRegistry()
      ..register(JavaVersionStrategy.java120(), verified: true);
    final engine = AccurateEngine(
      registry: registry,
      platform: Platform.web,
      selectBackend: (_) => const DartWebBackend(),
    );

    final result = await engine.findOres(OreQuery(
      seed: '123456789',
      centerX: 0,
      centerY: 0,
      centerZ: 0,
      radius: 128,
      oreType: OreType.diamond,
      includeNether: false,
      edition: MinecraftEdition.java,
      version: version,
      maxResults: 64,
    ));

    expect(result, isA<EngineOk<OreLocation>>());
    final ok = result as EngineOk<OreLocation>;
    expect(ok.results, isNotEmpty);
    expect(ok.meta.veinSize, isNotNull);
    expect(ok.meta.veinSize, greaterThanOrEqualTo(1));
    for (final o in ok.results) {
      expect(o.estimatedVeinSize, greaterThanOrEqualTo(1));
    }
  });
}
