import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  // Keys for different preferences
  static const String _seedKey = 'last_world_seed';
  static const String _xKey = 'last_x_coordinate';
  static const String _yKey = 'last_y_coordinate';
  static const String _zKey = 'last_z_coordinate';
  static const String _radiusKey = 'last_search_radius';

  // Default values
  static const String _defaultSeed = '8674308105921866736';
  static const String _defaultX = '0';
  static const String _defaultY = '-59';
  static const String _defaultZ = '0';
  static const String _defaultRadius = '50';

  // Seed preferences
  static Future<String> getLastSeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_seedKey) ?? _defaultSeed;
  }

  static Future<void> saveLastSeed(String seed) async {
    if (seed.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seedKey, seed);
    }
  }

  // X coordinate preferences
  static Future<String> getLastX() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_xKey) ?? _defaultX;
  }

  static Future<void> saveLastX(String x) async {
    if (x.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_xKey, x);
    }
  }

  // Y coordinate preferences
  static Future<String> getLastY() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_yKey) ?? _defaultY;
  }

  static Future<void> saveLastY(String y) async {
    if (y.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_yKey, y);
    }
  }

  // Z coordinate preferences
  static Future<String> getLastZ() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_zKey) ?? _defaultZ;
  }

  static Future<void> saveLastZ(String z) async {
    if (z.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_zKey, z);
    }
  }

  // Radius preferences
  static Future<String> getLastRadius() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_radiusKey) ?? _defaultRadius;
  }

  static Future<void> saveLastRadius(String radius) async {
    if (radius.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_radiusKey, radius);
    }
  }

  // Convenience method to load all search parameters at once
  static Future<Map<String, String>> getAllSearchParams() async {
    return {
      'seed': await getLastSeed(),
      'x': await getLastX(),
      'y': await getLastY(),
      'z': await getLastZ(),
      'radius': await getLastRadius(),
    };
  }
}
