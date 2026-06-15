import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_location.dart';
import '../models/ore_location.dart';
import '../models/structure_location.dart';

/// Manages the user's bookmarked/favorite locations.
/// Persists to SharedPreferences as a JSON list. Max 100 favorites.
class FavoritesProvider extends ChangeNotifier {
  static const _storageKey = 'favorites_list';
  static const _maxFavorites = 100;

  List<FavoriteLocation> _favorites = [];
  List<FavoriteLocation> get favorites => List.unmodifiable(_favorites);

  FavoritesProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = json.decode(jsonStr) as List<dynamic>;
        _favorites = decoded
            .map((e) =>
                FavoriteLocation.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      } catch (_) {
        // Corrupted data, start fresh
        _favorites = [];
      }
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr =
        json.encode(_favorites.map((f) => f.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  /// Check if an ore location is already a favorite.
  bool isOreFavorite(OreLocation ore, String seed) {
    return _favorites.any((f) =>
        f.type == FavoriteType.ore &&
        f.seed == seed &&
        f.oreLocation != null &&
        f.oreLocation!.x == ore.x &&
        f.oreLocation!.y == ore.y &&
        f.oreLocation!.z == ore.z &&
        f.oreLocation!.oreType == ore.oreType);
  }

  /// Check if a structure location is already a favorite.
  bool isStructureFavorite(StructureLocation structure, String seed) {
    return _favorites.any((f) =>
        f.type == FavoriteType.structure &&
        f.seed == seed &&
        f.structureLocation != null &&
        f.structureLocation!.x == structure.x &&
        f.structureLocation!.y == structure.y &&
        f.structureLocation!.z == structure.z &&
        f.structureLocation!.structureType == structure.structureType);
  }

  /// Add an ore location as a favorite.
  Future<void> addOreFavorite(OreLocation ore, String seed) async {
    if (_favorites.length >= _maxFavorites) return;
    if (isOreFavorite(ore, seed)) return;

    final favorite = FavoriteLocation(
      id: '${DateTime.now().millisecondsSinceEpoch}_${ore.x}_${ore.y}_${ore.z}',
      type: FavoriteType.ore,
      oreLocation: ore,
      seed: seed,
      timestamp: DateTime.now(),
    );
    _favorites.insert(0, favorite);
    notifyListeners();
    await _saveFavorites();
  }

  /// Add a structure location as a favorite.
  Future<void> addStructureFavorite(
      StructureLocation structure, String seed) async {
    if (_favorites.length >= _maxFavorites) return;
    if (isStructureFavorite(structure, seed)) return;

    final favorite = FavoriteLocation(
      id: '${DateTime.now().millisecondsSinceEpoch}_${structure.x}_${structure.y}_${structure.z}',
      type: FavoriteType.structure,
      structureLocation: structure,
      seed: seed,
      timestamp: DateTime.now(),
    );
    _favorites.insert(0, favorite);
    notifyListeners();
    await _saveFavorites();
  }

  /// Remove a favorite by ID.
  Future<void> removeFavorite(String id) async {
    _favorites.removeWhere((f) => f.id == id);
    notifyListeners();
    await _saveFavorites();
  }

  /// Remove an ore favorite by matching location.
  Future<void> removeOreFavorite(OreLocation ore, String seed) async {
    _favorites.removeWhere((f) =>
        f.type == FavoriteType.ore &&
        f.seed == seed &&
        f.oreLocation != null &&
        f.oreLocation!.x == ore.x &&
        f.oreLocation!.y == ore.y &&
        f.oreLocation!.z == ore.z &&
        f.oreLocation!.oreType == ore.oreType);
    notifyListeners();
    await _saveFavorites();
  }

  /// Remove a structure favorite by matching location.
  Future<void> removeStructureFavorite(
      StructureLocation structure, String seed) async {
    _favorites.removeWhere((f) =>
        f.type == FavoriteType.structure &&
        f.seed == seed &&
        f.structureLocation != null &&
        f.structureLocation!.x == structure.x &&
        f.structureLocation!.y == structure.y &&
        f.structureLocation!.z == structure.z &&
        f.structureLocation!.structureType == structure.structureType);
    notifyListeners();
    await _saveFavorites();
  }

  /// Update a favorite's label.
  Future<void> updateLabel(String id, String label) async {
    final index = _favorites.indexWhere((f) => f.id == id);
    if (index != -1) {
      _favorites[index].label = label;
      notifyListeners();
      await _saveFavorites();
    }
  }

  /// Reorder favorites.
  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _favorites.removeAt(oldIndex);
    _favorites.insert(newIndex, item);
    notifyListeners();
    await _saveFavorites();
  }

  /// Get favorites grouped by seed.
  Map<String, List<FavoriteLocation>> get groupedBySeed {
    final map = <String, List<FavoriteLocation>>{};
    for (final fav in _favorites) {
      map.putIfAbsent(fav.seed, () => []).add(fav);
    }
    return map;
  }
}
