// Feature: edition-version-selection, Property 1: GameRandom output range invariants
// **Validates: Requirements 3.1**
//
// For any GameRandom implementation (JavaRandom or BedrockRandom), any valid
// seed, and any positive bound:
// - nextInt(bound) returns a value in [0, bound)
// - nextDouble() returns a value in [0.0, 1.0)
// - nextFloat() returns a value in [0.0, 1.0)
// - nextLong() does not throw

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/java_random.dart';
import 'package:gem_ore_struct_finder_mc/models/bedrock_random.dart';

void main() {
  group('Property 1: GameRandom output range invariants', () {
    final inputRng = Random(42); // fixed seed for reproducibility

    /// Helper: generate a random seed (full 64-bit range).
    int randomSeed() {
      return inputRng.nextInt(1 << 32) - (1 << 31);
    }

    /// Helper: generate a random positive bound in [1, 100000].
    int randomBound() {
      return inputRng.nextInt(100000) + 1;
    }

    test('JavaRandom: nextInt(bound) ∈ [0, bound) for 100 random inputs', () {
      for (int i = 0; i < 100; i++) {
        final seed = randomSeed();
        final bound = randomBound();
        final rng = JavaRandom(seed);

        for (int j = 0; j < 10; j++) {
          final value = rng.nextInt(bound);
          expect(value, greaterThanOrEqualTo(0),
              reason: 'Iteration $i.$j: seed=$seed bound=$bound got $value');
          expect(value, lessThan(bound),
              reason: 'Iteration $i.$j: seed=$seed bound=$bound got $value');
        }
      }
    });

    test('BedrockRandom: nextInt(bound) ∈ [0, bound) for 100 random inputs',
        () {
      for (int i = 0; i < 100; i++) {
        final seed = randomSeed();
        final bound = randomBound();
        final rng = BedrockRandom(seed);

        for (int j = 0; j < 10; j++) {
          final value = rng.nextInt(bound);
          expect(value, greaterThanOrEqualTo(0),
              reason: 'Iteration $i.$j: seed=$seed bound=$bound got $value');
          expect(value, lessThan(bound),
              reason: 'Iteration $i.$j: seed=$seed bound=$bound got $value');
        }
      }
    });

    test('JavaRandom: nextDouble() ∈ [0.0, 1.0) for 100 random seeds', () {
      for (int i = 0; i < 100; i++) {
        final seed = randomSeed();
        final rng = JavaRandom(seed);

        for (int j = 0; j < 10; j++) {
          final value = rng.nextDouble();
          expect(value, greaterThanOrEqualTo(0.0),
              reason: 'Iteration $i.$j: seed=$seed got $value');
          expect(value, lessThan(1.0),
              reason: 'Iteration $i.$j: seed=$seed got $value');
        }
      }
    });

    test('BedrockRandom: nextDouble() ∈ [0.0, 1.0) for 100 random seeds', () {
      for (int i = 0; i < 100; i++) {
        final seed = randomSeed();
        final rng = BedrockRandom(seed);

        for (int j = 0; j < 10; j++) {
          final value = rng.nextDouble();
          expect(value, greaterThanOrEqualTo(0.0),
              reason: 'Iteration $i.$j: seed=$seed got $value');
          expect(value, lessThan(1.0),
              reason: 'Iteration $i.$j: seed=$seed got $value');
        }
      }
    });

    test('JavaRandom: nextFloat() ∈ [0.0, 1.0) for 100 random seeds', () {
      for (int i = 0; i < 100; i++) {
        final seed = randomSeed();
        final rng = JavaRandom(seed);

        for (int j = 0; j < 10; j++) {
          final value = rng.nextFloat();
          expect(value, greaterThanOrEqualTo(0.0),
              reason: 'Iteration $i.$j: seed=$seed got $value');
          expect(value, lessThan(1.0),
              reason: 'Iteration $i.$j: seed=$seed got $value');
        }
      }
    });

    test('BedrockRandom: nextFloat() ∈ [0.0, 1.0) for 100 random seeds', () {
      for (int i = 0; i < 100; i++) {
        final seed = randomSeed();
        final rng = BedrockRandom(seed);

        for (int j = 0; j < 10; j++) {
          final value = rng.nextFloat();
          expect(value, greaterThanOrEqualTo(0.0),
              reason: 'Iteration $i.$j: seed=$seed got $value');
          expect(value, lessThan(1.0),
              reason: 'Iteration $i.$j: seed=$seed got $value');
        }
      }
    });

    test('JavaRandom: nextLong() does not throw for 100 random seeds', () {
      for (int i = 0; i < 100; i++) {
        final seed = randomSeed();
        final rng = JavaRandom(seed);

        expect(() => rng.nextLong(), returnsNormally,
            reason: 'Iteration $i: seed=$seed');
      }
    });

    test('BedrockRandom: nextLong() does not throw for 100 random seeds', () {
      for (int i = 0; i < 100; i++) {
        final seed = randomSeed();
        final rng = BedrockRandom(seed);

        expect(() => rng.nextLong(), returnsNormally,
            reason: 'Iteration $i: seed=$seed');
      }
    });

    test(
        'GameRandom.forEdition: both implementations satisfy range invariants '
        'for 100 random inputs', () {
      for (int i = 0; i < 100; i++) {
        final seed = randomSeed();
        final bound = randomBound();

        for (final edition in MinecraftEdition.values) {
          final rng = GameRandom.forEdition(edition, seed);

          final intVal = rng.nextInt(bound);
          expect(intVal, greaterThanOrEqualTo(0),
              reason: 'Iteration $i: $edition seed=$seed bound=$bound');
          expect(intVal, lessThan(bound),
              reason: 'Iteration $i: $edition seed=$seed bound=$bound');

          final doubleVal = rng.nextDouble();
          expect(doubleVal, greaterThanOrEqualTo(0.0),
              reason: 'Iteration $i: $edition seed=$seed nextDouble=$doubleVal');
          expect(doubleVal, lessThan(1.0),
              reason: 'Iteration $i: $edition seed=$seed nextDouble=$doubleVal');

          final floatVal = rng.nextFloat();
          expect(floatVal, greaterThanOrEqualTo(0.0),
              reason: 'Iteration $i: $edition seed=$seed nextFloat=$floatVal');
          expect(floatVal, lessThan(1.0),
              reason: 'Iteration $i: $edition seed=$seed nextFloat=$floatVal');

          expect(() => rng.nextLong(), returnsNormally,
              reason: 'Iteration $i: $edition seed=$seed nextLong threw');
        }
      }
    });
  });
}
