import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/favorite_location.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';

void main() {
  group('FavoriteLocation', () {
    test('ore type fromJson/toJson roundtrip', () {
      final original = FavoriteLocation(
        id: 'test_id_123',
        type: FavoriteType.ore,
        oreLocation: OreLocation(
          x: 10,
          y: -59,
          z: 20,
          chunkX: 0,
          chunkZ: 1,
          probability: 0.85,
          oreType: OreType.diamond,
        ),
        seed: '12345',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        label: 'My Spot',
      );

      final json = original.toJson();
      final restored = FavoriteLocation.fromJson(json);

      expect(restored.id, 'test_id_123');
      expect(restored.type, FavoriteType.ore);
      expect(restored.oreLocation!.x, 10);
      expect(restored.oreLocation!.y, -59);
      expect(restored.oreLocation!.z, 20);
      expect(restored.oreLocation!.probability, 0.85);
      expect(restored.oreLocation!.oreType, OreType.diamond);
      expect(restored.seed, '12345');
      expect(restored.label, 'My Spot');
      expect(restored.timestamp.year, 2024);
    });

    test('structure type fromJson/toJson roundtrip', () {
      final original = FavoriteLocation(
        id: 'struct_id_456',
        type: FavoriteType.structure,
        structureLocation: StructureLocation(
          x: 100,
          y: 64,
          z: -200,
          chunkX: 6,
          chunkZ: -13,
          probability: 0.92,
          structureType: StructureType.village,
          biome: 'plains',
        ),
        seed: 'seed42',
        timestamp: DateTime(2024, 3, 20, 14, 0),
      );

      final json = original.toJson();
      final restored = FavoriteLocation.fromJson(json);

      expect(restored.id, 'struct_id_456');
      expect(restored.type, FavoriteType.structure);
      expect(restored.structureLocation!.x, 100);
      expect(restored.structureLocation!.z, -200);
      expect(restored.structureLocation!.structureType, StructureType.village);
      expect(restored.structureLocation!.biome, 'plains');
      expect(restored.seed, 'seed42');
      expect(restored.label, '');
    });

    test('x, y, z getters for ore type', () {
      final fav = FavoriteLocation(
        id: 'id1',
        type: FavoriteType.ore,
        oreLocation: OreLocation(
          x: 5, y: 10, z: 15,
          chunkX: 0, chunkZ: 0, probability: 0.5, oreType: OreType.gold,
        ),
        seed: 'seed',
        timestamp: DateTime.now(),
      );

      expect(fav.x, 5);
      expect(fav.y, 10);
      expect(fav.z, 15);
    });

    test('x, y, z getters for structure type', () {
      final fav = FavoriteLocation(
        id: 'id2',
        type: FavoriteType.structure,
        structureLocation: StructureLocation(
          x: 100, y: 64, z: -50,
          chunkX: 6, chunkZ: -4, probability: 0.8,
          structureType: StructureType.stronghold,
        ),
        seed: 'seed',
        timestamp: DateTime.now(),
      );

      expect(fav.x, 100);
      expect(fav.y, 64);
      expect(fav.z, -50);
    });

    test('displayName uses label when set', () {
      final fav = FavoriteLocation(
        id: 'id1',
        type: FavoriteType.ore,
        oreLocation: OreLocation(
          x: 5, y: 10, z: 15,
          chunkX: 0, chunkZ: 0, probability: 0.5, oreType: OreType.diamond,
        ),
        seed: 'seed',
        timestamp: DateTime.now(),
        label: 'Custom Label',
      );

      expect(fav.displayName, 'Custom Label');
    });

    test('displayName generates name from ore type when no label', () {
      final fav = FavoriteLocation(
        id: 'id1',
        type: FavoriteType.ore,
        oreLocation: OreLocation(
          x: 5, y: 10, z: 15,
          chunkX: 0, chunkZ: 0, probability: 0.5, oreType: OreType.diamond,
        ),
        seed: 'seed',
        timestamp: DateTime.now(),
      );

      expect(fav.displayName, contains('diamond'));
      expect(fav.displayName, contains('5'));
    });

    test('displayName generates name from structure type when no label', () {
      final fav = FavoriteLocation(
        id: 'id2',
        type: FavoriteType.structure,
        structureLocation: StructureLocation(
          x: 100, y: 64, z: -50,
          chunkX: 6, chunkZ: -4, probability: 0.8,
          structureType: StructureType.village,
        ),
        seed: 'seed',
        timestamp: DateTime.now(),
      );

      expect(fav.displayName, contains('village'));
      expect(fav.displayName, contains('100'));
    });

    test('fromJson handles missing label field', () {
      final json = {
        'id': 'nolabel_id',
        'type': 'ore',
        'oreLocation': {
          'x': 1, 'y': 2, 'z': 3,
          'chunkX': 0, 'chunkZ': 0,
          'probability': 0.5, 'oreType': 'diamond',
        },
        'seed': 's1',
        'timestamp': '2024-01-01T00:00:00.000',
      };

      final fav = FavoriteLocation.fromJson(json);
      expect(fav.label, '');
    });

    test('toJson includes null structureLocation for ore type', () {
      final fav = FavoriteLocation(
        id: 'id1',
        type: FavoriteType.ore,
        oreLocation: OreLocation(
          x: 5, y: 10, z: 15,
          chunkX: 0, chunkZ: 0, probability: 0.5, oreType: OreType.gold,
        ),
        seed: 'seed',
        timestamp: DateTime.now(),
      );

      final json = fav.toJson();
      expect(json['structureLocation'], isNull);
      expect(json['oreLocation'], isNotNull);
    });
  });
}
