// Property 4: Web RNG reproduces java.util.Random (spec task 4.2).
//
// Feature: seed-accurate-worldgen, Property 4: the Int64-backed web RNG stream
// (nextInt/nextLong/nextFloat/nextDouble) equals the reference java.util.Random
// stream with no divergence above 2^53.
// Validates: Requirements 3.5, 13.5
//
// This file MUST run on the web/JS target as well as the VM:
//   flutter test --platform chrome test/models/worldgen/rng_conformance_test.dart
//
// The reference sequences below were generated from java.util.Random (via the
// native-correct JavaRandom on the 64-bit Dart VM) and embedded here so the
// test is self-contained and can run in the browser (no dart:io file reads).
//
// Seeds are supplied as hex strings and parsed into Int64, because Dart int
// literals above 2^53 lose precision on the web; building the Int64 seed from
// hex avoids that trap in the test harness itself.

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/java_random_int64.dart';

class RngReference {
  const RngReference({
    required this.seedHex,
    required this.nextInt1000,
    required this.nextInt1024,
    required this.nextLongHex,
    required this.nextFloat,
    required this.nextDouble,
  });

  final String seedHex;
  final List<int> nextInt1000;
  final List<int> nextInt1024;
  final List<String> nextLongHex;
  final List<double> nextFloat;
  final List<double> nextDouble;
}

/// Parse a signed hex string ("-1a2b" / "1a2b") into an [Int64].
Int64 _hex(String s) {
  if (s.startsWith('-')) {
    return -Int64.parseHex(s.substring(1));
  }
  return Int64.parseHex(s);
}

// 2^53. Reduced nextInt/nextFloat/nextDouble outputs must stay strictly below
// this bound to be representable exactly as a JS double.
final Int64 _twoTo53 = Int64.ONE << 53;

