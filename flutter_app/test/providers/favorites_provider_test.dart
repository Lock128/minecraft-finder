import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gem_ore_struct_finder_mc/providers/favorites_provider.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/favorite_location.dart';

void main() {
  group('FavoritesProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state is empty list', () {
      final provider = FavoritesProvider();
      expect(provider.favorites, isEmpty);
    });

    test('addOreFavorite adds an ore location to favorites', () async {
      final provider = FavoritesProvider();
      final ore = OreLocation(
        x: 10,
        y: -59,
        z: 20,
        chunkX: 0,
        chunkZ: 1,
        probability: 0.85,
        oreType: OreType.diamond,
      );

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.addOreFavorite(ore, '12345');

      expect(provider.favorites.length, 1);
      expect(provider.favorites.first.type, FavoriteType.ore);
      expect(provider.favorites.first.seed, '12345');
      expect(provider.favorites.first.oreLocation!.x, 10);
      expect(notifyCount, greaterThan(0));
    });

    test('addStructureFavorite adds a structure location to favorites',
        () async {
      final provider = FavoritesProvider();
      final structure = StructureLocation(
        x: 100,
        y: 64,
        z: -200,
        chunkX: 6,
        chunkZ: -13,
        probability: 0.92,
        structureType: StructureType.village,
      );

      await provider.addStructureFavorite(structure, 'seed42');

      expect(provider.favorites.length, 1);
      expect(provider.favorites.first.type, FavoriteType.structure);
      expect(provider.favorites.first.structureLocation!.structureType,
          StructureType.village);
    });

    test('does not add duplicate ore favorites', () async {
      final provider = FavoritesProvider();
      final ore = OreLocation(
        x: 10,
        y: -59,
        z: 20,
        chunkX: 0,
        chunkZ: 1,
        probability: 0.85,
        oreType: OreType.diamond,
      );

      await provider.addOreFavorite(ore, '12345');
      await provider.addOreFavorite(ore, '12345');

      expect(provider.favorites.length, 1);
    });

    test('removeFavorite removes by id', () async {
      final provider = FavoritesProvider();
      final ore = OreLocation(
        x: 10,
        y: -59,
        z: 20,
        chunkX: 0,
        chunkZ: 1,
        probability: 0.85,
        oreType: OreType.diamond,
      );

      await provider.addOreFavorite(ore, '12345');
      final id = provider.favorites.first.id;

      await provider.removeFavorite(id);

      expect(provider.favorites, isEmpty);
    });

    test('removeOreFavorite removes matching ore location', () async {
      final provider = FavoritesProvider();
      final ore = OreLocation(
        x: 10,
        y: -59,
        z: 20,
        chunkX: 0,
        chunkZ: 1,
        probability: 0.85,
        oreType: OreType.diamond,
      );

      await provider.addOreFavorite(ore, '12345');
      await provider.removeOreFavorite(ore, '12345');

      expect(provider.favorites, isEmpty);
    });

    test('enforces max 100 favorites limit', () async {
      final provider = FavoritesProvider();

      for (int i = 0; i < 105; i++) {
        final ore = OreLocation(
          x: i,
          y: -59,
          z: i * 2,
          chunkX: 0,
          chunkZ: 0,
          probability: 0.5,
          oreType: OreType.diamond,
        );
        await provider.addOreFavorite(ore, 'seed$i');
      }

      expect(provider.favorites.length, 100);
    });

    test('reorder moves item from oldIndex to newIndex', () async {
      final provider = FavoritesProvider();

      for (int i = 0; i < 3; i++) {
        final ore = OreLocation(
          x: i * 10,
          y: -59,
          z: 0,
          chunkX: i,
          chunkZ: 0,
          probability: 0.5,
          oreType: OreType.diamond,
        );
        await provider.addOreFavorite(ore, 'seed$i');
      }

      // Favorites are inserted at index 0, so order is [seed2, seed1, seed0]
      final firstId = provider.favorites[0].id;

      await provider.reorder(0, 3); // Move first to end

      expect(provider.favorites.last.id, firstId);
    });

    test('isOreFavorite returns true for existing favorites', () async {
      final provider = FavoritesProvider();
      final ore = OreLocation(
        x: 10,
        y: -59,
        z: 20,
        chunkX: 0,
        chunkZ: 1,
        probability: 0.85,
        oreType: OreType.diamond,
      );

      await provider.addOreFavorite(ore, '12345');

      expect(provider.isOreFavorite(ore, '12345'), true);
      expect(provider.isOreFavorite(ore, 'different_seed'), false);
    });

    test('isStructureFavorite returns true for existing favorites', () async {
      final provider = FavoritesProvider();
      final structure = StructureLocation(
        x: 100,
        y: 64,
        z: -200,
        chunkX: 6,
        chunkZ: -13,
        probability: 0.92,
        structureType: StructureType.village,
      );

      await provider.addStructureFavorite(structure, 'seed42');

      expect(provider.isStructureFavorite(structure, 'seed42'), true);
      expect(provider.isStructureFavorite(structure, 'other'), false);
    });

    test('updateLabel changes the label for a favorite', () async {
      final provider = FavoritesProvider();
      final ore = OreLocation(
        x: 10,
        y: -59,
        z: 20,
        chunkX: 0,
        chunkZ: 1,
        probability: 0.85,
        oreType: OreType.diamond,
      );

      await provider.addOreFavorite(ore, '12345');
      final id = provider.favorites.first.id;

      await provider.updateLabel(id, 'My Diamond Spot');

      expect(provider.favorites.first.label, 'My Diamond Spot');
    });

    test('groupedBySeed groups favorites by their seed value', () async {
      final provider = FavoritesProvider();

      final ore1 = OreLocation(
        x: 10, y: -59, z: 20,
        chunkX: 0, chunkZ: 1, probability: 0.85, oreType: OreType.diamond,
      );
      final ore2 = OreLocation(
        x: 30, y: -59, z: 40,
        chunkX: 1, chunkZ: 2, probability: 0.75, oreType: OreType.gold,
      );
      final ore3 = OreLocation(
        x: 50, y: -59, z: 60,
        chunkX: 3, chunkZ: 3, probability: 0.65, oreType: OreType.iron,
      );

      await provider.addOreFavorite(ore1, 'seedA');
      await provider.addOreFavorite(ore2, 'seedA');
      await provider.addOreFavorite(ore3, 'seedB');

      final grouped = provider.groupedBySeed;
      expect(grouped.keys.length, 2);
      expect(grouped['seedA']!.length, 2);
      expect(grouped['seedB']!.length, 1);
    });

    test('persistence: favorites are saved and can be loaded', () async {
      // First provider adds data
      final provider1 = FavoritesProvider();
      final ore = OreLocation(
        x: 10, y: -59, z: 20,
        chunkX: 0, chunkZ: 1, probability: 0.85, oreType: OreType.diamond,
      );
      await provider1.addOreFavorite(ore, 'persist_seed');

      // Verify SharedPreferences contains data
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('favorites_list');
      expect(stored, isNotNull);
      expect(stored!.contains('persist_seed'), true);
    });
  });
}
