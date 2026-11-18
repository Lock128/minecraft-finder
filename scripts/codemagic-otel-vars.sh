#!/bin/bash

# Codemagic setup helper for Dash0 telemetry in Minecraft Finder
#
# Prints what to configure in the Codemagic UI so mobile builds send telemetry
# to Dash0. Prints only: no network access, no side effects. It never contains
# or asks for token values. See SETUP_OTEL.md (branch feat/dash0-otel).

set -euo pipefail

ENDPOINT="https://ingress.eu-west-1.aws.dash0.com"
ENV_SEL="all"

usage() {
    cat <<'USAGE'
Usage: scripts/codemagic-otel-vars.sh [--env <name>|all] [--help]

Prints the Codemagic variables and build script step needed for Dash0
telemetry in mobile builds. Nothing is changed and no token is printed.

Options:
  --env <name>  dev, staging, production or all (default: all)
  --help        Show this help
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --env)
            [ $# -ge 2 ] || { echo "--env needs a value" >&2; exit 1; }
            ENV_SEL="$2"
            shift 2
            ;;
        --help | -h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

case "$ENV_SEL" in
    dev | staging | production | all) ;;
    *)
        echo "Invalid --env '$ENV_SEL' (use dev, staging, production or all)" >&2
        exit 1
        ;;
esac

want_nonprod=false
want_prod=false
case "$ENV_SEL" in
    production) want_prod=true ;;
    dev | staging) want_nonprod=true ;;
    all) want_nonprod=true; want_prod=true ;;
esac

echo "== 1. Secure variables (Codemagic: App > Environment variables, tick 'Secure') =="
echo
echo "Add them to a group, for example 'dash0', and import the group in codemagic.yaml"
echo "or the workflow editor. Headers are ONE line, without quotes."
echo "Token values: run scripts/setup-otel.sh --rotate (Dash0 PR) or copy them from"
echo "the Dash0 UI. They are never printed here. The tokens are ingest-only and"
echo "dataset-restricted, but still end up in the app binary: never use an admin token."
echo
if $want_nonprod; then
    echo "NONPROD_FLUTTER_OTLP_ENDPOINT = $ENDPOINT"
    echo "NONPROD_FLUTTER_OTLP_HEADERS  = Authorization=Bearer <token of nonprod-minecraft-finder-flutter-ingest>,Dash0-Dataset=nonprod-minecraft-finder"
    echo "  used for: dev, staging (and any other non-production build)"
fi
if $want_prod; then
    echo "PROD_FLUTTER_OTLP_ENDPOINT    = $ENDPOINT"
    echo "PROD_FLUTTER_OTLP_HEADERS     = Authorization=Bearer <token of minecraft-finder-flutter-ingest>,Dash0-Dataset=minecraft-finder"
    echo "  used for: production (store) builds only. No fallback to the NONPROD_ pair."
fi
echo
echo "DASH0_ENVIRONMENT (per workflow, not secret)"
case "$ENV_SEL" in
    dev | staging) echo "  value for this build: $ENV_SEL" ;;
    production) echo "  value for this build: production" ;;
    *)
        echo "  production for store builds, otherwise the environment name (dev, staging)."
        echo "  Becomes deployment.environment.name; the service name is minecraft-finder"
        echo "  for production and minecraft-finder-<environment> otherwise."
        ;;
esac
echo "  Release builds without it send no environment attribute."
echo

echo "== 2. Optional build variables =="
echo
echo "The app reads only these dart-defines (see flutter_app/lib/main.dart and"
echo "utils/dash0_config.dart on feat/dash0-otel):"
echo "  OTEL_EXPORTER_OTLP_ENDPOINT  required, set by the step below from <ENV>_FLUTTER_OTLP_ENDPOINT"
echo "  OTEL_EXPORTER_OTLP_HEADERS   required, set by the step below from <ENV>_FLUTTER_OTLP_HEADERS"
echo "  DASH0_ENVIRONMENT            optional, default empty (see above)"
echo "Telemetry is off unless both the endpoint and a bearer token are compiled in."
echo
echo "Set automatically, nothing to configure:"
echo "  service.version              <version>+<build number> from package_info_plus"
echo
echo "Not read by this app (setting them has no effect): DASH0_DEPLOYMENT_NAME,"
echo "DASH0_DEPLOYMENT_ID, DASH0_VCS_REF_HEAD_REVISION, DASH0_VCS_REF_HEAD_NAME,"
echo "DASH0_VCS_REPOSITORY_URL_FULL, DASH0_METRIC_EXPORT_INTERVAL_SECONDS."
echo "Session replay, profiling, HTTP overrides and trace header propagation are"
echo "deliberately off (the app handles user input such as world seeds) and have"
echo "no variable."
echo

echo "== 3. Codemagic script step (put it before the build steps) =="
echo
cat <<'STEP'
- name: Write Dash0 config
  script: |
    set -euo pipefail
    cd flutter_app
    case "${DASH0_ENVIRONMENT:-}" in
      production) endpoint="${PROD_FLUTTER_OTLP_ENDPOINT:-}"; headers="${PROD_FLUTTER_OTLP_HEADERS:-}" ;;
      *)          endpoint="${NONPROD_FLUTTER_OTLP_ENDPOINT:-}"; headers="${NONPROD_FLUTTER_OTLP_HEADERS:-}" ;;
    esac
    if [ -z "$endpoint" ] || [ -z "$headers" ]; then
      echo "WARNING: Dash0 variables not set for '${DASH0_ENVIRONMENT:-}', building without telemetry"
      echo '{}' > otlp_config.json
    else
      case "$headers" in
        *Authorization=Bearer*) ;;
        *) echo "ERROR: OTLP headers lack Authorization=Bearer"; exit 1 ;;
      esac
      case "$headers" in
        *Dash0-Dataset=*) ;;
        *) echo "ERROR: OTLP headers lack Dash0-Dataset="; exit 1 ;;
      esac
      jq -n --arg e "$endpoint" --arg h "$headers" --arg env "${DASH0_ENVIRONMENT:-}" \
        '{OTEL_EXPORTER_OTLP_ENDPOINT: $e, OTEL_EXPORTER_OTLP_HEADERS: $h}
         + (if $env != "" then {DASH0_ENVIRONMENT: $env} else {} end)' > otlp_config.json
      echo "Dash0 config written (values not printed)"
    fi
STEP
echo
echo "Build commands (run from flutter_app/, Flutter 3.35.5 in CI). Keep any existing"
echo "--dart-define flags next to --dart-define-from-file:"
echo
echo "  flutter build appbundle --release --dart-define-from-file=otlp_config.json"
echo "  flutter build ios --release --dart-define-from-file=otlp_config.json"
echo
echo "otlp_config.json contains the token and must never be committed. Add this line"
echo "to flutter_app/.gitignore (it is not ignored yet):"
echo
echo "  otlp_config.json"
