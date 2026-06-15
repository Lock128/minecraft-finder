import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gem_ore_struct_finder_mc/l10n/app_localizations.dart';
import 'package:gem_ore_struct_finder_mc/widgets/results_map_view.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';

void main() {
  group('ResultsMapView', () {
    Widget buildTestWidget({
      List<OreLocation> results = const [],
      List<StructureLocation> structureResults = const [],
      bool isDarkMode = false,
    }) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: ResultsMapView(
              results: results,
              structureResults: structureResults,
              isDarkMode: isDarkMode,
            ),
          ),
        ),
      );
    }

    testWidgets('shows empty state when no results', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Should show "No results yet" text
      expect(find.textContaining('No results yet'), findsOneWidget);
    });

    testWidgets('renders map with ore results', (tester) async {
      final ores = [
        OreLocation(
          x: 10, y: -59, z: 20,
          chunkX: 0, chunkZ: 1,
          probability: 0.85, oreType: OreType.diamond,
        ),
        OreLocation(
          x: 50, y: -59, z: 100,
          chunkX: 3, chunkZ: 6,
          probability: 0.65, oreType: OreType.gold,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(results: ores));
      await tester.pumpAndSettle();

      // Should not show empty state
      expect(find.textContaining('No results yet'), findsNothing);
      // CustomPaint should be present (the map)
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders legend with ore types', (tester) async {
      final ores = [
        OreLocation(
          x: 10, y: -59, z: 20,
          chunkX: 0, chunkZ: 1,
          probability: 0.85, oreType: OreType.diamond,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(results: ores));
      await tester.pumpAndSettle();

      // Legend should include ore type name
      expect(find.textContaining('diamond'), findsOneWidget);
    });

    testWidgets('renders legend with structures label when structures present',
        (tester) async {
      final structures = [
        StructureLocation(
          x: 100, y: 64, z: -200,
          chunkX: 6, chunkZ: -13,
          probability: 0.92, structureType: StructureType.village,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(structureResults: structures));
      await tester.pumpAndSettle();

      // Legend should show "Structures" label
      expect(find.textContaining('Structures'), findsOneWidget);
    });

    testWidgets('InteractiveViewer is present for zoom/pan', (tester) async {
      final ores = [
        OreLocation(
          x: 10, y: -59, z: 20,
          chunkX: 0, chunkZ: 1,
          probability: 0.85, oreType: OreType.diamond,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(results: ores));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      final ores = [
        OreLocation(
          x: 10, y: -59, z: 20,
          chunkX: 0, chunkZ: 1,
          probability: 0.85, oreType: OreType.diamond,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        results: ores,
        isDarkMode: true,
      ));
      await tester.pumpAndSettle();

      // Should render without throwing
      expect(find.byType(ResultsMapView), findsOneWidget);
    });

    testWidgets('GestureDetector is present for tap interaction',
        (tester) async {
      final ores = [
        OreLocation(
          x: 10, y: -59, z: 20,
          chunkX: 0, chunkZ: 1,
          probability: 0.85, oreType: OreType.diamond,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(results: ores));
      await tester.pumpAndSettle();

      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
