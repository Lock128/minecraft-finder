/// On-device diagnostics for the Dash0 SDK. Filled during SDK init in
/// main.dart and shown by `Dash0DiagnosticsScreen`. Never holds the full token
/// or the raw headers.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dash0_flutter_sdk/dash0_flutter_sdk.dart';
import 'package:http/http.dart' as http;

import 'dash0_config.dart';

/// Build-time switch (`--dart-define=DASH0_SDK_DEBUG=true`) that makes the SDK
/// print export warnings in release builds.
const bool dash0SdkDebug =
    String.fromEnvironment('DASH0_SDK_DEBUG', defaultValue: '') == 'true';

/// Masks a token for display: first 7 characters plus the length, for example
/// `auth_Ey…(len 37)`. Returns `(none)` for a null or empty token.
String maskToken(String? token) {
  if (token == null || token.isEmpty) return '(none)';
  final visible = token.length < 7 ? token.length : 7;
  return '${token.substring(0, visible)}…(len ${token.length})';
}

/// Result of [Dash0Diagnostics.testConnection].
class Dash0ConnectionResult {
  const Dash0ConnectionResult({this.statusCode, this.body, this.error});

  final int? statusCode;
  final String? body;
  final String? error;

  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;

  @override
  String toString() {
    if (error != null) return error!;
    final snippet = (body ?? '').trim();
    return 'HTTP $statusCode${snippet.isEmpty ? '' : ' $snippet'}';
  }
}

class Dash0Diagnostics {
  Dash0Diagnostics();

  /// The record filled by `_initializeOpenTelemetry`.
  static final Dash0Diagnostics instance = Dash0Diagnostics();

  bool initRan = false;
  bool endpointSet = false;
  bool authTokenSet = false;
  String? dataset;
  String? endpoint;
  String maskedToken = '(none)';
  String? environment;
  String? serviceName;
  String? serviceVersion;

  /// 'no endpoint or token', 'initialized' or 'init failed: `<error>`'.
  String? initBranch;
  String? initError;
  DateTime? timestamp;
  bool sdkDebug = dash0SdkDebug;
  String compression = 'none';
  List<String> instrumentations = const [];

  // Live values, refreshed by [refreshLive].
  bool sdkInitialized = false;
  String? sessionId;
  bool? sessionSampled;
  bool? clientEnabled;

  /// Records the configuration that init is about to use.
  void recordConfig({
    required String? endpoint,
    required String? authToken,
    required String? dataset,
    required String? environment,
    required String? serviceName,
    required String? serviceVersion,
    required Iterable<String> instrumentations,
    required String compression,
  }) {
    initRan = true;
    endpointSet = endpoint != null && endpoint.isNotEmpty;
    authTokenSet = authToken != null && authToken.isNotEmpty;
    this.endpoint = endpointSet ? endpoint : null;
    maskedToken = maskToken(authToken);
    this.dataset = dataset;
    this.environment = environment;
    this.serviceName = serviceName;
    this.serviceVersion = serviceVersion;
    this.instrumentations = instrumentations.toList()..sort();
    this.compression = compression;
    timestamp = DateTime.now();
  }

  void recordBranch(String branch, {Object? error}) {
    initBranch = branch;
    initError = error?.toString();
    timestamp = DateTime.now();
  }

  /// Reads the live SDK state.
  void refreshLive() {
    sdkInitialized = Dash0.isInitialized;
    sessionId = Dash0.sessionId;
    final client = Dash0.client;
    sessionSampled = client?.isSessionSampled;
    clientEnabled = client?.isEnabled;
  }

