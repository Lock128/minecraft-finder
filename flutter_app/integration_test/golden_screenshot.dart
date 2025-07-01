import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Import for debug flags
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
    // ... other calls to _screenshotWidget
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
        // Store original view settings
        final originalSize = tester.view.physicalSize;
        final originalPixelRatio = tester.view.devicePixelRatio;

        // Store original painting debug values
        final originalDebugValues = {
          'debugPaintSizeEnabled': debugPaintSizeEnabled,
          'debugPaintBaselinesEnabled': debugPaintBaselinesEnabled,
          'debugRepaintRainbowEnabled': debugRepaintRainbowEnabled,
          'debugDisableClipLayers': debugDisableClipLayers,
          'debugDisablePhysicalShapeLayers': debugDisablePhysicalShapeLayers,
          'debugInvertOversizedImages': debugInvertOversizedImages,
          'debugDisableShadows': debugDisableShadows,
        };

        try {
          // Set the device size for the golden test
          final device = goldenDevice.device;
          tester.view.physicalSize = Size(
            device.resolution.width,
            device.resolution.height,
          );
          tester.view.devicePixelRatio = device.pixelRatio;

          // Pump the widget tree
          await tester.pumpWidget(MaterialApp(theme: theme, home: child));
          await tester.pumpAndSettle(const Duration(seconds: 10));

          // Perform the golden file comparison
          await expectLater(
            find.byType(MaterialApp).first,
            matchesGoldenFile(
                '${goldenFileName}_${goldenDevice.name}_${device.resolution.width.toInt()}x${device.resolution.height.toInt()}.png'),
          );
        } finally {
          // ALWAYS reset values in the finally block
          tester.view.physicalSize = originalSize;
          tester.view.devicePixelRatio = originalPixelRatio;

          // Reset all painting debug values to their original state
          debugPaintSizeEnabled = originalDebugValues['debugPaintSizeEnabled']!;
          debugPaintBaselinesEnabled =
              originalDebugValues['debugPaintBaselinesEnabled']!;
          debugRepaintRainbowEnabled =
              originalDebugValues['debugRepaintRainbowEnabled']!;
          debugDisableClipLayers =
              originalDebugValues['debugDisableClipLayers']!;
          debugDisablePhysicalShapeLayers =
              originalDebugValues['debugDisablePhysicalShapeLayers']!;
          debugInvertOversizedImages =
              originalDebugValues['debugInvertOversizedImages']!;
          debugDisableShadows = originalDebugValues['debugDisableShadows']!;
        }
      });
    }
  });
}
