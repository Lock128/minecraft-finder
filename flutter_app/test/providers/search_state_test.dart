import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gem_ore_struct_finder_mc/providers/search_state.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';

void main() {
  group('SearchState', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state has default values', () {
      final state = SearchState();
      expect(state.selectedEdition, MinecraftEdition.java);
      expect(state.selectedVersionEra, VersionEra.modern);
      expect(state.selectedOreTypes, {OreType.diamond});
      expect(state.includeNether, false);
      expect(state.includeOres, true);
      expect(state.includeStructures, false);
      expect(state.selectedStructures, isEmpty);
      expect(state.isLoading, false);
      expect(state.results, isEmpty);
      expect(state.structureResults, isEmpty);
    });

    test('default controller values are correct', () {
      final state = SearchState();
      expect(state.xController.text, '0');
      expect(state.yController.text, '-59');
      expect(state.zController.text, '0');
      expect(state.radiusController.text, '50');
    });

    test('setOreTypes updates selected ore types and notifies', () {
      final state = SearchState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.setOreTypes({OreType.gold, OreType.iron});

      expect(state.selectedOreTypes, {OreType.gold, OreType.iron});
      expect(notifyCount, greaterThan(0));
    });

    test('setIncludeNether updates includeNether and notifies', () {
      final state = SearchState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.setIncludeNether(true);

      expect(state.includeNether, true);
      expect(notifyCount, greaterThan(0));
    });

    test('setIncludeOres updates includeOres and notifies', () {
      final state = SearchState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.setIncludeOres(false);

      expect(state.includeOres, false);
      expect(notifyCount, greaterThan(0));
    });

    test('setIncludeStructures updates and notifies', () {
      final state = SearchState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.setIncludeStructures(true);

      expect(state.includeStructures, true);
      expect(notifyCount, greaterThan(0));
    });

    test('setSelectedStructures updates selected structures', () {
      final state = SearchState();

      state.setSelectedStructures({StructureType.village, StructureType.stronghold});

      expect(state.selectedStructures,
          {StructureType.village, StructureType.stronghold});
    });

    test('setEdition updates edition and notifies', () {
      final state = SearchState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.setEdition(MinecraftEdition.bedrock);

      expect(state.selectedEdition, MinecraftEdition.bedrock);
      expect(notifyCount, greaterThan(0));
    });

    test('setVersionEra updates version era and notifies', () {
      final state = SearchState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.setVersionEra(VersionEra.legacy);

      expect(state.selectedVersionEra, VersionEra.legacy);
      expect(notifyCount, greaterThan(0));
    });

    test('dispose cleans up controllers', () {
      final state = SearchState();
      // Should not throw
      state.dispose();
    });
  });
}
