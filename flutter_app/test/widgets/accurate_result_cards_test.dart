// Feature: seed-accurate-worldgen (M6 UX). Spec task 16.5.
// Widget tests for the accurate result cards + mode notices in ResultsTab.
// Validates: Requirements 12.3, 12.4, 12.5, 5.4.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/l10n/app_localizations.dart';
import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/search_runner.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/worldgen_engine.dart';
import 'package:gem_ore_struct_finder_mc/providers/monetization_config.dart';
import 'package:gem_ore_struct_finder_mc/providers/pro_status_provider.dart';
import 'package:gem_ore_struct_finder_mc/widgets/results_tab.dart';
import 'package:provider/provider.dart';

final AppLocalizations enL10n = lookupAppLocalizations(const Locale('en'));

OreLocation oreAt({
  OreType type = OreType.diamond,
  int estimatedVeinSize = 8,
  double probability = 0.9,
}) =>
    OreLocation(
      x: 10,
      y: -59,
      z: 20,
      chunkX: 0,
      chunkZ: 1,
      probability: probability,
      oreType: type,
      estimatedVeinSize: estimatedVeinSize,
    );

StructureLocation structureAt({String? biome = 'plains'}) => StructureLocation(
      x: 100,
      y: 64,
      z: 200,
      chunkX: 6,
      chunkZ: 12,
      probability: 0.8,
      structureType: StructureType.village,
      biome: biome,
    );

Widget buildTestWidget({
  required List<OreLocation> results,
  required List<StructureLocation> structureResults,
  SearchMeta? searchMeta,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MonetizationConfig>(
          create: (_) => MonetizationConfig()),
      ChangeNotifierProvider<ProStatusProvider>(
          create: (_) => ProStatusProvider()),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: ResultsTab(
          results: results,
          structureResults: structureResults,
          isLoading: false,
          findAllNetherite: false,
          selectedOreTypes: const {OreType.diamond},
          searchMeta: searchMeta,
        ),
      ),
    ),
  );
}

void main() {
  group('Accurate verified result cards (Req 12.3, 12.4, 12.5)', () {
    testWidgets('omit probability and show vein size for ore results',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        results: [oreAt(estimatedVeinSize: 8)],
        structureResults: const [],
        searchMeta: const SearchMeta.accurate('java-1.20'),
      ));
      await tester.pumpAndSettle();

      // No fabricated probability (Req 12.3).
      expect(find.textContaining('Probability:'), findsNothing);
      // Real vein size metadata (Req 12.4).
      expect(find.text(enL10n.veinSizeLabel(8)), findsOneWidget);
      // No disclaimer for a Verified Accurate result (Req 12.5); instead the
      // positive accurate notice.
      expect(find.text(enL10n.estimateDisclaimer), findsNothing);
      expect(find.text(enL10n.accurateResultsNotice), findsOneWidget);
    });

    testWidgets('omit probability and show variant for structure results',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        results: const [],
        structureResults: [structureAt(biome: 'plains')],
        searchMeta: const SearchMeta.accurate('java-1.20'),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Probability:'), findsNothing);
      // Variant derived from the biome (Req 12.4).
      expect(find.text(enL10n.structureVariantLabel('Plains')), findsOneWidget);
      expect(find.text(enL10n.estimateDisclaimer), findsNothing);
    });
  });

  group('Estimate result cards keep probability + disclaimer', () {
    testWidgets('plain estimate shows probability and disclaimer',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        results: [oreAt(probability: 0.9)],
        structureResults: const [],
        searchMeta: const SearchMeta.estimate('java-1.20'),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Probability:'), findsWidgets);
      expect(find.text(enL10n.estimateDisclaimer), findsOneWidget);
      expect(find.text(enL10n.accurateResultsNotice), findsNothing);
    });
  });

  group('Fallback notice (Req 5.4)', () {
    testWidgets('shows the fallback reason text when Accurate degraded',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        results: [oreAt()],
        structureResults: const [],
        searchMeta: const SearchMeta.fallback(
            'java-1.20', FallbackReason.unverifiedVersion),
      ));
      await tester.pumpAndSettle();

      // The degraded result is Estimate: probability shows, and the fallback
      // notice states the reason.
      expect(find.textContaining('Probability:'), findsWidgets);
      expect(find.text(FallbackReason.unverifiedVersion.text), findsOneWidget);
    });
  });
}
