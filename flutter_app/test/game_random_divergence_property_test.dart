// Feature: edition-version-selection, Property 2: BedrockRandom and JavaRandom produce divergent sequences
// **Validates: Requirements 3.4**
//
// For any seed value, the sequence of random numbers produced by
// BedrockRandom(seed) and JavaRandom(seed) SHALL differ. Specifically,
// calling nextLong() three times on each should produce at least one
// differing value.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/java_random.dart';
import 'package:gem_ore_struct_finder_mc/models/bedrock_random.dart';

void main() {
  group('Property 2: BedrockRandom and JavaRandom produce divergent sequences',
      () {
    final inputRng = Random(42); // fixed seed for reproducibility

    /// Helper: generate a random seed (full 32-bit signed range).
    int randomSeed() {
      return inputRng.nextInt(1 << 32) - (1 << 31);
    }

    test(
        'For any seed, nextLong() called 3 times produces at least one '
        'differing value between JavaRandom and BedrockRandom '
        '(100 random seeds)', () {
      for (int i = 0; i < 100; i++) {
        final seed = randomSeed();
        final java = JavaRandom(seed);
        final bedrock = BedrockRandom(seed);

        final javaValues = [
          java.nextLong(),
          java.nextLong(),
          java.nextLong(),
        ];
        final bedrockValues = [
          bedrock.nextLong(),
          bedrock.nextLong(),
          bedrock.nextLong(),
        ];

        final allSame = javaValues[0] == bedrockValues[0] &&
            javaValues[1] == bedrockValues[1] &&
            javaValues[2] == bedrockValues[2];

        expect(allSame, isFalse,
            reason: 'Iteration $i: seed=$seed — JavaRandom and BedrockRandom '
                'produced identical sequences: $javaValues');
      }
    });

    test(
        'Divergence holds for edge-case seeds '
        '(0, 1, -1, max 32-bit, min 32-bit)', () {
      final edgeCaseSeeds = [0, 1, -1, 2147483647, -2147483648];

      for (final seed in edgeCaseSeeds) {
        final java = JavaRandom(seed);
        final bedrock = BedrockRandom(seed);

        final javaValues = [
          java.nextLong(),
          java.nextLong(),
          java.nextLong(),
        ];
        final bedrockValues = [
          bedrock.nextLong(),
          bedrock.nextLong(),
          bedrock.nextLong(),
        ];

        final allSame = javaValues[0] == bedrockValues[0] &&
            javaValues[1] == bedrockValues[1] &&
            javaValues[2] == bedrockValues[2];

        expect(allSame, isFalse,
            reason: 'Edge-case seed=$seed — JavaRandom and BedrockRandom '
                'produced identical sequences: $javaValues');
      }
    });

    test(
        'Divergence holds across 100 additional large-magnitude seeds', () {
      for (int i = 0; i < 100; i++) {
        // Generate seeds with large magnitude to cover wider range
        final seed = (inputRng.nextInt(1 << 32) - (1 << 31)) *
            (inputRng.nextBool() ? 1 : -1);
        final java = JavaRandom(seed);
        final bedrock = BedrockRandom(seed);

        final javaValues = [
          java.nextLong(),
          java.nextLong(),
          java.nextLong(),
        ];
        final bedrockValues = [
          bedrock.nextLong(),
          bedrock.nextLong(),
          bedrock.nextLong(),
        ];

        final allSame = javaValues[0] == bedrockValues[0] &&
            javaValues[1] == bedrockValues[1] &&
            javaValues[2] == bedrockValues[2];

        expect(allSame, isFalse,
            reason: 'Iteration $i: seed=$seed — JavaRandom and BedrockRandom '
                'produced identical sequences: $javaValues');
      }
    });
  });
}
