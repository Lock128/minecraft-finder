import 'package:dash0_flutter_sdk/dash0_flutter_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_ore_struct_finder_mc/utils/dash0_config.dart';

void main() {
  group('Dash0 config helpers', () {
    test('parseOtlpHeaders parses comma separated pairs', () {
      final headers = parseOtlpHeaders(
        'Authorization=Bearer auth_abc=, Dash0-Dataset = prod ,bad,=x',
      );
      expect(headers, {
        'Authorization': 'Bearer auth_abc=',
        'Dash0-Dataset': 'prod',
      });
      expect(parseOtlpHeaders(''), isEmpty);
    });

    test('extractBearerToken handles prefix and case', () {
      expect(extractBearerToken({'authorization': 'Bearer auth_1'}), 'auth_1');
      expect(extractBearerToken({'Authorization': 'auth_2'}), 'auth_2');
      expect(extractBearerToken({'Authorization': 'Bearer '}), isNull);
      expect(extractBearerToken({'X': 'y'}), isNull);
    });

    test('extractDash0Dataset reads the dataset header', () {
      expect(extractDash0Dataset({'dash0-dataset': 'dev'}), 'dev');
      expect(extractDash0Dataset({'a': 'b'}), isNull);
    });

    test('normalizeOtlpEndpoint strips signal paths and slashes', () {
      expect(
        normalizeOtlpEndpoint('https://ingress.dash0.com/v1/traces/'),
        'https://ingress.dash0.com',
      );
      expect(
        normalizeOtlpEndpoint('https://ingress.dash0.com:4318'),
        'https://ingress.dash0.com:4318',
      );
    });
  });

  group('Dash0 feature config', () {
    test('dash0Instrumentations keeps opt-ins out', () {
      expect(
        dash0Instrumentations,
        containsAll([
          Dash0Instrumentation.navigation,
          Dash0Instrumentation.error,
          Dash0Instrumentation.http,
          Dash0Instrumentation.lifecycle,
          Dash0Instrumentation.metrics,
          Dash0Instrumentation.vitals,
          Dash0Instrumentation.rageClicks,
        ]),
      );
      expect(
        dash0Instrumentations,
        isNot(contains(Dash0Instrumentation.httpOverrides)),
      );
      expect(
        dash0Instrumentations,
        isNot(contains(Dash0Instrumentation.sessionReplay)),
      );
      expect(
        dash0Instrumentations,
        isNot(contains(Dash0Instrumentation.profiling)),
      );
    });

    test('resolveDash0Environment returns the trimmed value when set', () {
      expect(resolveDash0Environment(' beta ', isDebug: false), 'beta');
      expect(
        resolveDash0Environment('production', isDebug: true),
        'production',
      );
    });

    test('resolveDash0Environment falls back by build mode when empty', () {
      expect(resolveDash0Environment('', isDebug: true), 'development');
      expect(resolveDash0Environment('  ', isDebug: false), isNull);
    });
  });

  group('resolveDash0ServiceName', () {
    test('appends the environment for non-production', () {
      expect(
        resolveDash0ServiceName('minecraft-finder', 'sandbox'),
        'minecraft-finder-sandbox',
      );
      expect(
        resolveDash0ServiceName('minecraft-finder', 'billing'),
        'minecraft-finder-billing',
      );
    });

    test('keeps the base name for production, null and empty', () {
      for (final env in ['production', 'prod', 'Production', null, '', '  ']) {
        expect(
          resolveDash0ServiceName('minecraft-finder', env),
          'minecraft-finder',
        );
      }
    });
  });

  group('currentDash0Environment', () {
    test('falls back to the debug default when no define is set', () {
      // Tests run in debug mode without DASH0_ENVIRONMENT.
      expect(currentDash0Environment(), 'development');
    });
  });
}
