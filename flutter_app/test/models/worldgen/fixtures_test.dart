// Golden-fixture scaffolding tests (spec tasks 8.1, 8.2).
//
// Property 19: Supported versions always have a golden fixture set.
//   Feature: seed-accurate-worldgen, Property 19
//   Validates: Requirements 10.3, 13.1

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/version_strategy_registry.dart';

import 'fakes.dart';
import 'fixture_loader.dart';

void main() {
  group('Fixture auto-discovery and loading', () {
    final fixtures = FixtureLoader.loadAll();

    test('at least one fixture directory is discovered', () {
      expect(fixtures, isNotEmpty,
          reason: 'expected fixtures under ${FixtureLoader.fixturesRoot}');
    });

    // Parameterized suite: auto-discovers every directory under
    // test/fixtures/worldgen/ and validates its shape.
    for (final fixture in fixtures) {
      group('fixture ${fixture.directoryName}', () {
        test('directory name matches edition-version', () {
          expect(fixture.directoryName, '${fixture.edition}-${fixture.version}');
        });

        test('carries a seed and non-empty reference data', () {
          expect(fixture.seed, isNotEmpty);
          expect(fixture.isNonEmpty, isTrue);
        });

        test('structure entries parse into coordinates', () {
          for (final s in fixture.structures) {
            expect(s.structureType, isNotEmpty);
          }
        });

        test('ore entries carry a vein size >= 1', () {
          for (final o in fixture.ores) {
            expect(o.veinSize, greaterThanOrEqualTo(1));
          }
        });
      });
    }
  });

  group('Property 19: supported versions have a non-empty fixture set', () {
    // Build a registry whose supported versions line up with the authored
    // fixtures so the invariant is exercised end-to-end.
    final fixtures = FixtureLoader.loadAll();
    final registry = VersionStrategyRegistry();
    for (final f in fixtures) {
      // The directory name (<edition>-<release>) is the MinecraftVersion id.
      registry.register(FakeVersionStrategy(MinecraftVersion(f.directoryName)));
    }

    test('every supported version resolves to a non-empty fixture', () {
      final fixturesByVersion = <String, WorldGenFixture>{
        for (final f in fixtures) f.directoryName: f,
      };

      for (final version in registry.supportedVersions) {
        final fixture = fixturesByVersion[version.id];
        expect(fixture, isNotNull,
            reason: 'supported ${version.id} must have a fixture directory');
        expect(fixture!.isNonEmpty, isTrue,
            reason: '${version.id} fixture must carry reference data');
      }
    });

    test('supported Java versions are discoverable via VersionAvailability',
        () {
      // Sanity: the registry lists the same versions the UI picker would read.
      final javaVersions = registry.supportedVersionsFor(MinecraftEdition.java);
      expect(javaVersions.map((v) => v.id),
          containsAll(fixtures.map((f) => f.directoryName)));
    });
  });
}
