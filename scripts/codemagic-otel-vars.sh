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
echo "Required dart-defines (written by the step in section 3):"
echo "  OTEL_EXPORTER_OTLP_ENDPOINT  from <ENV>_FLUTTER_OTLP_ENDPOINT"
echo "  OTEL_EXPORTER_OTLP_HEADERS   from <ENV>_FLUTTER_OTLP_HEADERS"
echo "Telemetry is off unless both the endpoint and a bearer token are compiled in."
echo
echo "Optional dart-defines. flutter-dash0-sdk reads them through String.fromEnvironment"
echo "(lib/src/vcs.dart), so --dart-define-from-file is enough. Empty values are ignored."
echo "Codemagic source in brackets; the step in section 3 fills them in when non-empty:"
echo "  DASH0_ENVIRONMENT               [DASH0_ENVIRONMENT, see above]"
echo "  DASH0_DEPLOYMENT_NAME           [minecraft-finder-\$DASH0_ENVIRONMENT]"
echo "  DASH0_DEPLOYMENT_ID             [\$BUILD_NUMBER]"
echo "  DASH0_VCS_REF_HEAD_REVISION     [\$FCI_COMMIT]"
echo "  DASH0_VCS_REF_HEAD_NAME         [\$FCI_BRANCH]"
echo "  DASH0_VCS_REPOSITORY_URL_FULL   [\$FCI_REPOSITORY_URL, else https://github.com/Lock128/minecraft-finder]"
echo "  DASH0_VCS_PROVIDER_NAME         [derived from the repository URL, set only to override]"
echo "  DASH0_VCS_OWNER_NAME            [derived from the repository URL, set only to override]"
echo "  DASH0_VCS_REPOSITORY_NAME       [derived from the repository URL, set only to override]"
echo "  DASH0_VCS_CHANGE_ID             [pull request number, if your workflow has one]"
echo "Credentials in the repository URL are stripped by the SDK."
echo
echo "Set automatically, nothing to configure:"
echo "  service.version              <version>+<build number> from package_info_plus"
echo
echo "Session replay, profiling, HTTP overrides, trace header propagation and the"
echo "metric export interval have no dart-define. They are set in main.dart on the"
echo "feat/dash0-otel branch, not by variable. Session replay, profiling and"
echo "propagation are deliberately off (the app handles user input such as world seeds)."
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
      repo_url="${FCI_REPOSITORY_URL:-https://github.com/Lock128/minecraft-finder}"
      dep_name=""
      [ -n "${DASH0_ENVIRONMENT:-}" ] && dep_name="minecraft-finder-${DASH0_ENVIRONMENT}"
      jq -n --arg e "$endpoint" --arg h "$headers" \
        --arg env "${DASH0_ENVIRONMENT:-}" \
        --arg dname "$dep_name" \
        --arg did "${BUILD_NUMBER:-}" \
        --arg rev "${FCI_COMMIT:-}" \
        --arg branch "${FCI_BRANCH:-}" \
        --arg url "$repo_url" \
        '{OTEL_EXPORTER_OTLP_ENDPOINT: $e, OTEL_EXPORTER_OTLP_HEADERS: $h}
         + ({DASH0_ENVIRONMENT: $env,
             DASH0_DEPLOYMENT_NAME: $dname,
             DASH0_DEPLOYMENT_ID: $did,
             DASH0_VCS_REF_HEAD_REVISION: $rev,
             DASH0_VCS_REF_HEAD_NAME: $branch,
             DASH0_VCS_REPOSITORY_URL_FULL: $url}
            | with_entries(select(.value != "")))' > otlp_config.json
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
