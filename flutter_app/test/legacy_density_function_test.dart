// Unit tests for LegacyDensityFunction
// **Validates: Requirements 4.1, 4.4, 4.5**
//
// Tests each ore type returns non-zero density within its Y range,
// returns 0.0 outside its Y range, and verifies boundary values.

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/legacy_density_function.dart';

void main() {
  // Use a fixed seed for deterministic tests
  const int testSeed = 12345;

  group('LegacyDensityFunction - oreYRanges static map', () {
    test('contains all expected ore types', () {
      expect(LegacyDensityFunction.oreYRanges.keys.toSet(), equals({
        'diamond', 'gold', 'iron', 'coal', 'redstone', 'lapis',
      }));
    });

    test('ranges match legacy specification', () {
      expect(LegacyDensityFunction.oreYRanges['diamond'], equals([1, 15]));
      expect(LegacyDensityFunction.oreYRanges['gold'], equals([1, 31]));
      expect(LegacyDensityFunction.oreYRanges['iron'], equals([1, 63]));
      expect(LegacyDensityFunction.oreYRanges['coal'], equals([1, 127]));
      expect(LegacyDensityFunction.oreYRanges['redstone'], equals([1, 15]));
      expect(LegacyDensityFunction.oreYRanges['lapis'], equals([14, 30]));
    });
  });

  group('LegacyDensityFunction - non-zero density within Y range', () {
    late LegacyDensityFunction density;

    setUp(() {
      density = LegacyDensityFunction(testSeed);
    });

    // For each ore type, sample several (x, z) coordinates at the midpoint
    // of the Y range. At least some should produce non-zero density.
    for (final entry in LegacyDensityFunction.oreYRanges.entries) {
      final oreType = entry.key;
      final minY = entry.value[0];
      final maxY = entry.value[1];
      final midY = ((minY + maxY) / 2).toDouble();

      test('$oreType returns non-zero density for at least some coordinates '
          'within Y range ($minY–$maxY)', () {
        bool foundNonZero = false;
        // Sample a grid of x,z values
        for (double x = 0; x < 500; x += 50) {
          for (double z = 0; z < 500; z += 50) {
            final result = density.getOreDensity(x, midY, z, oreType);
            expect(result, greaterThanOrEqualTo(0.0),
                reason: '$oreType at ($x, $midY, $z) should be >= 0.0');
            if (result > 0.0) foundNonZero = true;
          }
        }
        expect(foundNonZero, isTrue,
            reason: '$oreType should produce non-zero density for at least '
                'some coordinates within its Y range');
      });
    }
  });

  group('LegacyDensityFunction - zero density outside Y range', () {
    late LegacyDensityFunction density;

    setUp(() {
      density = LegacyDensityFunction(testSeed);
    });

    for (final entry in LegacyDensityFunction.oreYRanges.entries) {
      final oreType = entry.key;
      final minY = entry.value[0];
      final maxY = entry.value[1];

      test('$oreType returns 0.0 below Y range (Y=${minY - 1})', () {
        final result = density.getOreDensity(
            100.0, (minY - 1).toDouble(), 100.0, oreType);
        expect(result, equals(0.0));
      });

      test('$oreType returns 0.0 above Y range (Y=${maxY + 1})', () {
        final result = density.getOreDensity(
            100.0, (maxY + 1).toDouble(), 100.0, oreType);
        expect(result, equals(0.0));
      });

      test('$oreType returns 0.0 far below Y range (Y=-100)', () {
        final result = density.getOreDensity(100.0, -100.0, 100.0, oreType);
        expect(result, equals(0.0));
      });

      test('$oreType returns 0.0 far above Y range (Y=300)', () {
        final result = density.getOreDensity(100.0, 300.0, 100.0, oreType);
        expect(result, equals(0.0));
      });
    }
  });

  group('LegacyDensityFunction - boundary values (diamond)', () {
    late LegacyDensityFunction density;

    setUp(() {
      density = LegacyDensityFunction(testSeed);
    });

    test('diamond at Y=1 (lower bound) returns >= 0.0', () {
      final result = density.getOreDensity(100.0, 1.0, 100.0, 'diamond');
      expect(result, greaterThanOrEqualTo(0.0));
    });

    test('diamond at Y=15 (upper bound) returns >= 0.0', () {
      final result = density.getOreDensity(100.0, 15.0, 100.0, 'diamond');
      expect(result, greaterThanOrEqualTo(0.0));
    });

    test('diamond at Y=0 (just below range) returns 0.0', () {
      final result = density.getOreDensity(100.0, 0.0, 100.0, 'diamond');
      expect(result, equals(0.0));
    });

    test('diamond at Y=16 (just above range) returns 0.0', () {
      final result = density.getOreDensity(100.0, 16.0, 100.0, 'diamond');
      expect(result, equals(0.0));
    });
  });

  group('LegacyDensityFunction - boundary values (lapis)', () {
    late LegacyDensityFunction density;

    setUp(() {
      density = LegacyDensityFunction(testSeed);
    });

    test('lapis at Y=14 (lower bound) returns >= 0.0', () {
      final result = density.getOreDensity(100.0, 14.0, 100.0, 'lapis');
      expect(result, greaterThanOrEqualTo(0.0));
    });

    test('lapis at Y=30 (upper bound) returns >= 0.0', () {
      final result = density.getOreDensity(100.0, 30.0, 100.0, 'lapis');
      expect(result, greaterThanOrEqualTo(0.0));
    });

    test('lapis at Y=13 (just below range) returns 0.0', () {
      final result = density.getOreDensity(100.0, 13.0, 100.0, 'lapis');
      expect(result, equals(0.0));
    });

    test('lapis at Y=31 (just above range) returns 0.0', () {
      final result = density.getOreDensity(100.0, 31.0, 100.0, 'lapis');
      expect(result, equals(0.0));
    });
  });

  group('LegacyDensityFunction - unrecognized ore type', () {
    test('returns 0.0 for unknown ore type', () {
      final density = LegacyDensityFunction(testSeed);
      expect(density.getOreDensity(100.0, 10.0, 100.0, 'emerald'), equals(0.0));
      expect(density.getOreDensity(100.0, 10.0, 100.0, ''), equals(0.0));
      expect(density.getOreDensity(100.0, 10.0, 100.0, 'netherite'), equals(0.0));
    });
  });

  group('LegacyDensityFunction - determinism', () {
    test('same seed produces identical results', () {
      final d1 = LegacyDensityFunction(testSeed);
      final d2 = LegacyDensityFunction(testSeed);

      for (final oreType in LegacyDensityFunction.oreYRanges.keys) {
        final result1 = d1.getOreDensity(50.0, 10.0, 50.0, oreType);
        final result2 = d2.getOreDensity(50.0, 10.0, 50.0, oreType);
        expect(result1, equals(result2),
            reason: '$oreType should be deterministic for same seed');
      }
    });

    test('different seeds can produce different results', () {
      final d1 = LegacyDensityFunction(1);
      final d2 = LegacyDensityFunction(999);

      bool anyDifferent = false;
      for (final oreType in LegacyDensityFunction.oreYRanges.keys) {
        final result1 = d1.getOreDensity(50.0, 10.0, 50.0, oreType);
        final result2 = d2.getOreDensity(50.0, 10.0, 50.0, oreType);
        if (result1 != result2) {
          anyDifferent = true;
          break;
        }
      }
      expect(anyDifferent, isTrue,
          reason: 'Different seeds should produce different density values');
    });
  });
}
