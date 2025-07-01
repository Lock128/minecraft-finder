/// This file contains the tests that take screenshots of the app.
///
/// Run it with `flutter test` to generate the screenshots
/// Screenshots will be saved to the screenshots/ directory
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot/screenshot.dart';
import 'package:minecraft_finder/main.dart';

// Define device configurations for screenshots
class DeviceConfig {
  final String name;
  final Size size;
  final double pixelRatio;

  const DeviceConfig({
    required this.name,
    required this.size,
    required this.pixelRatio,
  });
}

const List<DeviceConfig> devices = [
  DeviceConfig(
    name: 'phone',
    size: Size(390, 844), // iPhone 12/13/14 size
    pixelRatio: 3.0,
  ),
  DeviceConfig(
    name: 'tablet',
    size: Size(820, 1180), // iPad size
    pixelRatio: 2.0,
  ),
  DeviceConfig(
    name: 'desktop',
    size: Size(1200, 800), // Desktop size
    pixelRatio: 1.0,
  ),
];

void main() {
  group('Screenshot Tests:', () {
    late ScreenshotController screenshotController;

    setUp(() {
      screenshotController = ScreenshotController();
    });

    // Create screenshots directory if it doesn't exist
    setUpAll(() async {
      final screenshotsDir =
          await Directory.systemTemp.createTemp('screenshots_');
    });

    final appTheme = ThemeData(
      primarySwatch: Colors.green,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.light,
      ),
    );

    // Test different app states
    for (final device in devices) {
      group('${device.name} screenshots', () {
        testWidgets('main screen', (tester) async {
          await _takeScreenshot(
            tester: tester,
            controller: screenshotController,
            device: device,
            theme: appTheme,
            fileName: '1_main_screen_${device.name}',
            child: const MinecraftOreFinderApp(),
          );
        }, timeout: const Timeout(Duration(minutes: 2)));

        testWidgets('search tab with form filled', (tester) async {
          await _takeScreenshot(
            tester: tester,
            controller: screenshotController,
            device: device,
            theme: appTheme,
            fileName: '2_search_tab_${device.name}',
            child: const MinecraftOreFinderApp(),
            setupAction: (tester) async {
              // Wait for app to load
              await tester.pumpAndSettle();

              // Fill in some form fields to make it look more realistic
              final seedField = find.byType(TextFormField).first;
              if (seedField.evaluate().isNotEmpty) {
                await tester.enterText(seedField, '8674308105921866736');
                await tester.pumpAndSettle();
              }
            },
          );
        }, timeout: const Timeout(Duration(minutes: 2)));

        testWidgets('results tab', (tester) async {
          await _takeScreenshot(
            tester: tester,
            controller: screenshotController,
            device: device,
            theme: appTheme,
            fileName: '3_results_tab_${device.name}',
            child: const MinecraftOreFinderApp(),
            setupAction: (tester) async {
              await tester.pumpAndSettle();

              // Try to navigate to results tab
              final resultsTabs = find.text('Results');
              if (resultsTabs.evaluate().isNotEmpty) {
                await tester.tap(resultsTabs);
                await tester.pumpAndSettle();
              }
            },
          );
        }, timeout: const Timeout(Duration(minutes: 2)));

        testWidgets('guide tab', (tester) async {
          await _takeScreenshot(
            tester: tester,
            controller: screenshotController,
            device: device,
            theme: appTheme,
            fileName: '4_guide_tab_${device.name}',
            child: const MinecraftOreFinderApp(),
            setupAction: (tester) async {
              await tester.pumpAndSettle();

              // Try to navigate to guide tab
              final guideTabs = find.text('Guide');
              if (guideTabs.evaluate().isNotEmpty) {
                await tester.tap(guideTabs);
                await tester.pumpAndSettle();
              }
            },
          );
        }, timeout: const Timeout(Duration(minutes: 2)));
      });
    }
  });
}

Future<void> _takeScreenshot({
  required WidgetTester tester,
  required ScreenshotController controller,
  required DeviceConfig device,
  required ThemeData theme,
  required String fileName,
  required Widget child,
  Future<void> Function(WidgetTester)? setupAction,
}) async {
  // Set device size
  await tester.binding.setSurfaceSize(device.size);
  tester.view.devicePixelRatio = device.pixelRatio;

  // Create the app wrapped in Screenshot widget
  final app = Screenshot(
    controller: controller,
    child: MaterialApp(
      theme: theme,
      home: child,
      debugShowCheckedModeBanner: false,
    ),
  );

  // Pump the widget
  await tester.pumpWidget(app);
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Run setup action if provided
  if (setupAction != null) {
    await setupAction(tester);
  }

  // Wait a bit more for any animations to complete
  await tester.pumpAndSettle(const Duration(seconds: 2));

  try {
    // Capture screenshot
    final Uint8List? imageBytes = await controller.capture(
      delay: const Duration(milliseconds: 500),
      pixelRatio: device.pixelRatio,
    );

    if (imageBytes != null) {
      // Save screenshot to file
      final file = File(
          'screenshots/${fileName}_${device.size.width.toInt()}x${device.size.height.toInt()}.png');
      await file.writeAsBytes(imageBytes);

      print('Screenshot saved: ${file.path}');
      print('Size: ${device.size.width.toInt()}x${device.size.height.toInt()}');
      print('Pixel ratio: ${device.pixelRatio}');
    } else {
      print('Failed to capture screenshot for $fileName');
    }
  } catch (e) {
    print('Error taking screenshot for $fileName: $e');
  }

  // Reset surface size
  await tester.binding.setSurfaceSize(null);
}
