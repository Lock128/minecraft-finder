import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gem_ore_struct_finder_mc/providers/search_history_provider.dart';
import 'package:gem_ore_struct_finder_mc/models/search_history_entry.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';

void main() {
  group('SearchHistoryProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    SearchHistoryEntry createEntry({
      String seed = 'test_seed',
      int resultCount = 10,
    }) {
      return SearchHistoryEntry(
        seed: seed,
        centerX: 0,
        centerY: -59,
        centerZ: 0,
        radius: 50,
        oreTypes: {OreType.diamond},
        structures: <StructureType>{},
        edition: MinecraftEdition.java,
        versionEra: VersionEra.modern,
        timestamp: DateTime.now(),
        resultCount: resultCount,
        includeOres: true,
        includeStructures: false,
      );
    }

    test('initial state is empty list', () {
      final provider = SearchHistoryProvider();
      expect(provider.entries, isEmpty);
    });

    test('addEntry inserts entry at the beginning', () async {
      final provider = SearchHistoryProvider();
      final entry = createEntry(seed: 'first');

      await provider.addEntry(entry);

      expect(provider.entries.length, 1);
      expect(provider.entries.first.seed, 'first');
    });

    test('addEntry notifies listeners', () async {
      final provider = SearchHistoryProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.addEntry(createEntry());

      expect(notifyCount, greaterThan(0));
    });

    test('entries are ordered most recent first', () async {
      final provider = SearchHistoryProvider();

      await provider.addEntry(createEntry(seed: 'older'));
      await provider.addEntry(createEntry(seed: 'newer'));

      expect(provider.entries.first.seed, 'newer');
      expect(provider.entries.last.seed, 'older');
    });

    test('enforces max 20 entries limit', () async {
      final provider = SearchHistoryProvider();

      for (int i = 0; i < 25; i++) {
        await provider.addEntry(createEntry(seed: 'seed_$i'));
      }

      expect(provider.entries.length, 20);
      // Most recent entry should be the last one added
      expect(provider.entries.first.seed, 'seed_24');
    });

    test('clearHistory removes all entries', () async {
      final provider = SearchHistoryProvider();

      await provider.addEntry(createEntry(seed: 'first'));
      await provider.addEntry(createEntry(seed: 'second'));

      await provider.clearHistory();

      expect(provider.entries, isEmpty);
    });

    test('clearHistory notifies listeners', () async {
      final provider = SearchHistoryProvider();
      await provider.addEntry(createEntry());

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.clearHistory();

      expect(notifyCount, greaterThan(0));
    });

    test('entries list is unmodifiable', () {
      final provider = SearchHistoryProvider();
      expect(
        () => provider.entries.add(createEntry()),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('persistence: entries are saved to SharedPreferences', () async {
      final provider = SearchHistoryProvider();
      await provider.addEntry(createEntry(seed: 'persist_test'));

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('search_history');
      expect(stored, isNotNull);
      expect(stored!.contains('persist_test'), true);
    });
  });
}
