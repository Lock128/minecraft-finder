# OpenTelemetry (Dash0) setup for Minecraft Finder

The Flutter app in `flutter_app/` reports telemetry with [flutter-dash0-sdk](https://github.com/Lock128/flutter-dash0-sdk) (`v0.11.0`, same version as nexus-share). The app has no backend, so the SDK exports directly from the client to Dash0 over OTLP/HTTP.

Telemetry is off unless **both** an endpoint and an auth token are compiled in. Local runs, tests and CI builds without the secrets send nothing.

## What the app reports

- Screen navigation (`Dash0.navigatorObserver` on `MaterialApp`)
- Uncaught errors (`FlutterError.onError`, `PlatformDispatcher.onError`, `runZonedGuarded`)
- App lifecycle, metrics, web vitals (web), rage clicks, and SDK HTTP spans
- Service name `minecraft-finder` (production) or `minecraft-finder-<environment>` otherwise

Deliberately **not** enabled: session replay, profiling, `HttpOverrides` and trace header propagation. The app takes world seeds and coordinates as input, and has no own backend to propagate to. Do not add seeds, coordinates or purchase data as span or log attributes.

## Actions required (in order)

### 1. Dash0 account and dataset
Two datasets exist in the Dash0 region `eu-west-1`:

| Dataset slug | Used for |
| --- | --- |
| `minecraft-finder` | Production |
| `nonprod-minecraft-finder` | Every non-production environment (dev, staging, sandbox, beta) |

The OTLP/HTTP ingress URL is `https://ingress.eu-west-1.aws.dash0.com`. A trailing `/v1/traces` is accepted and stripped. The Dash0 API URL is `https://api.eu-west-1.aws.dash0.com`.

To create them yourself (for another region or account), use the [dash0 CLI](#set-up-dash0-with-the-dash0-cli) below, or the Dash0 UI.

### 2. Auth token
One ingest-only token per dataset already exists: `minecraft-finder-flutter-ingest` (dataset `minecraft-finder`) and `nonprod-minecraft-finder-flutter-ingest` (dataset `nonprod-minecraft-finder`). Each has the action `ingest:*` and is restricted to its dataset.

Treat the tokens as public: they end up in the compiled web bundle and in app binaries. Use only dedicated ingest-only, dataset-restricted tokens, never an admin or API token, and rotate a token if it is abused. The production bundle must never contain the nonprod token and vice versa.

### 3. GitHub configuration (web deployment)
`.github/workflows/deploy-web-hosting.yml` passes these to `flutter build web --release`. The `prod` environment uses only the `PROD_*` secrets (no fallback to `NONPROD_*`). Every other environment (`dev`, `staging`) uses only the `NONPROD_*` secrets.

| Name | Kind | Value |
| --- | --- | --- |
| `NONPROD_FLUTTER_OTLP_ENDPOINT` | Repository secret | `https://ingress.eu-west-1.aws.dash0.com` |
| `NONPROD_FLUTTER_OTLP_HEADERS` | Repository secret | `Authorization=Bearer <nonprod token>,Dash0-Dataset=nonprod-minecraft-finder` |
| `PROD_FLUTTER_OTLP_ENDPOINT` | Repository secret | `https://ingress.eu-west-1.aws.dash0.com` |
| `PROD_FLUTTER_OTLP_HEADERS` | Repository secret | `Authorization=Bearer <prod token>,Dash0-Dataset=minecraft-finder` |
| `DASH0_SDK_DEBUG` | Codemagic variable (optional) | `true` makes the SDK print export warnings (with HTTP status) in release builds. Written to `otlp_config.json` by the pre-build script |
| `DASH0_ENVIRONMENT` | Repository variable (optional) | Overrides `deployment.environment.name`. Defaults to `production` for `prod` and to the environment name (`dev`, `staging`) otherwise |

Run [`scripts/setup-otel.sh`](#automated-setup-with-scriptssetup-otelsh) from your own machine to create these secrets (the token values are never stored in this repository). Without the secrets the web build is produced with telemetry disabled.

## Automated setup with `scripts/setup-otel.sh`
The script does the whole setup below (datasets, ingest-only tokens, GitHub secrets) from your own machine, with your own `gh` login. Use it when setting secrets through an agent or gateway fails with HTTP 403.

### Prerequisites
- `dash0` CLI 1.22 or newer, `jq`, and `gh`
- `DASH0_AUTH_TOKEN`: a Dash0 admin token, read from the environment only (the script rejects it as an argument). `DASH0_API_URL` defaults to `https://api.eu-west-1.aws.dash0.com`
- `gh` logged in with permission to write Actions secrets on `Lock128/minecraft-finder`: a classic token with the `repo` scope, or a fine-grained token for that repository with Repository permission **Secrets: Read and write**

The script checks all of this first, including `gh api repos/Lock128/minecraft-finder/actions/secrets/public-key`.

### Usage
```bash
export DASH0_AUTH_TOKEN=<admin token>      # keep out of shell history, for example by using read -s
scripts/setup-otel.sh --dry-run            # validate and print the plan, sets nothing
scripts/setup-otel.sh                      # nonprod and prod
scripts/setup-otel.sh --only nonprod       # or: --only prod
scripts/setup-otel.sh --rotate             # replace existing tokens
scripts/setup-otel.sh --help
```

### What it does
For each environment (`nonprod-minecraft-finder` and `minecraft-finder`):
1. Creates or updates the dataset with `dash0 -X datasets create -f` (upsert by slug, same YAML as below).
2. Creates the ingest-only token `<slug>-flutter-ingest` (`ingest:*`, restricted to that dataset). The secret is written with `--secret-file` into a private temporary directory that is removed on exit. It is never printed or passed on a command line.
3. Sets `<NONPROD|PROD>_FLUTTER_OTLP_ENDPOINT` and `<NONPROD|PROD>_FLUTTER_OTLP_HEADERS` (`Authorization=Bearer <token>,Dash0-Dataset=<slug>`) on `Lock128/minecraft-finder` through `gh secret set`, reading the value from stdin.

### Rotation
Dash0 returns a token secret only when the token is created. If `<slug>-flutter-ingest` already exists, the script stops with an error before it changes anything. Run it with `--rotate` to delete the existing token (it stops working at once) and create a new one. Re-run the web deployment afterwards, and update the mobile build variables (Codemagic) with the new values.

### Troubleshooting HTTP 403
`gh` fails with 403 when its token cannot write Actions secrets, or when `GH_TOKEN`/`GITHUB_TOKEN` in the environment overrides your login. Unset those variables, run `gh auth login` with a classic `repo`-scope token or a fine-grained token with **Secrets: Read and write** on this repository, and check with `gh api repos/Lock128/minecraft-finder/actions/secrets/public-key`. A newly created token needs to be selected during `gh auth login` (or exported as `GH_TOKEN`); org SSO may also require authorizing the token.

### Secrets never touch the repository
The script contains no token values. Temporary files live in a `mktemp -d` directory with mode 700 and are deleted by an `EXIT` trap.

## Set up Dash0 manually with the dash0 CLI
The datasets and tokens above can be created with the [dash0 CLI](https://github.com/dash0hq/dash0-cli) (syntax verified with v1.22.1). `--dry-run` previews a creation.

### Install
```bash
brew install --cask dash0hq/dash0-cli/dash0
```
Or download a release binary from the [releases page](https://github.com/dash0hq/dash0-cli/releases) and put it on your `PATH`.

### Authenticate
Use an admin token that may create datasets and auth tokens (keep it out of git):
```bash
export DASH0_API_URL=https://api.eu-west-1.aws.dash0.com
export DASH0_AUTH_TOKEN=<admin token>
```
Alternatively run `dash0 login` and follow the prompts. Check access with `dash0 -X datasets list`.

### Create the dataset
Save as `ds.yaml` (repeat with slug `nonprod-minecraft-finder` for nonprod):
```yaml
apiVersion: dash0.com/v1alpha1
kind: Dash0Dataset
metadata:
  name: minecraft-finder
  labels:
    dash0.com/id: minecraft-finder
spec:
  slug: minecraft-finder
  preferred: false
  permissions:
    - actions: [dataset:read]
      role: basic_member
  privacy:
    geoLocation:
      endUser:
        storage: up_to_city
    ipAddresses:
      endUser:
        storage: anonymize
  retention:
    logs: 30d
    metrics: 13M
    profiles: 30d
    traces: 30d
    webEvents: 30d
```
```bash
dash0 -X datasets create -f ds.yaml --dry-run
dash0 -X datasets create -f ds.yaml
dash0 -X datasets list
```

### Create the ingest-only token
Save as `tok.yaml` (repeat with `nonprod-minecraft-finder` names for nonprod):
```yaml
apiVersion: dash0.com/v1alpha1
kind: Dash0AuthToken
metadata:
  name: minecraft-finder-flutter-ingest
spec:
  actions: [ingest:*]
  ingestion:
    defaultDataset: minecraft-finder
  scope:
    datasets:
      restriction: restricted
      slugs: [minecraft-finder]
    signals:
      restriction: unrestricted
      types: []
```
```bash
dash0 -X auth-tokens create -f tok.yaml --secret-file ./token.secret
dash0 -X auth-tokens list
```
`--secret-file` must point to a new file. Write it outside the repository or in a gitignored path, and delete it once the GitHub secrets are set. Never commit it.

### Build the header value
```bash
printf 'Authorization=Bearer %s,Dash0-Dataset=%s' "$(cat ./token.secret)" minecraft-finder
```
The result is the value for `PROD_FLUTTER_OTLP_HEADERS` (use `nonprod-minecraft-finder` and the nonprod token for `NONPROD_FLUTTER_OTLP_HEADERS`). Set the secrets with `gh secret set <NAME> --repo Lock128/minecraft-finder`.

### 4. Android and iOS release builds
**No iOS or Android build is defined in this repository.** There is no `codemagic.yaml`, fastlane setup or GitHub workflow that builds an app bundle or iOS app, so mobile builds run in the Codemagic UI (or by hand). The telemetry configuration must be added to that build. Without it the app starts with telemetry disabled.

The app reads its OTLP settings from build-time variables, passed with `--dart-define-from-file=otlp_config.json`. The script `scripts/codemagic-otel-prebuild.sh` writes that file.

#### 1. Get the variable values (once, on your machine)
`scripts/codemagic-otel-vars.sh` creates dedicated ingest-only tokens `<slug>-codemagic-ingest` (separate from the GitHub `-flutter-ingest` tokens, which it never changes) and prints the Codemagic variables as `NAME=value` lines to copy and paste:

```bash
export DASH0_AUTH_TOKEN=<admin token>   # environment only, never an argument
scripts/codemagic-otel-vars.sh --env all          # or dev, staging, production
scripts/codemagic-otel-vars.sh --dry-run          # validate only, creates nothing
```

Dash0 returns a token secret only when the token is created and never again. If `<slug>-codemagic-ingest` already exists, the script prints everything else and tells you so. Add `--rotate` to delete it and create a new one (the old secret stops working, so update Codemagic right away). Secrets are printed to the terminal only. The script refuses to print them when stdout is not a terminal (unless you pass `--print-secrets-to-pipe`) or when `CI` or `CM_BUILD_ID` is set. Without `DASH0_AUTH_TOKEN` it prints placeholders. Needs the dash0 CLI 1.22 or newer and `jq`.

#### 2. Codemagic variables
Add these in a variable group (for example `dash0`) and mark the `*_HEADERS` ones as Secure:

| Variable | Purpose |
| --- | --- |
| `NONPROD_FLUTTER_OTLP_ENDPOINT`, `NONPROD_FLUTTER_OTLP_HEADERS` | Dev, staging and other non-production builds (dataset `nonprod-minecraft-finder`) |
| `PROD_FLUTTER_OTLP_ENDPOINT`, `PROD_FLUTTER_OTLP_HEADERS` | Production store builds only (dataset `minecraft-finder`). No fallback to `NONPROD_*` |
| `DASH0_ENVIRONMENT` | `production` selects the `PROD_*` pair, anything else the `NONPROD_*` pair. Becomes `deployment.environment.name` |

The headers value must contain both `Authorization=Bearer <token>` and `Dash0-Dataset=<dataset>`, for example `Authorization=Bearer auth_xxx,Dash0-Dataset=minecraft-finder`. Optional variables are listed by `scripts/codemagic-otel-vars.sh` (section 2).

#### 3. Pre-build step and build commands
Call the script from the Codemagic pre-build step (it works from any directory, needs `jq`, bash 3.2 is enough):

```bash
bash scripts/codemagic-otel-prebuild.sh
```

It picks the variables for `DASH0_ENVIRONMENT`, checks the headers, and writes `flutter_app/otlp_config.json` (mode 600, gitignored) with the OTLP settings, `DASH0_ENVIRONMENT`, `DASH0_DEPLOYMENT_NAME`, `DASH0_DEPLOYMENT_ID` (`$BUILD_NUMBER`) and the `DASH0_VCS_*` values from `FCI_*` (credentials stripped from the repository URL). It never prints header values. If the endpoint or headers are not set, it warns and writes `{}`, so the build succeeds with telemetry off. Invalid headers fail the step. Then build from `flutter_app/`:

```bash
flutter build appbundle --release --dart-define-from-file=otlp_config.json
flutter build ios --release --dart-define-from-file=otlp_config.json
```

Never put the nonprod token into a production build or the other way round.

Native apps send `service.version` as `<version>+<build number>` (from `package_info_plus`) and a synthetic user agent built by the SDK. Web builds send the browser user agent.

The Android main manifest declares `android.permission.INTERNET`, which release builds need to export telemetry. Test one release build and check that data arrives in Dash0.

For local debugging use `flutter run` with the same `--dart-define-from-file` and `DASH0_ENVIRONMENT=development` (the default in debug builds). Debug builds also enable SDK debug logging.

### 5. Privacy and store listings (release gate)
**Do not ship a build with the `PROD_*` secrets until the policy is public.** Deploy or publish the updated `flutter_app/PRIVACY_POLICY.md` at its public URL before, or together with, the first production build (web, App Store, Google Play) that has the `PROD_*` secrets.

- The policy, `flutter_app/APP_STORE_RESPONSE.md` and `store_listings/{english,german,french}.md` disclose the telemetry: usage and performance data, error reports, page views, device model, OS version and app version (native builds also send a synthetic user agent with app version, OS version and device model identifier), a random session ID and no user ID. Dash0 anonymizes IP addresses and keeps city-level approximate location. Session replay and profiling are off. Processor Dash0, EU (eu-west-1), retention 30 days (metrics 13 months), purpose diagnostics and reliability, no advertising, no sale of data. If the SDK settings or dataset privacy settings change, update all of them together.
- **App Store Connect, App Privacy (manual, maintainer):** declare Crash Data, Performance Data and Product Interaction (page views) as collected, not linked to the user, not used for tracking.
- **Google Play, Data safety (manual, maintainer):** declare Crash logs and Diagnostics as collected, and Dash0 as a service provider processing data on our behalf.
- Neither store declaration can be changed from this repository. Update them before releasing.

### 6. Web hosting (CloudFront)
The CSP in `infrastructure/src/constructs/cloudfront-distribution.ts` uses `connect-src 'self' https:`, so the browser can already reach the Dash0 ingress. No CDK change is needed. If you tighten that directive later, add the Dash0 ingress origin. Confirm in the browser network tab that OTLP requests from the web build are not blocked by CORS (nexus-share exports from the browser the same way).

## Verify
1. Build or run with the dart-defines above and open a few screens.
2. In Dash0, filter by service `minecraft-finder` (and the matching dataset). Within about a minute you should see navigation spans and `app.client.type` set to `web-*`, `ios` or `android`.
3. Trigger a test error in a debug build and look for it in Logs/Errors.
4. In debug builds, the SDK `debug` flag prints export status in the console.

## Troubleshooting on a device
Release builds hide SDK diagnostics. To see what happens on a device (TestFlight, App Store, Play):

1. Open the screen: open the About dialog and long-press its title. The screen shows the init state, endpoint, dataset, masked token, session and SDK state.
2. **Send test event** sends `dash0.diagnostics.test` through the SDK and flushes. "Done" only means the SDK accepted it.
3. **Test connection** POSTs a log record to `<endpoint>/v1/logs` without the SDK, with the compiled-in headers. HTTP 200 means network and token work. 401/403 means a wrong token or dataset. An exception means the device cannot reach Dash0. The record has `service.name` `<service>-diagnostics`.
4. **Copy** copies a plain-text report. It contains only the masked token.
5. Set `DASH0_SDK_DEBUG=true` in Codemagic and rebuild to print SDK export failures. Read them in Xcode (Window > Devices and Simulators > Open Console) or Console.app, filtered by `[dash0]`. On Android use `adb logcat | grep dash0`.

This app enables gzip compression (`Dash0Compression.gzip`). If Test connection succeeds but SDK exports fail, gzip is the first suspect.

## Local SDK development
In `flutter_app/pubspec.yaml` switch the `dash0_flutter_sdk` dependency to `path: ../../flutter-dash0-sdk`.
