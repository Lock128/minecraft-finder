import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_settings.dart';
import 'providers/favorites_provider.dart';
import 'providers/search_history_provider.dart';
import 'theme/gamer_theme.dart';
import 'widgets/ore_finder_screen.dart';

export 'widgets/ore_finder_screen.dart' show OreFinderScreen;

void main() {
  runApp(const GemOreStructFinderApp());
}

class GemOreStructFinderApp extends StatelessWidget {
  const GemOreStructFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => SearchHistoryProvider()),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Gem, Ore & Struct Finder for MC - Find Diamonds, Gold, Netherite & More',
            debugShowCheckedModeBanner: false,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: GamerTheme.buildLight(),
            darkTheme: GamerTheme.buildDark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: settings.locale,
            home: OreFinderScreen(
              onThemeToggle: settings.toggleTheme,
              isDarkMode: settings.isDarkMode,
              onLocaleChanged: settings.setLocale,
              currentLocale: settings.locale,
            ),
          );
        },
      ),
    );
  }
}
