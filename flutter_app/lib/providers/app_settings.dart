import 'dart:ui' show PlatformDispatcher;
import 'package:material_ui/material_ui.dart';
import '../utils/preferences_service.dart';

/// Holds app-level settings: theme mode and locale.
///
/// The theme follows the system until the user taps the theme button. After
/// that the explicit choice is saved and restored on the next start.
class AppSettings extends ChangeNotifier with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return PlatformDispatcher.instance.platformBrightness ==
            Brightness.dark;
    }
  }

  Locale? _locale;
  Locale? get locale => _locale;

  AppSettings() {
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    final localeCode = await PreferencesService.getLocale();
    final savedTheme = await PreferencesService.getThemeMode();
    if (localeCode != null && localeCode.isNotEmpty) {
      _locale = Locale(localeCode);
    }
    if (savedTheme == 'dark') _themeMode = ThemeMode.dark;
    if (savedTheme == 'light') _themeMode = ThemeMode.light;
    notifyListeners();
  }

  @override
  void didChangePlatformBrightness() {
    // Only matters while following the system theme.
    if (_themeMode == ThemeMode.system) notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    PreferencesService.saveThemeMode(
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    PreferencesService.saveLocale(locale.languageCode);
    notifyListeners();
  }
}