const List<RngReference> kRngReferences = [
  RngReference(
    seedHex: '0',
    nextInt1000: [360, 948, 29, 447, 515, 53, 491, 761, 719, 854],
    nextInt1024: [748, 851, 246, 620, 652, 316, 563, 119, 611, 800],
    nextLongHex: ['-44df4b9f2b26aec8', '3d93cb7a9b3970be', '-5cd23609b0e20fc6', '-73168f48e20bdafd', '-670745c137ed5893', '554dcd2b40b5f04b'],
    nextFloat: [0.7309677600860596, 0.8314409852027893, 0.2405363917350769, 0.6063451766967773, 0.6374173760414124, 0.3090505599975586],
    nextDouble: [0.730967787376657, 0.24053641567148587, 0.6374174253501083, 0.5504370051176339, 0.5975452777972018, 0.3332183994766498],
  ),
  RngReference(
    seedHex: '1',
    nextInt1000: [985, 588, 847, 313, 254, 904, 434, 606, 978, 748],
    nextInt1024: [748, 102, 419, 417, 212, 37, 340, 674, 990, 727],
    nextLongHex: ['-44e52a8ce6476328', '68fb0e6f684df992', '352cccfc0946b8f0', '552cf1e5a8ab85dd', '-841262a4a0cf798', '190e5722719b812'],
    nextFloat: [0.7308781743049622, 0.10047316551208496, 0.41008079051971436, 0.4074397683143616, 0.20771479606628418, 0.03623533248901367],
    nextDouble: [0.7308781907032909, 0.41008081149220166, 0.20771484130971707, 0.3327170559595112, 0.9677559094241207, 0.006117182265761301],
  ),
  RngReference(
    seedHex: '-1',
    nextInt1000: [913, 225, 579, 439, 604, 438, 477, 478, 765, 731],
    nextInt1024: [275, 450, 12, 561, 677, 615, 426, 408, 845, 57],
    nextLongHex: ['44d96cb3708722c3', '32420178c4bff9e', '-5681a196663244b4', '6a9bb39a6637c50c', '-2c806435f186c70a', '-31a78affb0b314bf'],
    nextFloat: [0.26894259452819824, 0.43956196308135986, 0.012269973754882812, 0.5480346083641052, 0.6620844602584839, 0.6007954478263855],
    nextDouble: [0.26894263088050496, 0.012269981921235296, 0.6620844841121951, 0.4164383172882866, 0.8261659004768312, 0.8060372517968333],
  ),
  RngReference(
    seedHex: '2a',
    nextInt1000: [130, 763, 248, 884, 970, 525, 505, 918, 519, 93],
    nextInt1024: [745, 55, 699, 49, 316, 964, 283, 724, 681, 93],
    nextLongHex: ['-45be62caf2017509', '-5118441ef3ba3fd8', '4f083ce4f12bbb4b', '46ee9d83b52c856d', '-559e9541e89ef366', '-18bc98428c7a6824'],
    nextFloat: [0.7275636792182922, 0.054665207862854004, 0.6832234263420105, 0.047939300537109375, 0.3087193965911865, 0.9420735239982605],
    nextDouble: [0.7275636800328681, 0.6832234717598454, 0.30871945533265976, 0.27707849007413665, 0.6655489517945736, 0.9033722646721782],
  ),
  RngReference(
    seedHex: '75bcd15',
    nextInt1000: [965, 600, 483, 344, 290, 554, 533, 807, 297, 887],
    nextInt1024: [679, 781, 467, 260, 399, 221, 914, 435, 767, 441],
    nextLongHex: ['-560199543c974aff', '74facac7413f22b0', '63f83ba43772df24', '-1b4dfe6593131671', '-40177b3c91a9c1d1', '5c0710a27d86cb83'],
    nextFloat: [0.6640380620956421, 0.7633164525032043, 0.45695173740386963, 0.25486958026885986, 0.39050644636154175, 0.2165965437889099],
    nextDouble: [0.664038103272266, 0.45695178590520646, 0.39050647939140426, 0.8933411602003871, 0.749641708001546, 0.3594828023066827],
  ),
  RngReference(
    seedHex: '-3ade68b1',
    nextInt1000: [362, 534, 416, 630, 710, 541, 22, 370, 878, 296],
    nextInt1024: [710, 631, 618, 777, 843, 480, 44, 819, 803, 415],
    nextLongHex: ['-4e5dce8a623da964', '-657c337e3dbe36c4', '-2d06367387c4ee46', 'b193f8cccc1eb44', '-373e1d03980016ef', '22f4b41952adf791'],
    nextFloat: [0.693881094455719, 0.6162465810775757, 0.6035735607147217, 0.7588163018226624, 0.8241239190101624, 0.4696512818336487],
    nextDouble: [0.6938811185396703, 0.6035736018242882, 0.8241239558108348, 0.04335401653996063, 0.7842084676958416, 0.13654637817989324],
  ),
  RngReference(
    seedHex: '7fffffff',
    nextInt1000: [281, 505, 419, 231, 812, 910, 221, 302, 517, 515],
    nextInt1024: [634, 928, 869, 838, 816, 661, 69, 48, 466, 982],
    nextLongHex: ['-6141134c17c15d3d', '-26ba5fe82e708062', '-33c421965a82c4b4', '1155339a0c33450c', '74951bcaf5a0b8f6', '-48d60aff567f94bf'],
    nextFloat: [0.620100736618042, 0.9072057008743286, 0.8487186431884766, 0.818595826625824, 0.7977885007858276, 0.6464421153068542],
    nextDouble: [0.6201007799387834, 0.8487186553865054, 0.7977885253197272, 0.0677063174196677, 0.45540022789662593, 0.7154839733558263],
  ),
  RngReference(
    seedHex: '-80000000',
    nextInt1000: [992, 668, 837, 655, 307, 581, 747, 937, 967, 718],
    nextInt1024: [388, 372, 413, 343, 513, 269, 920, 479, 991, 899],
    nextLongHex: ['613b34605d21d138', '67724b7a55f5f0be', '-7f8fb609bc918fc6', '-19d00f4888075afd', '-81cc5c11f14d893', '6c7c4d2be682704b'],
    nextFloat: [0.3798096179962158, 0.36379724740982056, 0.40408772230148315, 0.3357839584350586, 0.5017133355140686, 0.26340389251708984],
    nextDouble: [0.37980963831837855, 0.4040877422062158, 0.5017133841425762, 0.8991690049862529, 0.9683109652785683, 0.423771692818818],
  ),
  RngReference(
    seedHex: '112210f47de98115',
    nextInt1000: [561, 928, 956, 763, 100, 688, 587, 180, 104, 59],
    nextInt1024: [309, 934, 196, 943, 77, 93, 273, 627, 72, 63],
    nextLongHex: ['4d66b6e2e981d470', '312a5d08ebf1d926', '134a3c48174ed161', '44672ff69cec1fe8', '122897e00ff98a56', '-4f9d75fbfb8afbc3'],
    nextFloat: [0.3023484945297241, 0.9121372699737549, 0.1920526623725891, 0.9216590523719788, 0.07535147666931152, 0.09104639291763306],
    nextDouble: [0.3023485528251125, 0.19205267610637933, 0.07535149292717003, 0.2671995105293091, 0.07093189749719842, 0.689003587028541],
  ),
  RngReference(
    seedHex: '-112210f47de98115',
    nextInt1000: [337, 533, 471, 989, 758, 653, 325, 904, 992, 420],
    nextInt1024: [714, 642, 235, 34, 813, 559, 493, 455, 740, 721],
    nextLongHex: ['-4d7274bc5f4214d5', '3af4d17e08a8200a', '-349f10e2743a5d25', '7b61758a71f72b01', '-46ea223f4b8d48f7', '1f86d06e71f19f16'],
    nextFloat: [0.6974722743034363, 0.6278979182243347, 0.23029810190200806, 0.03381538391113281, 0.7944478392601013, 0.5459843873977661],
    nextDouble: [0.6974722985610057, 0.23029811730705774, 0.7944478473959034, 0.4819558627184888, 0.7229899124037535, 0.12315084703405343],
  ),
  RngReference(
    seedHex: '20000000000001',
    nextInt1000: [985, 588, 847, 313, 254, 904, 434, 606, 978, 748],
    nextInt1024: [748, 102, 419, 417, 212, 37, 340, 674, 990, 727],
    nextLongHex: ['-44e52a8ce6476328', '68fb0e6f684df992', '352cccfc0946b8f0', '552cf1e5a8ab85dd', '-841262a4a0cf798', '190e5722719b812'],
    nextFloat: [0.7308781743049622, 0.10047316551208496, 0.41008079051971436, 0.4074397683143616, 0.20771479606628418, 0.03623533248901367],
    nextDouble: [0.7308781907032909, 0.41008081149220166, 0.20771484130971707, 0.3327170559595112, 0.9677559094241207, 0.006117182265761301],
  ),
  RngReference(
    seedHex: '7fffffffffffffff',
    nextInt1000: [913, 225, 579, 439, 604, 438, 477, 478, 765, 731],
    nextInt1024: [275, 450, 12, 561, 677, 615, 426, 408, 845, 57],
    nextLongHex: ['44d96cb3708722c3', '32420178c4bff9e', '-5681a196663244b4', '6a9bb39a6637c50c', '-2c806435f186c70a', '-31a78affb0b314bf'],
    nextFloat: [0.26894259452819824, 0.43956196308135986, 0.012269973754882812, 0.5480346083641052, 0.6620844602584839, 0.6007954478263855],
    nextDouble: [0.26894263088050496, 0.012269981921235296, 0.6620844841121951, 0.4164383172882866, 0.8261659004768312, 0.8060372517968333],
  ),
];

