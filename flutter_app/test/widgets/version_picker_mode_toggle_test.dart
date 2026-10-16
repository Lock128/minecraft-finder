// Feature: seed-accurate-worldgen (M6 UX). Spec task 16.5.
// Widget tests for the version picker and Accurate/Estimate mode toggle in
// EditionVersionCard.
// Validates: Requirements 12.1, 12.2.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/l10n/app_localizations.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/default_registry.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/engine_selector.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/minecraft_version.dart';
import 'package:gem_ore_struct_finder_mc/models/version_availability.dart';
import 'package:gem_ore_struct_finder_mc/widgets/edition_version_card.dart';

final AppLocalizations enL10n = lookupAppLocalizations(const Locale('en'));

/// The registry-sourced version list the real UI feeds the picker.
final List<MinecraftVersion> registryVersions = VersionAvailability
    .supportedVersions(buildDefaultRegistry(),
        edition: MinecraftEdition.java);

Future<void> expandCard(WidgetTester tester) async {
  await tester.tap(find.text(enL10n.editionVersionTitle));
  await tester.pumpAndSettle();
}

Widget buildTestWidget({
  List<MinecraftVersion> availableVersions = const [],
  MinecraftVersion? selectedVersion,
  ValueChanged<MinecraftVersion?>? onVersionChanged,
  SearchMode searchMode = SearchMode.estimate,
  ValueChanged<SearchMode>? onSearchModeChanged,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: SingleChildScrollView(
        child: EditionVersionCard(
          selectedEdition: MinecraftEdition.java,
          selectedVersionEra: VersionEra.modern,
          onEditionChanged: (_) {},
          onVersionEraChanged: (_) {},
          availableVersions: availableVersions,
          selectedVersion: selectedVersion,
          onVersionChanged: onVersionChanged ?? (_) {},
          searchMode: searchMode,
          onSearchModeChanged: onSearchModeChanged ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  group('Version picker (Req 12.1)', () {
    testWidgets('lists every registry version', (tester) async {
      await tester.pumpWidget(
          buildTestWidget(availableVersions: registryVersions));
      await tester.pumpAndSettle();
      await expandCard(tester);

      // The picker label is present.
      expect(find.text(enL10n.minecraftVersionLabel), findsWidgets);

      // The dropdown is present and offers every registry version by release.
      expect(find.byType(DropdownButton<MinecraftVersion>), findsOneWidget);
      expect(registryVersions, isNotEmpty);
      // Open the dropdown menu to reveal the items.
      await tester.tap(find.byType(DropdownButton<MinecraftVersion>));
      await tester.pumpAndSettle();
      for (final version in registryVersions) {
        expect(find.text(version.release), findsWidgets,
            reason: 'picker should list ${version.release}');
      }
    });

    testWidgets('selecting a version calls onVersionChanged', (tester) async {
      MinecraftVersion? picked;
      await tester.pumpWidget(buildTestWidget(
        availableVersions: registryVersions,
        onVersionChanged: (v) => picked = v,
      ));
      await tester.pumpAndSettle();
      await expandCard(tester);

      await tester.tap(find.byType(DropdownButton<MinecraftVersion>));
      await tester.pumpAndSettle();
      final target = registryVersions.last;
      await tester.tap(find.text(target.release).last);
      await tester.pumpAndSettle();

      expect(picked, target);
    });

    testWidgets('picker is hidden when there are no versions', (tester) async {
      await tester.pumpWidget(buildTestWidget(availableVersions: const []));
      await tester.pumpAndSettle();
      await expandCard(tester);

      expect(find.byType(DropdownButton<MinecraftVersion>), findsNothing);
    });
  });

  group('Mode toggle (Req 12.2)', () {
    testWidgets('toggle is present with both options', (tester) async {
      await tester.pumpWidget(
          buildTestWidget(availableVersions: registryVersions));
      await tester.pumpAndSettle();
      await expandCard(tester);

      expect(find.byType(SegmentedButton<SearchMode>), findsOneWidget);
      expect(find.text(enL10n.searchModeEstimate), findsOneWidget);
      expect(find.text(enL10n.searchModeAccurate), findsOneWidget);
    });

    testWidgets('tapping Accurate calls onSearchModeChanged', (tester) async {
      SearchMode? mode;
      await tester.pumpWidget(buildTestWidget(
        availableVersions: registryVersions,
        searchMode: SearchMode.estimate,
        onSearchModeChanged: (m) => mode = m,
      ));
      await tester.pumpAndSettle();
      await expandCard(tester);

      await tester.tap(find.text(enL10n.searchModeAccurate));
      await tester.pumpAndSettle();

      expect(mode, SearchMode.accurate);
    });

    testWidgets('tapping Estimate calls onSearchModeChanged', (tester) async {
      SearchMode? mode;
      await tester.pumpWidget(buildTestWidget(
        availableVersions: registryVersions,
        searchMode: SearchMode.accurate,
        onSearchModeChanged: (m) => mode = m,
      ));
      await tester.pumpAndSettle();
      await expandCard(tester);

      await tester.tap(find.text(enL10n.searchModeEstimate));
      await tester.pumpAndSettle();

      expect(mode, SearchMode.estimate);
    });

    testWidgets('Accurate mode reveals its info box', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        availableVersions: registryVersions,
        searchMode: SearchMode.accurate,
      ));
      await tester.pumpAndSettle();
      await expandCard(tester);

      expect(find.text(enL10n.searchModeAccurateInfo), findsOneWidget);
    });
  });
}
