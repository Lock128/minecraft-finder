import 'dart:async';

import 'package:dash0_flutter_sdk/dash0_flutter_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'l10n/localization_delegates.dart';
import 'providers/app_settings.dart';
import 'providers/favorites_provider.dart';
import 'providers/monetization_config.dart';
import 'providers/pro_status_provider.dart';
import 'providers/search_history_provider.dart';
import 'theme/gamer_theme.dart';
import 'utils/dash0_config.dart';
import 'utils/dash0_device.dart';
import 'widgets/ore_finder_screen.dart';

export 'widgets/ore_finder_screen.dart' show OreFinderScreen;

Future<void> main() async {
  // Binding, SDK init and runApp share one zone to avoid a zone mismatch.
  // The SDK installs the FlutterError and PlatformDispatcher handlers itself;
  // the zone callback only covers uncaught async errors.
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await _initializeOpenTelemetry();
      runApp(const GemOreStructFinderApp());
    },
    (error, stack) => Dash0.reportError(error, stackTrace: stack),
  );
}

/// Initializes the Dash0 SDK from `--dart-define` values. Does nothing when
/// the endpoint or the auth token is missing, so local and test builds send
/// no telemetry. Session replay, profiling, HTTP overrides and trace header
/// propagation are intentionally not enabled: the app has no backend and
/// handles user input such as world seeds.
Future<void> _initializeOpenTelemetry() async {
  try {
    const otlpEndpoint = String.fromEnvironment(
      'OTEL_EXPORTER_OTLP_ENDPOINT',
      defaultValue: '',
    );
    const otlpHeaders = String.fromEnvironment(
      'OTEL_EXPORTER_OTLP_HEADERS',
      defaultValue: '',
    );
    final headers = parseOtlpHeaders(otlpHeaders);
    final authToken = extractBearerToken(headers);
    if (otlpEndpoint.isEmpty || authToken == null) {
      debugPrint('Dash0: no OTLP endpoint or auth token, telemetry disabled');
      return;
    }

    final environment = currentDash0Environment();
    String? serviceVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      serviceVersion = resolveDash0ServiceVersion(
        info.version,
        info.buildNumber,
      );
    } catch (_) {
      // The version is optional.
    }

    await Dash0.init(
      Dash0Options(
        serviceName: resolveDash0ServiceName('minecraft-finder', environment),
        serviceVersion: serviceVersion,
        // Native apps have no browser user agent, so the SDK builds one.
        syntheticUserAgent: !kIsWeb,
        // Device model and OS version for the synthetic user agent.
        resourceAttributes: await loadDash0DeviceAttributes(),
        endpoint: Dash0Endpoint(
          url: normalizeOtlpEndpoint(otlpEndpoint),
          authToken: authToken,
          dataset: extractDash0Dataset(headers),
        ),
        debug: kDebugMode,
        environment: environment,
        enabledInstrumentations: dash0Instrumentations,
        compression: Dash0Compression.gzip,
      ),
    );
    debugPrint('Dash0: initialized, serviceVersion=$serviceVersion');
  } catch (e) {
    // Telemetry must never prevent the app from starting.
    debugPrint('Failed to initialize Dash0: $e');
  }
}

class GemOreStructFinderApp extends StatelessWidget {
  const GemOreStructFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => SearchHistoryProvider()),
        ChangeNotifierProvider(create: (_) => MonetizationConfig()),
        ChangeNotifierProxyProvider<MonetizationConfig, ProStatusProvider>(
          create: (context) => ProStatusProvider(
            monetizationEnabled:
                context.read<MonetizationConfig>().isEnabled,
          ),
          update: (_, monetization, proStatus) {
            proStatus!.updateMonetization(monetization.isEnabled);
            return proStatus;
          },
        ),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          return MaterialApp(
            title:
                'Gem, Ore & Struct Finder for MC - Find Diamonds, Gold, Netherite & More',
            debugShowCheckedModeBanner: false,
            navigatorObservers: [Dash0.navigatorObserver],
            themeMode: settings.themeMode,
            theme: GamerTheme.buildLight(),
            darkTheme: GamerTheme.buildDark(),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: settings.locale,
            home: OreFinderScreen(
              onThemeToggle: settings.toggleTheme,
              isDarkMode: settings.isDarkMode,
              onLocaleChanged: settings.setLocale,
              currentLocale: settings.locale,
            ),
          );
        },
      ),
    );
  }
}
