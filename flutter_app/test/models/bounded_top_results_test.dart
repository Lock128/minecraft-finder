import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/bounded_top_results.dart';

void main() {
  group('BoundedTopResults', () {
    test('retains only the top-N highest-scoring items', () {
      final top = BoundedTopResults<int>(3, (v) => v.toDouble());
      for (final v in [5, 1, 9, 3, 7, 2, 8]) {
        top.add(v);
      }
      // Highest three, sorted descending.
      expect(top.toList(), [9, 8, 7]);
    });

    test('keeps everything when fewer items than capacity are added', () {
      final top = BoundedTopResults<int>(5, (v) => v.toDouble());
      top.add(2);
      top.add(4);
      top.add(1);
      expect(top.toList(), [4, 2, 1]);
    });

    test('totalOffered counts every candidate regardless of retention', () {
      final top = BoundedTopResults<int>(2, (v) => v.toDouble());
      for (final v in [1, 2, 3, 4, 5]) {
        top.add(v);
      }
      expect(top.totalOffered, 5);
      expect(top.length, 2);
      expect(top.toList(), [5, 4]);
    });

    test('output stays sorted descending as items arrive out of order', () {
      final top = BoundedTopResults<double>(4, (v) => v);
      for (final v in [0.1, 0.9, 0.5, 0.3, 0.95, 0.2]) {
        top.add(v);
      }
      final result = top.toList();
      for (var i = 0; i < result.length - 1; i++) {
        expect(result[i] >= result[i + 1], isTrue);
      }
      expect(result, [0.95, 0.9, 0.5, 0.3]);
    });

    test('capacity of 1 keeps the single best item', () {
      final top = BoundedTopResults<int>(1, (v) => v.toDouble());
      top.add(3);
      top.add(10);
      top.add(7);
      expect(top.toList(), [10]);
    });
  });
}
