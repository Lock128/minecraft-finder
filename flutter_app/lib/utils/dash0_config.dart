/// Helpers that turn the OTEL_EXPORTER_OTLP_* build-time variables into the
/// values needed by the Dash0 Flutter SDK.
library;

import 'package:dash0_flutter_sdk/dash0_flutter_sdk.dart';
import 'package:flutter/foundation.dart';

/// Parses an `OTEL_EXPORTER_OTLP_HEADERS` value (`key1=value1,key2=value2`)
/// into a map. Entries without a key are ignored.
Map<String, String> parseOtlpHeaders(String raw) {
  final headers = <String, String>{};
  if (raw.isEmpty) return headers;
  for (final pair in raw.split(',')) {
    final eqIdx = pair.indexOf('=');
    if (eqIdx > 0) {
      headers[pair.substring(0, eqIdx).trim()] = pair
          .substring(eqIdx + 1)
          .trim();
    }
  }
  return headers;
}

/// Extracts the bearer token from an `Authorization` header (case
/// insensitive key). A missing `Bearer ` prefix is tolerated. Returns null when
/// there is no usable token.
String? extractBearerToken(Map<String, String> headers) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() != 'authorization') continue;
    var value = entry.value.trim();
    if (value.toLowerCase() == 'bearer') {
      value = '';
    } else if (value.toLowerCase().startsWith('bearer ')) {
      value = value.substring(7).trim();
    }
    return value.isEmpty ? null : value;
  }
  return null;
}

/// Returns the dataset from a `Dash0-Dataset` header, if any.
String? extractDash0Dataset(Map<String, String> headers) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == 'dash0-dataset' &&
        entry.value.trim().isNotEmpty) {
      return entry.value.trim();
    }
  }
  return null;
}

/// Normalizes an OTLP endpoint to the base URL expected by the SDK: removes
/// trailing slashes and a trailing `/v1/traces|logs|metrics` signal path.
String normalizeOtlpEndpoint(String endpoint) {
  var url = endpoint.trim();
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  for (final signal in const ['traces', 'logs', 'metrics']) {
    final suffix = '/v1/$signal';
    if (url.endsWith(suffix)) {
      url = url.substring(0, url.length - suffix.length);
      break;
    }
  }
  return url;
}

/// Parses a boolean build-time flag (`true`, `1`, `yes`, `on` and their
/// negatives, case insensitive). Returns [defaultValue] when [raw] is empty or
/// not recognized.
bool parseBoolFlag(String raw, {required bool defaultValue}) {
  switch (raw.trim().toLowerCase()) {
    case 'true':
    case '1':
    case 'yes':
    case 'on':
      return true;
    case 'false':
    case '0':
    case 'no':
    case 'off':
      return false;
    default:
      return defaultValue;
  }
}

/// True for user agents of headless browsers (`HeadlessChrome`, PhantomJS)
/// and common automation tools.
bool isAutomatedUserAgent(String? userAgent) {
  final ua = userAgent?.toLowerCase() ?? '';
  if (ua.isEmpty) return false;
  return const [
    'headlesschrome',
    'phantomjs',
    'playwright',
    'puppeteer',
    'selenium',
  ].any(ua.contains);
}

/// Whether telemetry is recorded in this browser. Automated browsers (end to
/// end tests, screenshot jobs, crawlers driving headless Chrome) start with an
/// empty storage every run, so each run is a new Dash0 session. They are
/// skipped unless [recordAutomatedFlag] (`DASH0_RECORD_AUTOMATED_BROWSERS`)
/// is true.
bool shouldRecordDash0Telemetry({
  required bool automatedBrowser,
  required String recordAutomatedFlag,
}) {
  if (!automatedBrowser) return true;
  return parseBoolFlag(recordAutomatedFlag, defaultValue: false);
}

/// Resolves the `deployment.environment.name` value from the
/// `DASH0_ENVIRONMENT` build-time variable. Returns the trimmed value, or
/// `development` in debug builds and null in release builds when it is empty.
String? resolveDash0Environment(String raw, {required bool isDebug}) {
  final value = raw.trim();
  if (value.isNotEmpty) return value;
  return isDebug ? 'development' : null;
}

/// The `deployment.environment.name` of this build.
String? currentDash0Environment() => resolveDash0Environment(
  const String.fromEnvironment('DASH0_ENVIRONMENT', defaultValue: ''),
  isDebug: kDebugMode,
);

/// Builds the `service.version` value `<version>+<buildNumber>`. Returns just
/// the version when the build number is empty and null when the version is
/// empty.
String? resolveDash0ServiceVersion(String? version, String? buildNumber) {
  final v = version?.trim() ?? '';
  if (v.isEmpty) return null;
  final b = buildNumber?.trim() ?? '';
  return b.isEmpty ? v : '$v+$b';
}

/// Service name reported to Dash0 (shown as the site name). Returns
/// [baseName] for production (null, empty, `production` or `prod`), otherwise
/// `<baseName>-<environment>`.
String resolveDash0ServiceName(String baseName, String? environment) {
  final env = environment?.trim() ?? '';
  final lower = env.toLowerCase();
  if (env.isEmpty || lower == 'production' || lower == 'prod') {
    return baseName;
  }
  return '$baseName-$env';
}

/// Instrumentations enabled for the app. `enabledInstrumentations` of the SDK
/// is an allow-list, so every wanted instrumentation must be listed. Session
/// replay, profiling and HTTP overrides are intentionally left out: the app
/// has no backend and handles user input such as world seeds.
const Set<Dash0Instrumentation> dash0Instrumentations = {
  Dash0Instrumentation.navigation,
  Dash0Instrumentation.error,
  Dash0Instrumentation.http,
  Dash0Instrumentation.lifecycle,
  Dash0Instrumentation.metrics,
  Dash0Instrumentation.vitals,
  Dash0Instrumentation.rageClicks,
};
