import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../utils/dash0_diagnostics.dart';

/// Hidden developer screen that shows the Dash0 SDK state and can test the
/// device network path. Opened by a long press on the title of the About
/// dialog.
class Dash0DiagnosticsScreen extends StatefulWidget {
  const Dash0DiagnosticsScreen({super.key, Dash0Diagnostics? diagnostics})
    : _diagnostics = diagnostics;

  final Dash0Diagnostics? _diagnostics;

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const Dash0DiagnosticsScreen()),
  );

  @override
  State<Dash0DiagnosticsScreen> createState() => _Dash0DiagnosticsScreenState();
}

class _Dash0DiagnosticsScreenState extends State<Dash0DiagnosticsScreen> {
  late final Dash0Diagnostics _d =
      widget._diagnostics ?? Dash0Diagnostics.instance;
  String? _eventResult;
  String? _connectionResult;
  bool _sendingEvent = false;
  bool _testingConnection = false;

  @override
  void initState() {
    super.initState();
    _d.refreshLive();
  }

  Future<void> _sendEvent() async {
    setState(() {
      _sendingEvent = true;
      _eventResult = null;
    });
    String result;
    try {
      await _d.sendTestEvent();
      result = 'Done at ${DateTime.now().toIso8601String()}';
    } catch (e) {
      result = '${e.runtimeType}: $e';
    }
    if (!mounted) return;
    setState(() {
      _d.refreshLive();
      _sendingEvent = false;
      _eventResult = result;
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _connectionResult = null;
    });
    final result = await _d.testConnection();
    if (!mounted) return;
    setState(() {
      _testingConnection = false;
      _connectionResult = result.toString();
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _d.buildReport()));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Report copied')));
  }

  @override
  Widget build(BuildContext context) {
    final configured = _d.endpointSet && _d.authTokenSet;
    return Scaffold(
      appBar: AppBar(title: const Text('Dash0 diagnostics')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!configured)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Telemetry: not configured'),
              ),
            SelectableText(
              _d.buildReport(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendingEvent ? null : _sendEvent,
              child: const Text('Send test event'),
            ),
            if (_sendingEvent) const LinearProgressIndicator(),
            if (_eventResult != null) SelectableText(_eventResult!),
            const Text(
              'Sends dash0.diagnostics.test through the SDK and flushes. '
              'Done only means the SDK accepted it. Failures show in the '
              'console when DASH0_SDK_DEBUG=true.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testingConnection ? null : _testConnection,
              child: const Text('Test connection'),
            ),
            if (_testingConnection) const LinearProgressIndicator(),
            if (_connectionResult != null) SelectableText(_connectionResult!),
            const Text(
              'Posts a log record to <endpoint>/v1/logs without the SDK. '
              '200 means network and token work. 401/403 means a bad token or '
              'dataset. An exception means the device cannot reach Dash0. '
              '200 here but no SDK data points to the SDK (for example gzip).',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _copy, child: const Text('Copy')),
            const Text(
              'Copies the report above. The token is masked.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'Meaning: init branch "initialized" with Dash0.isInitialized yes '
              'means the SDK started. "no endpoint or token" means the build '
              'has no OTLP config. "session sampled: no" means the SDK drops '
              'session data.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
