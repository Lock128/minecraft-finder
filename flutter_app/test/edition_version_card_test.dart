// Feature: edition-version-selection
// Widget tests for EditionVersionCard
//
// Validates: Requirements 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4,
//            7.1, 7.2, 7.3, 7.4

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/models/game_random.dart';
import 'package:gem_ore_struct_finder_mc/widgets/edition_version_card.dart';

/// Helper to wrap EditionVersionCard in a MaterialApp for testing.
Widget buildTestWidget({
  MinecraftEdition edition = MinecraftEdition.java,
  VersionEra versionEra = VersionEra.modern,
  ValueChanged<MinecraftEdition>? onEditionChanged,
  ValueChanged<VersionEra>? onVersionEraChanged,
  bool isDarkMode = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: EditionVersionCard(
          selectedEdition: edition,
          selectedVersionEra: versionEra,
          onEditionChanged: onEditionChanged ?? (_) {},
          onVersionEraChanged: onVersionEraChanged ?? (_) {},
          isDarkMode: isDarkMode,
        ),
      ),
    ),
  );
}

void main() {
  group('EditionVersionCard - default selections', () {
    // Validates: Requirement 1.4 (default Java), 2.4 (default Modern)
    testWidgets('renders with Java and Modern selected by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Both segment labels should be present
      expect(find.text('Java Edition'), findsOneWidget);
      expect(find.text('Bedrock Edition'), findsOneWidget);
      expect(find.text('Pre-1.18 (Legacy)'), findsOneWidget);
      expect(find.text('1.18+ (Modern)'), findsOneWidget);
    });
  });

  group('EditionVersionCard - segment labels and header', () {
    // Validates: Requirement 1.1, 2.1, 9.4
    testWidgets('displays section header with emoji and title',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('🎮'), findsOneWidget);
      expect(find.text('Edition & Version'), findsOneWidget);
    });

    // Validates: Requirement 1.1
    testWidgets('edition segmented button has two segments',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Two SegmentedButton widgets: one for edition, one for version
      expect(find.byType(SegmentedButton<MinecraftEdition>), findsOneWidget);
      expect(find.byType(SegmentedButton<VersionEra>), findsOneWidget);
    });
  });

  group('EditionVersionCard - edition selection callbacks', () {
    // Validates: Requirement 1.2, 1.3
    testWidgets('tapping Bedrock Edition triggers onEditionChanged',
        (WidgetTester tester) async {
      MinecraftEdition? changedEdition;

      await tester.pumpWidget(buildTestWidget(
        edition: MinecraftEdition.java,
        onEditionChanged: (edition) {
          changedEdition = edition;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bedrock Edition'));
      await tester.pumpAndSettle();

      expect(changedEdition, MinecraftEdition.bedrock);
    });

    testWidgets('tapping Java Edition triggers onEditionChanged',
        (WidgetTester tester) async {
      MinecraftEdition? changedEdition;

      await tester.pumpWidget(buildTestWidget(
        edition: MinecraftEdition.bedrock,
        onEditionChanged: (edition) {
          changedEdition = edition;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Java Edition'));
      await tester.pumpAndSettle();

      expect(changedEdition, MinecraftEdition.java);
    });
  });

  group('EditionVersionCard - version era selection callbacks', () {
    // Validates: Requirement 2.2, 2.3
    testWidgets('tapping Legacy triggers onVersionEraChanged',
        (WidgetTester tester) async {
      VersionEra? changedEra;

      await tester.pumpWidget(buildTestWidget(
        versionEra: VersionEra.modern,
        onVersionEraChanged: (era) {
          changedEra = era;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pre-1.18 (Legacy)'));
      await tester.pumpAndSettle();

      expect(changedEra, VersionEra.legacy);
    });

    testWidgets('tapping Modern triggers onVersionEraChanged',
        (WidgetTester tester) async {
      VersionEra? changedEra;

      await tester.pumpWidget(buildTestWidget(
        versionEra: VersionEra.legacy,
        onVersionEraChanged: (era) {
          changedEra = era;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('1.18+ (Modern)'));
      await tester.pumpAndSettle();

      expect(changedEra, VersionEra.modern);
    });
  });

  group('EditionVersionCard - info box visibility', () {
    // Validates: Requirement 7.4
    testWidgets('Java + Modern shows no info boxes',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        edition: MinecraftEdition.java,
        versionEra: VersionEra.modern,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    // Validates: Requirement 7.1
    testWidgets('Bedrock + Modern shows Bedrock info box only',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        edition: MinecraftEdition.bedrock,
        versionEra: VersionEra.modern,
      ));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Bedrock ore prediction accuracy is approximate'),
        findsOneWidget,
      );
      // Legacy info box should NOT be present
      expect(
        find.textContaining('Legacy ore placement uses uniform distribution'),
        findsNothing,
      );
    });

    // Validates: Requirement 7.2
    testWidgets('Java + Legacy shows Legacy info box only',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        edition: MinecraftEdition.java,
        versionEra: VersionEra.legacy,
      ));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Legacy ore placement uses uniform distribution'),
        findsOneWidget,
      );
      // Bedrock info box should NOT be present
      expect(
        find.textContaining('Bedrock ore prediction accuracy is approximate'),
        findsNothing,
      );
    });

    // Validates: Requirement 7.1, 7.2
    testWidgets('Bedrock + Legacy shows both info boxes',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        edition: MinecraftEdition.bedrock,
        versionEra: VersionEra.legacy,
      ));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Bedrock ore prediction accuracy is approximate'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Legacy ore placement uses uniform distribution'),
        findsOneWidget,
      );
    });

    // Validates: Requirement 7.3
    testWidgets('info boxes use info_outline icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        edition: MinecraftEdition.bedrock,
        versionEra: VersionEra.legacy,
      ));
      await tester.pumpAndSettle();

      // Two info boxes → two info_outline icons
      expect(find.byIcon(Icons.info_outline), findsNWidgets(2));
    });
  });

  group('EditionVersionCard - dark mode and light mode rendering', () {
    // Validates: Requirement 9.2 (dark mode)
    testWidgets('renders in dark mode without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        isDarkMode: true,
        edition: MinecraftEdition.bedrock,
        versionEra: VersionEra.legacy,
      ));
      await tester.pumpAndSettle();

      // Widget should render all elements in dark mode
      expect(find.text('Java Edition'), findsOneWidget);
      expect(find.text('Bedrock Edition'), findsOneWidget);
      expect(find.text('Pre-1.18 (Legacy)'), findsOneWidget);
      expect(find.text('1.18+ (Modern)'), findsOneWidget);
      expect(find.text('Edition & Version'), findsOneWidget);
      expect(
        find.textContaining('Bedrock ore prediction accuracy is approximate'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Legacy ore placement uses uniform distribution'),
        findsOneWidget,
      );
    });

    // Validates: Requirement 9.2 (light mode)
    testWidgets('renders in light mode without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        isDarkMode: false,
        edition: MinecraftEdition.bedrock,
        versionEra: VersionEra.legacy,
      ));
      await tester.pumpAndSettle();

      // Widget should render all elements in light mode
      expect(find.text('Java Edition'), findsOneWidget);
      expect(find.text('Bedrock Edition'), findsOneWidget);
      expect(find.text('Pre-1.18 (Legacy)'), findsOneWidget);
      expect(find.text('1.18+ (Modern)'), findsOneWidget);
      expect(find.text('Edition & Version'), findsOneWidget);
    });
  });
}
