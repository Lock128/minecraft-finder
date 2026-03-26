// Feature: multi-language-support, Property 4: Parameterized string interpolation
// Validates: Requirements 5.2
//
// For any parameterized translation string and for any valid parameter values,
// the formatted output should contain the string representation of each
// parameter value.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Property 4: Parameterized string interpolation', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    const supportedLocales = ['en', 'de', 'es', 'ja', 'fr'];

    for (final localeCode in supportedLocales) {
      testWidgets(
        '100 random iterations: parameterized strings contain values for "$localeCode"',
        (WidgetTester tester) async {
          late AppLocalizations l10n;

          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale(localeCode),
              home: Builder(
                builder: (context) {
                  l10n = AppLocalizations.of(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
          await tester.pumpAndSettle();

          final random = Random(42);

          for (int i = 0; i < 100; i++) {
            final total = random.nextInt(10000);
            final oreCount = random.nextInt(total + 1);
            final structureCount = total - oreCount;

            // resultsCount(int total, int oreCount, int structureCount)
            final resultsOutput =
                l10n.resultsCount(total, oreCount, structureCount);
            expect(resultsOutput, contains('$total'),
                reason:
                    'Iteration $i, locale $localeCode: resultsCount should contain total "$total"');
            expect(resultsOutput, contains('$oreCount'),
                reason:
                    'Iteration $i, locale $localeCode: resultsCount should contain oreCount "$oreCount"');
            expect(resultsOutput, contains('$structureCount'),
                reason:
                    'Iteration $i, locale $localeCode: resultsCount should contain structureCount "$structureCount"');

            // structuresSelected(int count)
            final count = random.nextInt(500);
            final structuresOutput = l10n.structuresSelected(count);
            expect(structuresOutput, contains('$count'),
                reason:
                    'Iteration $i, locale $localeCode: structuresSelected should contain count "$count"');

            // copiedCoordinates(String coords)
            final x = random.nextInt(10000) - 5000;
            final y = random.nextInt(384) - 64;
            final z = random.nextInt(10000) - 5000;
            final coords = '$x $y $z';
            final copiedOutput = l10n.copiedCoordinates(coords);
            expect(copiedOutput, contains(coords),
                reason:
                    'Iteration $i, locale $localeCode: copiedCoordinates should contain coords "$coords"');

            // errorGeneric(String message)
            final msg = 'TestError_${random.nextInt(99999)}';
            final errorOutput = l10n.errorGeneric(msg);
            expect(errorOutput, contains(msg),
                reason:
                    'Iteration $i, locale $localeCode: errorGeneric should contain message "$msg"');

            // chunkLabel(int chunkX, int chunkZ)
            final chunkX = random.nextInt(1000) - 500;
            final chunkZ = random.nextInt(1000) - 500;
            final chunkOutput = l10n.chunkLabel(chunkX, chunkZ);
            expect(chunkOutput, contains('$chunkX'),
                reason:
                    'Iteration $i, locale $localeCode: chunkLabel should contain chunkX "$chunkX"');
            expect(chunkOutput, contains('$chunkZ'),
                reason:
                    'Iteration $i, locale $localeCode: chunkLabel should contain chunkZ "$chunkZ"');

            // probabilityLabel(String percent)
            final percent =
                (random.nextDouble() * 100).toStringAsFixed(1);
            final probOutput = l10n.probabilityLabel(percent);
            expect(probOutput, contains(percent),
                reason:
                    'Iteration $i, locale $localeCode: probabilityLabel should contain percent "$percent"');

            // biomeLabel(String biome)
            final biome = 'Biome_${random.nextInt(99999)}';
            final biomeOutput = l10n.biomeLabel(biome);
            expect(biomeOutput, contains(biome),
                reason:
                    'Iteration $i, locale $localeCode: biomeLabel should contain biome "$biome"');
          }
        },
      );
    }
  });
}
