# OpenTelemetry (Dash0) setup for Minecraft Finder

The Flutter app in `flutter_app/` reports telemetry with [flutter-dash0-sdk](https://github.com/Lock128/flutter-dash0-sdk) (`v0.9.0`, same version as nexus-share). The app has no backend, so the SDK exports directly from the client to Dash0 over OTLP/HTTP.

Telemetry is off unless **both** an endpoint and an auth token are compiled in. Local runs, tests and CI builds without the secrets send nothing.

## What the app reports

- Screen navigation (`Dash0.navigatorObserver` on `MaterialApp`)
- Uncaught errors (`FlutterError.onError`, `PlatformDispatcher.onError`, `runZonedGuarded`)
- App lifecycle, metrics, web vitals (web), rage clicks, and SDK HTTP spans
- Service name `minecraft-finder` (production) or `minecraft-finder-<environment>` otherwise

Deliberately **not** enabled: session replay, profiling, `HttpOverrides` and trace header propagation. The app takes world seeds and coordinates as input, and has no own backend to propagate to. Do not add seeds, coordinates or purchase data as span or log attributes.

## Actions required (in order)

### 1. Dash0 account and dataset
1. In Dash0, create a dataset for the app, for example `minecraft-finder` (optionally one per environment such as `minecraft-finder-beta`).
2. Note the OTLP/HTTP ingress URL of your Dash0 region, for example `https://ingress.eu-west-1.aws.dash0.com`. A trailing `/v1/traces` is accepted and stripped.

### 2. Auth token
1. In Dash0 go to Settings, Auth Tokens, and create a token with **ingest only** permission, limited to the dataset from step 1.
2. Treat it as public-ish: it ends up in the compiled web bundle and in app binaries. Use a dedicated ingest-only token, never an admin or API token, and rotate it if abused.

### 3. GitHub configuration (web deployment)
`.github/workflows/deploy-web-hosting.yml` passes these to `flutter build web --release`:

| Name | Kind | Value |
| --- | --- | --- |
| `FLUTTER_OTLP_ENDPOINT` | Repository secret | Ingress URL from step 1 |
| `FLUTTER_OTLP_HEADERS` | Repository secret | `Authorization=Bearer <token>,Dash0-Dataset=<dataset>` |
| `DASH0_ENVIRONMENT` | Repository variable (optional) | Defaults to `production` |

Secret names match nexus-share, so the same naming can be reused. Without the secrets the web build is produced with telemetry disabled.

### 4. Android and iOS release builds
Release builds are not in CI, so pass the same values by hand (never commit them):

```bash
cd flutter_app
flutter build appbundle --release \
  --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT=https://ingress.<region>.dash0.com \
  --dart-define=OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer <token>,Dash0-Dataset=minecraft-finder" \
  --dart-define=DASH0_ENVIRONMENT=production
# same --dart-define flags for: flutter build ios --release
```

The Android main manifest declares `android.permission.INTERNET`, which release builds need to export telemetry. Test one release build and check that data arrives in Dash0.

For local debugging use the same flags with `flutter run` and `DASH0_ENVIRONMENT=development` (the default in debug builds). Debug builds also enable SDK debug logging.

### 5. Privacy and store listings
- `flutter_app/PRIVACY_POLICY.md` was updated to describe the diagnostics. Publish the updated policy at its public URL.
- **App Store Connect, App Privacy:** declare Diagnostics data (Crash Data, Performance Data) as collected, not linked to the user, not used for tracking.
- **Google Play, Data safety:** declare Crash logs and Diagnostics as collected. The service provider (Dash0) processes the data on our behalf.
- `flutter_app/APP_STORE_RESPONSE.md` and `store_listings/english.md` were updated to mention diagnostics. Re-read them before submitting.
- Review any other "no data collected" statements in store descriptions and in `flutter_app/APP_STORE_*.md`, which now conflict if diagnostics are enabled.

### 6. Web hosting (CloudFront)
The CSP in `infrastructure/src/constructs/cloudfront-distribution.ts` uses `connect-src 'self' https:`, so the browser can already reach the Dash0 ingress. No CDK change is needed. If you tighten that directive later, add the Dash0 ingress origin. Confirm in the browser network tab that OTLP requests from the web build are not blocked by CORS (nexus-share exports from the browser the same way).

## Verify
1. Build or run with the dart-defines above and open a few screens.
2. In Dash0, filter by service `minecraft-finder` (and the dataset). Within about a minute you should see navigation spans and `app.client.type` set to `web-*`, `ios` or `android`.
3. Trigger a test error in a debug build and look for it in Logs/Errors.
4. In debug builds, the SDK `debug` flag prints export status in the console.

## Local SDK development
In `flutter_app/pubspec.yaml` switch the `dash0_flutter_sdk` dependency to `path: ../../flutter-dash0-sdk`.
