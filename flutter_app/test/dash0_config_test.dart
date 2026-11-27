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

  group('resolveDash0ServiceVersion', () {
    test('joins version and build number', () {
      expect(resolveDash0ServiceVersion('1.2.3', '45'), '1.2.3+45');
    });
    test('omits an empty build number', () {
      expect(resolveDash0ServiceVersion(' 1.2.3 ', ''), '1.2.3');
      expect(resolveDash0ServiceVersion('1.2.3', null), '1.2.3');
    });
    test('returns null without a version', () {
      expect(resolveDash0ServiceVersion('', '45'), isNull);
      expect(resolveDash0ServiceVersion(null, null), isNull);
    });

    test('isAutomatedUserAgent matches headless and automation agents', () {
      expect(
        isAutomatedUserAgent(
          'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) HeadlessChrome/159.0.8154.6 Safari/537.36',
        ),
        isTrue,
      );
      expect(isAutomatedUserAgent('Mozilla/5.0 PhantomJS/2.1.1'), isTrue);
      expect(
        isAutomatedUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36',
        ),
        isFalse,
      );
      expect(isAutomatedUserAgent(''), isFalse);
      expect(isAutomatedUserAgent(null), isFalse);
    });

    test('shouldRecordDash0Telemetry skips automated browsers by default', () {
      expect(
        shouldRecordDash0Telemetry(
          automatedBrowser: false,
          recordAutomatedFlag: '',
        ),
        isTrue,
      );
      expect(
        shouldRecordDash0Telemetry(
          automatedBrowser: true,
          recordAutomatedFlag: '',
        ),
        isFalse,
      );
      expect(
        shouldRecordDash0Telemetry(
          automatedBrowser: true,
          recordAutomatedFlag: 'true',
        ),
        isTrue,
      );
    });

    test('parseBoolFlag parses flags and falls back to the default', () {
      expect(parseBoolFlag('TRUE', defaultValue: false), isTrue);
      expect(parseBoolFlag('off', defaultValue: true), isFalse);
      expect(parseBoolFlag('', defaultValue: true), isTrue);
      expect(parseBoolFlag('maybe', defaultValue: false), isFalse);
    });
  });
}
