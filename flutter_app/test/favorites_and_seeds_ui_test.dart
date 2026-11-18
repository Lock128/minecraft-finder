import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/l10n/app_localizations.dart';
import 'package:gem_ore_struct_finder_mc/l10n/localization_delegates.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/providers/favorites_provider.dart';
import 'package:gem_ore_struct_finder_mc/widgets/favorites_tab.dart';
import 'package:gem_ore_struct_finder_mc/widgets/recent_seeds_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

Widget _wrap(Widget child, {List<ChangeNotifierProvider>? providers}) {
  final app = MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
  return providers == null
      ? app
      : MultiProvider(providers: providers, child: app);
}

void main() {
  group('Recent seeds', () {
    testWidgets('collapsed by default, toggle shows and remembers', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'recent_world_seeds': jsonEncode(['111', '222']),
      });
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(RecentSeedsWidget(seedController: controller, isDarkMode: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('${_l10n.recentSeeds} (2)'), findsOneWidget);
      expect(find.text('111'), findsNothing);

      await tester.tap(find.text('${_l10n.recentSeeds} (2)'));
      await tester.pumpAndSettle();
      expect(find.text('111'), findsOneWidget);
      expect(find.text('222'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('recent_seeds_expanded'), isTrue);

      await tester.tap(find.text('222'));
      expect(controller.text, '222');
    });
  });

  group('Favorites tab', () {
    testWidgets('remove button deletes a favorite and Undo restores it', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final favorites = FavoritesProvider();
      await favorites.addOreFavorite(
        OreLocation(
          x: 10,
          y: -59,
          z: 20,
          chunkX: 0,
          chunkZ: 1,
          probability: 0.9,
          oreType: OreType.diamond,
        ),
        '12345',
      );

      await tester.pumpWidget(
        _wrap(
          const FavoritesTab(isDarkMode: false),
          providers: [
            ChangeNotifierProvider<FavoritesProvider>.value(value: favorites),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('(10, -59, 20)'), findsOneWidget);

      await tester.tap(find.byTooltip(_l10n.favoritesRemove));
      await tester.pumpAndSettle();
      expect(favorites.favorites, isEmpty);
      expect(find.text(_l10n.favoritesRemoved), findsOneWidget);

      await tester.tap(find.text(_l10n.undoAction));
      await tester.pumpAndSettle();
      expect(favorites.favorites, hasLength(1));
      expect(find.text('(10, -59, 20)'), findsOneWidget);
    });
  });
}
