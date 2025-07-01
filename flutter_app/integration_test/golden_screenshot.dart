/// This file contains the tests that take screenshots of the app.
///
/// Run it with `flutter test --update-goldens` to generate the screenshots
/// or `flutter test` to compare the screenshots to the golden files.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_screenshot/golden_screenshot.dart';
import 'package:minecraft_finder/main.dart';

void main() {
  group('Screenshot:', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Set up proper golden file comparator for CI environments
    setUpAll(() {
      // This fixes the LocalFileComparator issue in CI environments
      if (goldenFileComparator is! LocalFileComparator) {
        goldenFileComparator =
            LocalFileComparator(Uri.parse('integration_test/'));
      }
    });

    final appTheme = ThemeData(
      primarySwatch: Colors.green,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.light,
      ),
    );

    _screenshotWidget(
      theme: appTheme,
      goldenFileName: '1_main_screen',
      child: const MinecraftOreFinderApp(),
    );

    _screenshotWidget(
      theme: appTheme,
      goldenFileName: '2_search_tab',
      child: const MinecraftOreFinderApp(),
    );

    _screenshotWidget(
      theme: appTheme,
      goldenFileName: '3_results_tab',
      child: const MinecraftOreFinderApp(),
    );

    _screenshotWidget(
      theme: appTheme,
      goldenFileName: '4_guide_tab',
      child: const MinecraftOreFinderApp(),
    );
  });
}

void _screenshotWidget({
  ThemeData? theme,
  required String goldenFileName,
  required Widget child,
}) {
  group(goldenFileName, () {
    for (final goldenDevice in GoldenScreenshotDevices.values) {
      testGoldens('for ${goldenDevice.name}', (tester) async {
        final device = goldenDevice.device;
        final widget = ScreenshotApp(
          theme: theme,
          device: device,
          child: child,
        );

        await tester.pumpWidget(widget);

        // Precache the images and fonts so they're ready for the screenshot
        await tester.precacheImagesInWidgetTree();
        await tester.precacheTopbarImages();
        await tester.loadFonts();

        // Pump the widget for a second to ensure animations are complete
        await tester.pumpFrames(widget, const Duration(seconds: 1));

        // Take the screenshot and compare it to the golden file
        await tester.expectScreenshot(device, goldenFileName);
      });
    }
  });
}