  /// Plain-text report. Contains the masked token only.
  String buildReport() {
    String yn(bool? v) => v == null ? 'n/a' : (v ? 'yes' : 'no');
    String s(String? v) => (v == null || v.isEmpty) ? '(not set)' : v;
    final lines = <String>[
      'Dash0 diagnostics',
      'init ran: ${yn(initRan)}',
      'init branch: ${s(initBranch)}',
      'init error: ${s(initError)}',
      'init time: ${timestamp?.toIso8601String() ?? '(not set)'}',
      'endpoint set: ${yn(endpointSet)}',
      'auth token set: ${yn(authTokenSet)}',
      'endpoint: ${s(endpoint)}',
      'token: $maskedToken',
      'dataset: ${s(dataset)}',
      'environment: ${s(environment)}',
      'service name: ${s(serviceName)}',
      'service version: ${s(serviceVersion)}',
      'compression: $compression',
      'instrumentations: ${instrumentations.isEmpty ? '(none)' : instrumentations.join(', ')}',
      'DASH0_SDK_DEBUG: ${yn(sdkDebug)}',
      'Dash0.isInitialized: ${yn(sdkInitialized)}',
      'session id: ${s(sessionId)}',
      'session sampled: ${yn(sessionSampled)}',
      'client enabled: ${yn(clientEnabled)}',
    ];
    return lines.join('\n');
  }

  /// Sends a custom event through the SDK and flushes it.
  Future<void> sendTestEvent() async {
    Dash0.sendEvent(
      'dash0.diagnostics.test',
      title: 'Dash0 diagnostics test event',
      attributes: {'diagnostics.sent_at': DateTime.now().toIso8601String()},
    );
    await Dash0.flush();
  }

  /// POSTs a minimal OTLP log record to `<endpoint>/v1/logs` using the
  /// compiled-in configuration, bypassing the SDK.
  Future<Dash0ConnectionResult> testConnection({
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    const rawEndpoint = String.fromEnvironment(
      'OTEL_EXPORTER_OTLP_ENDPOINT',
      defaultValue: '',
    );
    const rawHeaders = String.fromEnvironment(
      'OTEL_EXPORTER_OTLP_HEADERS',
      defaultValue: '',
    );
    return postTestLog(
      rawEndpoint: rawEndpoint,
      rawHeaders: rawHeaders,
      serviceName: serviceName ?? 'minecraft-finder',
      client: client,
      timeout: timeout,
    );
  }
}

/// Builds the minimal OTLP/JSON log payload used by the connection test.
Map<String, Object?> buildTestLogPayload(String serviceName) {
  final nanos = (DateTime.now().microsecondsSinceEpoch * 1000).toString();
  return {
    'resourceLogs': [
      {
        'resource': {
          'attributes': [
            {
              'key': 'service.name',
              'value': {'stringValue': '$serviceName-diagnostics'},
            },
          ],
        },
        'scopeLogs': [
          {
            'logRecords': [
              {
                'timeUnixNano': nanos,
                'observedTimeUnixNano': nanos,
                'severityNumber': 9,
                'severityText': 'INFO',
                'body': {'stringValue': 'diagnostics connection test'},
              },
            ],
          },
        ],
      },
    ],
  };
}

Future<Dash0ConnectionResult> postTestLog({
  required String rawEndpoint,
  required String rawHeaders,
  required String serviceName,
  http.Client? client,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final headers = parseOtlpHeaders(rawHeaders);
  final token = extractBearerToken(headers);
  if (rawEndpoint.isEmpty || token == null) {
    return const Dash0ConnectionResult(error: 'Not configured');
  }
  final dataset = extractDash0Dataset(headers);
  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient
        .post(
          Uri.parse('${normalizeOtlpEndpoint(rawEndpoint)}/v1/logs'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Dash0-Dataset': ?dataset,
          },
          body: jsonEncode(buildTestLogPayload(serviceName)),
        )
        .timeout(timeout);
    final body = response.body;
    return Dash0ConnectionResult(
      statusCode: response.statusCode,
      body: body.length > 200 ? body.substring(0, 200) : body,
    );
  } catch (e) {
    return Dash0ConnectionResult(error: '${e.runtimeType}: $e');
  } finally {
    if (client == null) httpClient.close();
  }
}
