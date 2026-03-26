import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/l10n/app_localizations.dart';
import 'package:gem_ore_struct_finder_mc/main.dart';
import 'package:gem_ore_struct_finder_mc/models/bedwars_guide_data.dart';
import 'package:gem_ore_struct_finder_mc/widgets/bedwars_guide_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  /// **Validates: Requirements 3.2, 4.2, 5.2**
  ///
  /// Feature: bedwars-guide, Property 1: All guide sections have required fields
  ///
  /// For any skill tier, every guide section must have a non-empty title,
  /// a non-empty emoji, and a non-empty content list with at least one
  /// non-empty string.
  group('Property 1: All guide sections have required fields', () {
    test(
      'all guide sections have non-empty title, emoji, and content '
      'across 100 random tier selections',
      () {
        final random = Random(42);
        final tiers = SkillTier.values;

        for (var i = 0; i < 100; i++) {
          final tier = tiers[random.nextInt(tiers.length)];
          final sections = tier.sections;

          expect(sections, isNotEmpty,
              reason: '${tier.label} should have at least one section');

          for (final section in sections) {
            expect(section.title, isNotEmpty,
                reason:
                    '${tier.label} section title must be non-empty (iteration $i)');

            expect(section.emoji, isNotEmpty,
                reason:
                    '${tier.label} section emoji must be non-empty (iteration $i)');

            expect(section.content, isNotEmpty,
                reason:
                    '${tier.label} section "${section.title}" content list must be non-empty (iteration $i)');

            final hasNonEmptyContent =
                section.content.any((line) => line.isNotEmpty);
            expect(hasNonEmptyContent, isTrue,
                reason:
                    '${tier.label} section "${section.title}" must have at least one non-empty content string (iteration $i)');
          }
        }
      },
    );
  });

  /// **Validates: Requirements 2.3**
  ///
  /// Feature: bedwars-guide, Property 2: Tier selection displays correct content
  ///
  /// For any SkillTier value, the guide sections returned must exactly match
  /// the predefined static content list for that tier (same length, same
  /// titles, same content).
  group('Property 2: Tier selection displays correct content', () {
    /// Maps each tier to its expected static sections list.
    List<GuideSection> expectedSectionsForTier(SkillTier tier) {
      switch (tier) {
        case SkillTier.starters:
          return BedwarsGuideData.startersSections;
        case SkillTier.practitioners:
          return BedwarsGuideData.practitionersSections;
        case SkillTier.experts:
          return BedwarsGuideData.expertsSections;
      }
    }

    test(
      'tier.sections matches the predefined static content list '
      'across 100 random tier selections',
      () {
        final random = Random(99);
        final tiers = SkillTier.values;

        for (var i = 0; i < 100; i++) {
          final tier = tiers[random.nextInt(tiers.length)];
          final sections = tier.sections;
          final expected = expectedSectionsForTier(tier);

          expect(sections.length, equals(expected.length),
              reason:
                  '${tier.label} should have ${expected.length} sections (iteration $i)');

          for (var j = 0; j < sections.length; j++) {
            expect(sections[j].title, equals(expected[j].title),
                reason:
                    '${tier.label} section $j title mismatch (iteration $i)');

            expect(sections[j].emoji, equals(expected[j].emoji),
                reason:
                    '${tier.label} section $j emoji mismatch (iteration $i)');

            expect(sections[j].accentColor, equals(expected[j].accentColor),
                reason:
                    '${tier.label} section $j accentColor mismatch (iteration $i)');

            expect(sections[j].content.length,
                equals(expected[j].content.length),
                reason:
                    '${tier.label} section $j content length mismatch (iteration $i)');

            for (var k = 0; k < sections[j].content.length; k++) {
              expect(sections[j].content[k], equals(expected[j].content[k]),
                  reason:
                      '${tier.label} section $j content[$k] mismatch (iteration $i)');
            }
          }
        }
      },
    );
  });

  /// **Validates: Requirements 1.1, 1.2**
  ///
  /// Verify the Bedwars tab appears in the TabBar with the correct icon
  /// (Icons.sports_esports) and "Bedwars" label.
  group('Widget: Bedwars tab presence in TabBar', () {
    testWidgets('TabBar contains Bedwars tab with correct icon and label',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: OreFinderScreen(
            onThemeToggle: () {},
            isDarkMode: false,
            onLocaleChanged: (_) {},
            currentLocale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the "Bedwars" label text exists in the TabBar
      expect(find.text('Bedwars'), findsOneWidget);

      // Verify the sports_esports icon exists in the TabBar
      expect(find.byIcon(Icons.sports_esports), findsOneWidget);
    });
  });

  /// **Validates: Requirement 1.3**
  ///
  /// Verify tapping the Bedwars tab displays the guide content area.
  group('Widget: Bedwars tab navigation', () {
    testWidgets('tapping Bedwars tab displays guide content',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: OreFinderScreen(
            onThemeToggle: () {},
            isDarkMode: false,
            onLocaleChanged: (_) {},
            currentLocale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Bedwars tab
      await tester.tap(find.text('Bedwars'));
      await tester.pumpAndSettle();

      // Verify the tier selector labels are visible (guide content area)
      expect(find.text('Starters'), findsOneWidget);
      expect(find.text('Practitioners'), findsOneWidget);
      expect(find.text('Experts'), findsOneWidget);

      // Verify the default Starters tier content is displayed
      // The first section title for Starters is "Game Objective & Rules"
      expect(find.text('Game Objective & Rules'), findsOneWidget);
    });
  });

  /// **Validates: Requirements 2.1, 2.4, 3.1, 4.1, 5.1, 6.1**
  ///
  /// Unit tests for tier selector rendering, default selection, tier content,
  /// and dark/light mode builds.
  group('Widget: Tier selector and content', () {
    Widget buildBedwarsGuideTab({bool isDarkMode = false}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.ltr,
            child: BedwarsGuideTab(isDarkMode: isDarkMode),
          ),
        ),
      );
    }

    testWidgets('all three tier options are displayed',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildBedwarsGuideTab());
      await tester.pumpAndSettle();

      expect(find.text('Starters'), findsOneWidget);
      expect(find.text('Practitioners'), findsOneWidget);
      expect(find.text('Experts'), findsOneWidget);
    });

    testWidgets('Starters is selected by default on first navigation',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildBedwarsGuideTab());
      await tester.pumpAndSettle();

      // Starters content should be visible by default
      for (final section in BedwarsGuideData.startersSections) {
        expect(find.text(section.title), findsOneWidget);
      }
    });

    testWidgets('Starters tier contains the correct 5 topic sections',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildBedwarsGuideTab());
      await tester.pumpAndSettle();

      const expectedTitles = [
        'Game Objective & Rules',
        'Basic Resource Gathering',
        'Purchasing Essential Items',
        'Basic Bed Defense',
        'Basic Combat Tips',
      ];
      for (final title in expectedTitles) {
        expect(find.text(title), findsOneWidget);
      }
    });

    testWidgets('Practitioners tier contains the correct 5 topic sections',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildBedwarsGuideTab());
      await tester.pumpAndSettle();

      // Tap Practitioners
      await tester.tap(find.text('Practitioners'));
      await tester.pumpAndSettle();

      const expectedTitles = [
        'Efficient Resource Management & Upgrades',
        'Intermediate Bed Defense',
        'Team Coordination Strategies',
        'Bridge-Building Techniques',
        'Mid-Game Combat Tactics',
      ];
      for (final title in expectedTitles) {
        expect(find.text(title), findsOneWidget);
      }
    });

    testWidgets('Experts tier contains the correct 5 topic sections',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildBedwarsGuideTab());
      await tester.pumpAndSettle();

      // Tap Experts
      await tester.tap(find.text('Experts'));
      await tester.pumpAndSettle();

      const expectedTitles = [
        'Advanced PvP Combat',
        'Speed-Bridging & Advanced Movement',
        'Rush Strategies & Timing',
        'Endgame Tactics & Resource Prioritization',
        'Counter-Strategies Against Common Plays',
      ];
      for (final title in expectedTitles) {
        expect(find.text(title), findsOneWidget);
      }
    });

    testWidgets('widget builds without errors in dark mode',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildBedwarsGuideTab(isDarkMode: true));
      await tester.pumpAndSettle();

      // Verify the widget rendered successfully with tier selector visible
      expect(find.text('Starters'), findsOneWidget);
      expect(find.text('Practitioners'), findsOneWidget);
      expect(find.text('Experts'), findsOneWidget);
    });

    testWidgets('widget builds without errors in light mode',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildBedwarsGuideTab(isDarkMode: false));
      await tester.pumpAndSettle();

      // Verify the widget rendered successfully with tier selector visible
      expect(find.text('Starters'), findsOneWidget);
      expect(find.text('Practitioners'), findsOneWidget);
      expect(find.text('Experts'), findsOneWidget);
    });
  });
}
