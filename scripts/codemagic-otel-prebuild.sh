#!/bin/bash

# Codemagic pre-build step: writes flutter_app/otlp_config.json for Dash0 telemetry.
#
# Usage (Codemagic: pre-build script, or a script step before the build steps):
#   bash scripts/codemagic-otel-prebuild.sh
#
# Then build with:
#   cd flutter_app
#   flutter build appbundle --release --dart-define-from-file=otlp_config.json
#   flutter build ios --release --dart-define-from-file=otlp_config.json
#
# Reads these Codemagic variables (see SETUP_OTEL.md and scripts/codemagic-otel-vars.sh):
#   DASH0_ENVIRONMENT                  "production" selects the PROD_ pair, anything else NONPROD_
#   NONPROD_FLUTTER_OTLP_ENDPOINT / NONPROD_FLUTTER_OTLP_HEADERS
#   PROD_FLUTTER_OTLP_ENDPOINT    / PROD_FLUTTER_OTLP_HEADERS   (no fallback to NONPROD_)
#   DASH0_SDK_DEBUG                    optional, "true" prints SDK export warnings in release builds
#   BUILD_NUMBER, FCI_COMMIT, FCI_BRANCH, FCI_REPOSITORY_URL    (set by Codemagic)
#
# If the endpoint or headers are not set, it writes {} so the build still works
# with telemetry off. Header values are never printed. Needs bash 3.2+ and jq.
# The file contains a token: it is gitignored (flutter_app/.gitignore), mode 600.

set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: bash scripts/codemagic-otel-prebuild.sh [--help]

Writes flutter_app/otlp_config.json for the Codemagic build. Run it from the
Codemagic pre-build step; it works from any directory.

Variables: DASH0_ENVIRONMENT, NONPROD_/PROD_FLUTTER_OTLP_ENDPOINT,
NONPROD_/PROD_FLUTTER_OTLP_HEADERS (PROD_ is used only when
DASH0_ENVIRONMENT=production), plus BUILD_NUMBER and FCI_* from Codemagic.
USAGE
}

case "${1:-}" in
    --help | -h)
        usage
        exit 0
        ;;
    "") ;;
    *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
esac

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required" >&2; exit 1; }

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app_dir="$script_dir/../flutter_app"
[ -d "$app_dir" ] || { echo "ERROR: $app_dir not found" >&2; exit 1; }
out="$app_dir/otlp_config.json"

environment="${DASH0_ENVIRONMENT:-}"
case "$environment" in
    production)
        endpoint="${PROD_FLUTTER_OTLP_ENDPOINT:-}"
        headers="${PROD_FLUTTER_OTLP_HEADERS:-}"
        ;;
    *)
        endpoint="${NONPROD_FLUTTER_OTLP_ENDPOINT:-}"
        headers="${NONPROD_FLUTTER_OTLP_HEADERS:-}"
        ;;
esac

umask 077
if [ -z "$endpoint" ] || [ -z "$headers" ]; then
    echo "WARNING: Dash0 variables not set for '$environment', building without telemetry"
    echo '{}' > "$out"
    chmod 600 "$out"
    exit 0
fi

case "$headers" in
    *Authorization=Bearer*) ;;
    *) echo "ERROR: OTLP headers lack Authorization=Bearer" >&2; exit 1 ;;
esac
case "$headers" in
    *Dash0-Dataset=*) ;;
    *) echo "ERROR: OTLP headers lack Dash0-Dataset=" >&2; exit 1 ;;
esac

repo_url="${FCI_REPOSITORY_URL:-https://github.com/Lock128/minecraft-finder}"
# Strip credentials (user:password@) from the repository URL.
repo_url="$(printf '%s' "$repo_url" | sed -E 's#^([a-zA-Z][a-zA-Z0-9+.-]*://)[^/@]*@#\1#')"

dep_name=""
[ -n "$environment" ] && dep_name="minecraft-finder-$environment"

jq -n --arg e "$endpoint" --arg h "$headers" \
    --arg env "$environment" \
    --arg dname "$dep_name" \
    --arg did "${BUILD_NUMBER:-}" \
    --arg rev "${FCI_COMMIT:-}" \
    --arg branch "${FCI_BRANCH:-}" \
    --arg url "$repo_url" \
    --arg sdkdebug "${DASH0_SDK_DEBUG:-}" \
    '{OTEL_EXPORTER_OTLP_ENDPOINT: $e, OTEL_EXPORTER_OTLP_HEADERS: $h}
     + ({DASH0_ENVIRONMENT: $env,
         DASH0_DEPLOYMENT_NAME: $dname,
         DASH0_DEPLOYMENT_ID: $did,
         DASH0_VCS_REF_HEAD_REVISION: $rev,
         DASH0_VCS_REF_HEAD_NAME: $branch,
         DASH0_VCS_REPOSITORY_URL_FULL: $url,
         DASH0_SDK_DEBUG: $sdkdebug}
        | with_entries(select(.value != "")))' > "$out"
chmod 600 "$out"
echo "Dash0 config written to flutter_app/otlp_config.json (values not printed)"
