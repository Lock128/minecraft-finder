import 'package:flutter/material.dart';
import '../utils/preferences_service.dart';

/// Holds app-level settings: theme mode and locale.
class AppSettings extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  Locale? _locale;
  Locale? get locale => _locale;

  AppSettings() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final localeCode = await PreferencesService.getLocale();
    if (localeCode != null && localeCode.isNotEmpty) {
      _locale = Locale(localeCode);
      notifyListeners();
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    PreferencesService.saveLocale(locale.languageCode);
    notifyListeners();
  }
}
