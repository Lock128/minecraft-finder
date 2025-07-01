/// This file contains the tests that take screenshots of the app.
///
/// Run it with `flutter test --update-goldens` to generate the screenshots
/// or `flutter test` to compare the screenshots to the golden files.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_screenshot/golden_screenshot.dart';
import 'package:minecraft_finder/main.dart';

import 'package:flutter/rendering.dart';

void _resetPaintingDebugFlags() {
  debugPaintSizeEnabled = false;
  debugPaintBaselinesEnabled = false;
  debugRepaintRainbowEnabled = false;
  debugDisableClipLayers = false;
  debugDisablePhysicalShapeLayers = false;
  debugInvertOversizedImages = false;
  //debugAllowBannerOverride = false;
  debugDisableShadows = false;
  //debugCheckElevationsEnabled = false;
}

void printPaintingFlags() {
  print('debugPaintSizeEnabled=$debugPaintSizeEnabled');
  print('debugPaintBaselinesEnabled=$debugPaintBaselinesEnabled');
  print('debugRepaintRainbowEnabled=$debugRepaintRainbowEnabled');
  print('debugDisableClipLayers=$debugDisableClipLayers');
  print('debugDisablePhysicalShapeLayers=$debugDisablePhysicalShapeLayers');
  print('debugInvertOversizedImages=$debugInvertOversizedImages');
  print('debugAllowBannerOverride=$debugAllowBannerOverride');
  print('debugDisableShadows=$debugDisableShadows');
  print('debugCheckElevationsEnabled=$debugCheckElevationsEnabled');
}

void main() {
  setUp(() {
    _resetPaintingDebugFlags();
  });

  group('Screenshot:', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Set up proper golden file comparator for CI environments
    setUpAll(() {
      // This fixes the LocalFileComparator issue in CI environments
      if (goldenFileComparator is! LocalFileComparator) {
        // Use system temp directory which is writable in CI
        final tempDir =
            Directory.systemTemp.createTempSync('golden_screenshots');
        goldenFileComparator = LocalFileComparator(tempDir.uri);
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
    tearDown(() {
      // Reset all painting debug variables after each test
      debugDisableShadows = false;
      debugPaintSizeEnabled = false;
    });

    for (final goldenDevice in GoldenScreenshotDevices.values) {
      testGoldens('for ${goldenDevice.name}', (tester) async {
        addTearDown(() {
          _resetPaintingDebugFlags();
        });

        printPaintingFlags();

        final device = goldenDevice.device;

        // Store original view settings
        final originalSize = tester.view.physicalSize;
        final originalPixelRatio = tester.view.devicePixelRatio;

        try {
          // Set the device size directly on the tester
          tester.view.physicalSize = Size(
            device.resolution.width,
            device.resolution.height,
          );
          tester.view.devicePixelRatio = device.pixelRatio;

          // Pump the app directly without ScreenshotApp wrapper
          await tester.pumpWidget(child);

          // Wait for the app to settle and load
          await tester.pumpAndSettle(const Duration(seconds: 10));

          // Take the screenshot of the MaterialApp directly
          await expectLater(
            find.byType(MaterialApp).first,
            matchesGoldenFile(
                '${goldenFileName}_${goldenDevice.name}_${device.resolution.width.toInt()}x${device.resolution.height.toInt()}.png'),
          );
        } finally {
          // Reset view settings to original values
          tester.view.physicalSize = originalSize;
          tester.view.devicePixelRatio = originalPixelRatio;

          // Clear any painting debug variables that might have been set
          debugDisableShadows = false;
          debugPaintSizeEnabled = false;

          _resetPaintingDebugFlags();

          printPaintingFlags();

          // Force a pump to clear any cached painting state
          try {
            await tester.pump();
            await tester.pump();
          } catch (e) {
            // Ignore pump errors during cleanup
          }
        }
      });
    }
  });
}
