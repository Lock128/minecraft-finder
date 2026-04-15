// Unit tests for BedrockRandom (MT19937 Mersenne Twister)
// **Validates: Requirements 3.1, 3.4**
//
// Verifies known MT19937 output values for specific seeds against
// C++ reference values, and tests ArgumentError on invalid bounds.

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/bedrock_random.dart';

void main() {
  group('BedrockRandom - MT19937 reference values', () {
    test('seed 1: nextLong() matches combined first two MT19937 outputs', () {
      // MT19937 reference (C implementation, seed=1):
      //   first  _nextUint32() = 1791095845
      //   second _nextUint32() = 4282876139
      // nextLong() = (high << 32) | low
      final rng = BedrockRandom(1);
      final expected = (1791095845 << 32) | 4282876139;
      expect(rng.nextLong(), equals(expected));
    });

    test('seed 5489: nextLong() matches combined first two MT19937 outputs',
        () {
      // MT19937 reference (C implementation, seed=5489 — the default MT seed):
      //   first  _nextUint32() = 3499211612
      //   second _nextUint32() = 581869302
      final rng = BedrockRandom(5489);
      final expected = (3499211612 << 32) | 581869302;
      expect(rng.nextLong(), equals(expected));
    });

    test('seed 1: sequential nextInt(bound) values are deterministic', () {
      // Verify determinism: two instances with the same seed produce
      // identical sequences.
      final rng1 = BedrockRandom(1);
      final rng2 = BedrockRandom(1);

      for (int i = 0; i < 20; i++) {
        expect(rng1.nextInt(1000), equals(rng2.nextInt(1000)),
            reason: 'Mismatch at iteration $i');
      }
    });

    test('seed 1: nextInt verifiable against known first uint32 output', () {
      // First _nextUint32() for seed 1 = 1791095845
      // nextInt(bound) uses rejection sampling over 32-bit range.
      // For bound = 1791095846 (one more than the first output),
      // the first output 1791095845 is within [0, bound), so
      // nextInt should return 1791095845.
      final rng = BedrockRandom(1);
      // Use a bound larger than the known output so it passes rejection
      // sampling on the first draw.
      final result = rng.nextInt(1 << 30); // bound = 1073741824
      // 1791095845 % 1073741824 = 717354021
      // But we need to account for rejection sampling:
      // limit = (0x100000000 ~/ 1073741824) * 1073741824 = 4 * 1073741824 = 4294967296
      // 1791095845 < 4294967296, so no rejection. Result = 1791095845 % 1073741824
      expect(result, equals(1791095845 % (1 << 30)));
    });

    test('setSeed resets state to produce same sequence', () {
      final rng = BedrockRandom(1);
      final firstValue = rng.nextLong();

      rng.setSeed(1);
      final secondValue = rng.nextLong();

      expect(firstValue, equals(secondValue));
    });

    test('different seeds produce different sequences', () {
      final rng1 = BedrockRandom(1);
      final rng2 = BedrockRandom(2);

      // At least one of the first few values should differ
      bool anyDifferent = false;
      for (int i = 0; i < 5; i++) {
        if (rng1.nextLong() != rng2.nextLong()) {
          anyDifferent = true;
          break;
        }
      }
      expect(anyDifferent, isTrue);
    });
  });

  group('BedrockRandom - ArgumentError on invalid bounds', () {
    test('nextInt(0) throws ArgumentError', () {
      final rng = BedrockRandom(42);
      expect(() => rng.nextInt(0), throwsArgumentError);
    });

    test('nextInt(-1) throws ArgumentError', () {
      final rng = BedrockRandom(42);
      expect(() => rng.nextInt(-1), throwsArgumentError);
    });

    test('nextInt(-100) throws ArgumentError', () {
      final rng = BedrockRandom(42);
      expect(() => rng.nextInt(-100), throwsArgumentError);
    });

    test('nextInt(1) does not throw and returns 0', () {
      final rng = BedrockRandom(42);
      // With bound=1, the only possible result is 0
      expect(rng.nextInt(1), equals(0));
    });
  });

  group('BedrockRandom - nextDouble and nextFloat range', () {
    test('nextDouble returns value in [0.0, 1.0)', () {
      final rng = BedrockRandom(1);
      for (int i = 0; i < 100; i++) {
        final val = rng.nextDouble();
        expect(val, greaterThanOrEqualTo(0.0));
        expect(val, lessThan(1.0));
      }
    });

    test('nextFloat returns value in [0.0, 1.0)', () {
      final rng = BedrockRandom(1);
      for (int i = 0; i < 100; i++) {
        final val = rng.nextFloat();
        expect(val, greaterThanOrEqualTo(0.0));
        expect(val, lessThan(1.0));
      }
    });
  });

  group('BedrockRandom - nextBool', () {
    test('nextBool returns both true and false over many calls', () {
      final rng = BedrockRandom(1);
      bool seenTrue = false;
      bool seenFalse = false;
      for (int i = 0; i < 100; i++) {
        final val = rng.nextBool();
        if (val) seenTrue = true;
        if (!val) seenFalse = true;
        if (seenTrue && seenFalse) break;
      }
      expect(seenTrue, isTrue);
      expect(seenFalse, isTrue);
    });
  });
}
