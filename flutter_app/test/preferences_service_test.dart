import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gem_ore_struct_finder_mc/utils/preferences_service.dart';

void main() {
  group('PreferencesService', () {
    setUp(() {
      // Initialize SharedPreferences with empty values for testing
      SharedPreferences.setMockInitialValues({});
    });

    group('Seed preferences', () {
      test('should return default seed when no seed is saved', () async {
        final seed = await PreferencesService.getLastSeed();
        expect(seed, '8674308105921866736');
      });

      test('should save and retrieve seed correctly', () async {
        const testSeed = '123456789';

        await PreferencesService.saveLastSeed(testSeed);
        final retrievedSeed = await PreferencesService.getLastSeed();

        expect(retrievedSeed, testSeed);
      });

      test('should not save empty seed', () async {
        const originalSeed = '987654321';

        // Save a valid seed first
        await PreferencesService.saveLastSeed(originalSeed);

        // Try to save empty seed
        await PreferencesService.saveLastSeed('');

        // Should still return the original seed
        final retrievedSeed = await PreferencesService.getLastSeed();
        expect(retrievedSeed, originalSeed);
      });
    });

    group('Coordinate preferences', () {
      test('should return default coordinates when none are saved', () async {
        final x = await PreferencesService.getLastX();
        final y = await PreferencesService.getLastY();
        final z = await PreferencesService.getLastZ();

        expect(x, '0');
        expect(y, '-59');
        expect(z, '0');
      });

      test('should save and retrieve coordinates correctly', () async {
        const testX = '100';
        const testY = '64';
        const testZ = '-200';

        await PreferencesService.saveLastX(testX);
        await PreferencesService.saveLastY(testY);
        await PreferencesService.saveLastZ(testZ);

        final retrievedX = await PreferencesService.getLastX();
        final retrievedY = await PreferencesService.getLastY();
        final retrievedZ = await PreferencesService.getLastZ();

        expect(retrievedX, testX);
        expect(retrievedY, testY);
        expect(retrievedZ, testZ);
      });
    });

    group('Radius preferences', () {
      test('should return default radius when none is saved', () async {
        final radius = await PreferencesService.getLastRadius();
        expect(radius, '50');
      });

      test('should save and retrieve radius correctly', () async {
        const testRadius = '100';

        await PreferencesService.saveLastRadius(testRadius);
        final retrievedRadius = await PreferencesService.getLastRadius();

        expect(retrievedRadius, testRadius);
      });
    });

    group('All search parameters', () {
      test('should load all search parameters at once', () async {
        // Save some test values
        await PreferencesService.saveLastSeed('999888777');
        await PreferencesService.saveLastX('50');
        await PreferencesService.saveLastY('32');
        await PreferencesService.saveLastZ('-75');
        await PreferencesService.saveLastRadius('75');

        final params = await PreferencesService.getAllSearchParams();

        expect(params['seed'], '999888777');
        expect(params['x'], '50');
        expect(params['y'], '32');
        expect(params['z'], '-75');
        expect(params['radius'], '75');
      });

      test('should return defaults when no parameters are saved', () async {
        final params = await PreferencesService.getAllSearchParams();

        expect(params['seed'], '8674308105921866736');
        expect(params['x'], '0');
        expect(params['y'], '-59');
        expect(params['z'], '0');
        expect(params['radius'], '50');
      });
    });
  });
}