void main() {
  group('Property 4: JavaRandomInt64 reproduces java.util.Random', () {
    for (final ref in kRngReferences) {
      test('seed 0x${ref.seedHex} matches reference stream', () {
        final seed = _hex(ref.seedHex);

        // nextInt(1000) — non power-of-two bound.
        final rInt = JavaRandomInt64(seed);
        for (int i = 0; i < ref.nextInt1000.length; i++) {
          final v = rInt.nextInt(1000);
          expect(v, ref.nextInt1000[i], reason: 'nextInt(1000)[$i]');
          expect(Int64(v) < _twoTo53, isTrue,
              reason: 'nextInt result must fit in 2^53');
        }

        // nextInt(1024) — power-of-two bound (separate code path).
        final rIntPow = JavaRandomInt64(seed);
        for (int i = 0; i < ref.nextInt1024.length; i++) {
          expect(rIntPow.nextInt(1024), ref.nextInt1024[i],
              reason: 'nextInt(1024)[$i]');
        }

        // nextLong — full 64-bit, compared as Int64 hex.
        final rLong = JavaRandomInt64(seed);
        for (int i = 0; i < ref.nextLongHex.length; i++) {
          final got = rLong.nextLong();
          expect(got, _hex(ref.nextLongHex[i]), reason: 'nextLong[$i]');
        }

        // nextFloat.
        final rFloat = JavaRandomInt64(seed);
        for (int i = 0; i < ref.nextFloat.length; i++) {
          expect(rFloat.nextFloat(), closeTo(ref.nextFloat[i], 1e-12),
              reason: 'nextFloat[$i]');
        }

        // nextDouble.
        final rDouble = JavaRandomInt64(seed);
        for (int i = 0; i < ref.nextDouble.length; i++) {
          expect(rDouble.nextDouble(), closeTo(ref.nextDouble[i], 1e-12),
              reason: 'nextDouble[$i]');
        }
      });
    }

    test('no divergence above 2^53: every reduced draw fits in a JS double',
        () {
      // Exercise many draws for a high seed and assert every reduced result
      // (nextInt/nextFloat/nextDouble) stays exactly representable.
      final r = JavaRandomInt64(_hex('7fffffffffffffff'));
      for (int i = 0; i < 1000; i++) {
        final n = r.nextInt(1 << 20);
        expect(Int64(n) < _twoTo53, isTrue);
        final f = r.nextFloat();
        expect(f >= 0.0 && f < 1.0, isTrue);
        final d = r.nextDouble();
        expect(d >= 0.0 && d < 1.0, isTrue);
      }
    });
  });
}
