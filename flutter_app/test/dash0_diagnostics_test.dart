import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gem_ore_struct_finder_mc/utils/dash0_diagnostics.dart';

void main() {
  test('maskToken shows 7 chars and the length', () {
    expect(
      maskToken('auth_EyABCDEFGHIJKLMNOPQRSTUVWXYZ12345678'),
      startsWith('auth_Ey…(len '),
    );
    expect(
      maskToken('auth_Ey1234567890123456789012345678901234'),
      'auth_Ey…(len 41)',
    );
    expect(maskToken(null), '(none)');
    expect(maskToken(''), '(none)');
    expect(maskToken('abc'), 'abc…(len 3)');
  });

  test('report never contains the full token', () {
    const token = 'auth_EySECRETSECRETSECRET';
    final d = Dash0Diagnostics()
      ..recordConfig(
        endpoint: 'https://ingress.example.com',
        authToken: token,
        dataset: 'ds',
        environment: 'production',
        serviceName: 'svc',
        serviceVersion: '1.0+2',
        instrumentations: ['http', 'error'],
        compression: 'gzip',
      )
      ..recordBranch('initialized');
    final report = d.buildReport();
    expect(report, isNot(contains('SECRETSECRET')));
    expect(report, contains('token: auth_Ey…(len ${token.length})'));
    expect(report, contains('init branch: initialized'));
    expect(report, contains('dataset: ds'));
    expect(report, contains('instrumentations: error, http'));
  });

  test('report for unconfigured state', () {
    final d = Dash0Diagnostics()..recordBranch('no endpoint or token');
    final report = d.buildReport();
    expect(report, contains('endpoint set: no'));
    expect(report, contains('auth token set: no'));
    expect(report, contains('token: (none)'));
  });

  test('postTestLog sends headers and reports status', () async {
    late http.Request seen;
    final client = MockClient((req) async {
      seen = req;
      return http.Response('ok', 200);
    });
    final r = await postTestLog(
      rawEndpoint: 'https://x.example.com/v1/logs/',
      rawHeaders: 'Authorization=Bearer tok,Dash0-Dataset=ds',
      serviceName: 'svc',
      client: client,
    );
    expect(r.isSuccess, isTrue);
    expect(seen.url.toString(), 'https://x.example.com/v1/logs');
    expect(seen.headers['Authorization'], 'Bearer tok');
    expect(seen.headers['Dash0-Dataset'], 'ds');
    expect(seen.body, contains('svc-diagnostics'));
  });

  test('postTestLog reports exceptions and missing config', () async {
    final r = await postTestLog(
      rawEndpoint: 'https://x.example.com',
      rawHeaders: 'Authorization=Bearer tok',
      serviceName: 'svc',
      client: MockClient((_) async => throw http.ClientException('boom')),
    );
    expect(r.error, contains('ClientException'));
    final none = await postTestLog(
      rawEndpoint: '',
      rawHeaders: '',
      serviceName: 'svc',
    );
    expect(none.error, 'Not configured');
  });
}
