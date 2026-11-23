#!/bin/bash

# Codemagic variables helper for Dash0 telemetry in Minecraft Finder
#
# With DASH0_AUTH_TOKEN (admin token, from the environment only) it creates
# dedicated ingest-only tokens "<slug>-codemagic-ingest" and prints the
# Codemagic variables as ready-to-paste NAME=value lines. Dash0 returns a token
# secret only once, at creation, so it cannot be read back later: --rotate
# creates a new one. The GitHub tokens "<slug>-flutter-ingest" are never
# touched. Without DASH0_AUTH_TOKEN it prints placeholders and changes nothing.
#
# Secrets go to stdout only (never to files, stderr or command arguments).
# Status messages go to stderr. See SETUP_OTEL.md. The pre-build step is
# scripts/codemagic-otel-prebuild.sh.

set -euo pipefail

OTLP_ENDPOINT="https://ingress.eu-west-1.aws.dash0.com"
DEFAULT_API_URL="https://api.eu-west-1.aws.dash0.com"
MIN_DASH0_VERSION="1.22"

ENV_SEL="all"
DRY_RUN=false
ROTATE=false
PIPE_OK=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Status output goes to stderr: stdout carries only the variables.
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

die() {
    print_error "$1"
    exit 1
}

usage() {
    cat <<'EOF'
Usage: [DASH0_AUTH_TOKEN=<admin token>] scripts/codemagic-otel-vars.sh [options]

With DASH0_AUTH_TOKEN set, creates ingest-only Dash0 tokens named
"<slug>-codemagic-ingest" and prints the Codemagic variables as NAME=value
lines to paste into Codemagic (mark the *_HEADERS ones as Secure). Without it,
prints placeholders only and changes nothing.

Options:
  --env <name>             dev, staging, production or all (default: all)
  --rotate                 Delete an existing "<slug>-codemagic-ingest" token and
                           create a new one (the old secret stops working). Without
                           it, an existing token is kept and its secret cannot be
                           shown again.
  --dry-run                Validate only, create nothing.
  --print-secrets-to-pipe  Allow printing secrets when stdout is not a terminal.
  --help                   Show this help

Environment:
  DASH0_AUTH_TOKEN         Optional admin token (never accepted as an argument).
  DASH0_API_URL            Optional. Default: https://api.eu-west-1.aws.dash0.com

Prerequisites (token mode): dash0 CLI >= 1.22 and jq. Secrets are not printed
when CI or CM_BUILD_ID is set.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --env)
            [ $# -ge 2 ] || die "--env needs a value"
            ENV_SEL="$2"
            shift
            ;;
        --env=*) ENV_SEL="${1#--env=}" ;;
        --rotate) ROTATE=true ;;
        --dry-run) DRY_RUN=true ;;
        --print-secrets-to-pipe) PIPE_OK=true ;;
        --help | -h)
            usage
            exit 0
            ;;
        *)
            usage >&2
            die "Unknown argument: $1"
            ;;
    esac
    shift
done

case "$ENV_SEL" in
    dev | staging | production | all) ;;
    *) die "Invalid --env '$ENV_SEL' (use dev, staging, production or all)" ;;
esac

want_nonprod=false
want_prod=false
case "$ENV_SEL" in
    production) want_prod=true ;;
    dev | staging) want_nonprod=true ;;
    all) want_nonprod=true; want_prod=true ;;
esac

TOKEN_MODE=false
[ -n "${DASH0_AUTH_TOKEN:-}" ] && TOKEN_MODE=true

# ---------------------------------------------------------------------------
# Prerequisites (token mode only)
# ---------------------------------------------------------------------------

check_prerequisites() {
    command -v jq >/dev/null 2>&1 || die "jq is not installed. Install it (for example: brew install jq)."
    command -v dash0 >/dev/null 2>&1 || die "dash0 CLI is not installed. Install it with: brew install --cask dash0hq/dash0-cli/dash0 (or see https://github.com/dash0hq/dash0-cli/releases)"

    local version_line version major minor min_major min_minor
    version_line="$(dash0 --version 2>&1 | head -n 1)"
    version="$(printf '%s' "$version_line" | grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || true)"
    [ -n "$version" ] || die "Could not read the dash0 version from: $version_line"
    major="${version%%.*}"
    minor="${version#*.}"
    minor="${minor%%.*}"
    min_major="${MIN_DASH0_VERSION%%.*}"
    min_minor="${MIN_DASH0_VERSION#*.}"
    if [ "$major" -lt "$min_major" ] || { [ "$major" -eq "$min_major" ] && [ "$minor" -lt "$min_minor" ]; }; then
        die "dash0 CLI $version is too old. Version $MIN_DASH0_VERSION or newer is required."
    fi

    export DASH0_API_URL="${DASH0_API_URL:-$DEFAULT_API_URL}"

    # A dry run prints no secrets, so the checks below do not apply.
    [ "$DRY_RUN" = true ] && return 0

    if [ -n "${CI:-}" ] || [ -n "${CM_BUILD_ID:-}" ]; then
        die "Refusing to print secrets in a CI/build environment (CI or CM_BUILD_ID is set). Run this on your own machine."
    fi
    if [ "$PIPE_OK" != true ] && [ ! -t 1 ]; then
        die "stdout is not a terminal, so secrets would end up in a pipe or file. Run it in a terminal, or pass --print-secrets-to-pipe if you are sure."
    fi
}

WORK_DIR=""
cleanup() {
    if [ -n "$WORK_DIR" ] && [ -d "$WORK_DIR" ]; then
        rm -rf "$WORK_DIR"
    fi
}
trap cleanup EXIT

make_work_dir() {
    WORK_DIR="$(mktemp -d)"
    chmod 700 "$WORK_DIR"
}

# ---------------------------------------------------------------------------
# Dash0 helpers
# ---------------------------------------------------------------------------

write_token_yaml() {
    local slug="$1" file="$2"
    cat >"$file" <<EOF
apiVersion: dash0.com/v1alpha1
kind: Dash0AuthToken
metadata:
  name: ${slug}-codemagic-ingest
spec:
  actions: [ingest:*]
  ingestion:
    defaultDataset: $slug
  scope:
    datasets:
      restriction: restricted
      slugs: [$slug]
    signals:
      restriction: unrestricted
      types: []
EOF
}

# Prints the id of the auth token with the given name, or nothing if none exists.
find_token_id() {
    local name="$1" json
    json="$(dash0 -X auth-tokens list -o json)" || die "Could not list Dash0 auth tokens. Check DASH0_AUTH_TOKEN and DASH0_API_URL."
    printf '%s' "$json" | jq -r --arg name "$name" '
        (if type == "array" then . else (.items // .authTokens // .tokens // []) end)
        | map(select((.metadata.name // .name // .spec.display.name // "") == $name))
        | first
        | if . == null then empty
          else (.metadata.labels["dash0.com/id"] // .metadata.id // .metadata.origin // .id // .origin // empty)
          end'
}

# Handles one environment. Sets HEADERS_VALUE (real value or placeholder) and
# SECRET_STATE (created, existing, planned or none).
HEADERS_VALUE=""
SECRET_STATE="none"
process_env() {
    local slug="$1" token_name existing_id tok_yaml secret_file token
    token_name="${slug}-codemagic-ingest"
    HEADERS_VALUE="Authorization=Bearer <token of ${token_name}>,Dash0-Dataset=${slug}"
    SECRET_STATE="none"
    $TOKEN_MODE || return 0

    existing_id="$(find_token_id "$token_name")"
    tok_yaml="$WORK_DIR/${slug}.yaml"
    secret_file="$WORK_DIR/${slug}.secret"
    write_token_yaml "$slug" "$tok_yaml"

    if $DRY_RUN; then
        # A dry run cannot validate a token creation while the same name exists.
        if [ -z "$existing_id" ]; then
            dash0 -X auth-tokens create -f "$tok_yaml" --dry-run >&2 || die "Token definition for $slug failed validation."
        fi
        if [ -n "$existing_id" ] && ! $ROTATE; then
            print_status "Plan: keep existing token $token_name (no --rotate)"
            SECRET_STATE="existing"
        else
            [ -n "$existing_id" ] && print_status "Plan: delete existing token $token_name (--rotate)"
            print_status "Plan: create ingest-only token $token_name (ingest:*, restricted to dataset $slug)"
            SECRET_STATE="planned"
        fi
        return 0
    fi

    if [ -n "$existing_id" ]; then
        if ! $ROTATE; then
            print_warning "Token $token_name already exists and is kept. Its secret cannot be retrieved again."
            SECRET_STATE="existing"
            return 0
        fi
        print_warning "Deleting existing auth token $token_name"
        dash0 -X auth-tokens delete "$existing_id" --force >/dev/null || die "Could not delete auth token $token_name."
    fi

    dash0 -X auth-tokens create -f "$tok_yaml" --secret-file "$secret_file" >/dev/null || die "Could not create auth token $token_name."
    [ -s "$secret_file" ] || die "Dash0 did not write a secret for $token_name."
    token="$(tr -d '\r\n' <"$secret_file")"
    rm -f "$secret_file"
    HEADERS_VALUE="Authorization=Bearer ${token},Dash0-Dataset=${slug}"
    unset token
    SECRET_STATE="created"
    print_success "Created auth token $token_name"
}

print_vars() {
    local prefix="$1" label="$2"
    echo "${prefix}_FLUTTER_OTLP_ENDPOINT=$OTLP_ENDPOINT"
    case "$SECRET_STATE" in
        existing) echo "${prefix}_FLUTTER_OTLP_HEADERS=<unavailable, token already exists: rerun with --rotate>" ;;
        planned) echo "${prefix}_FLUTTER_OTLP_HEADERS=<created on a real run>" ;;
        *) echo "${prefix}_FLUTTER_OTLP_HEADERS=$HEADERS_VALUE" ;;
    esac
    echo "  ${prefix}_FLUTTER_OTLP_HEADERS is a SECRET: tick 'Secure'. Used for: $label"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if $TOKEN_MODE; then
    check_prerequisites
    make_work_dir
    print_status "Dash0 API: $DASH0_API_URL"
    $DRY_RUN && print_status "Mode: dry run (nothing is created)"
    $ROTATE && print_status "Rotation: existing <slug>-codemagic-ingest tokens are deleted and recreated"
fi

echo "== 1. Codemagic variables (App > Environment variables, tick 'Secure' for *_HEADERS) =="
echo
echo "Add them to a group, for example 'dash0', and import the group in codemagic.yaml"
echo "or the workflow editor. Headers are ONE line, without quotes. The tokens are"
echo "dedicated ingest-only, dataset-restricted tokens (<slug>-codemagic-ingest). They"
echo "still end up in the app binary: never use an admin token."
if $TOKEN_MODE; then
    echo "Secrets are shown once. Dash0 cannot show them again."
else
    echo "Placeholders only. Set DASH0_AUTH_TOKEN to create the tokens and print real values."
fi
echo
EXISTING_NOTE=false
if $want_nonprod; then
    process_env "nonprod-minecraft-finder"
    print_vars NONPROD "dev, staging (and any other non-production build)"
    [ "$SECRET_STATE" = "existing" ] && EXISTING_NOTE=true
fi
if $want_prod; then
    process_env "minecraft-finder"
    print_vars PROD "production (store) builds only. No fallback to the NONPROD_ pair."
    [ "$SECRET_STATE" = "existing" ] && EXISTING_NOTE=true
fi
echo
if $EXISTING_NOTE; then
    echo "NOTE: a token with that name already exists. Dash0 does not return the secret of an"
    echo "existing token. --rotate creates a new token and invalidates the old one (builds"
    echo "that still use it lose telemetry until you paste the new value)."
    echo
fi
echo "DASH0_ENVIRONMENT (per workflow, not secret)"
case "$ENV_SEL" in
    dev | staging) echo "DASH0_ENVIRONMENT=$ENV_SEL" ;;
    production) echo "DASH0_ENVIRONMENT=production" ;;
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
echo "Required dart-defines (written by scripts/codemagic-otel-prebuild.sh):"
echo "  OTEL_EXPORTER_OTLP_ENDPOINT  from <ENV>_FLUTTER_OTLP_ENDPOINT"
echo "  OTEL_EXPORTER_OTLP_HEADERS   from <ENV>_FLUTTER_OTLP_HEADERS"
echo "Telemetry is off unless both the endpoint and a bearer token are compiled in."
echo
echo "Optional dart-defines. flutter-dash0-sdk reads them through String.fromEnvironment"
echo "(lib/src/vcs.dart), so --dart-define-from-file is enough. Empty values are ignored."
echo "Codemagic source in brackets; the pre-build script fills them in when non-empty:"
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
echo "  DASH0_SDK_DEBUG                 [set to true to print SDK export warnings in release builds; see SETUP_OTEL.md]"
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

echo "== 3. Codemagic pre-build step and build commands =="
echo
echo "Pre-build script (works from any directory, needs jq, writes flutter_app/otlp_config.json):"
echo
echo "  bash scripts/codemagic-otel-prebuild.sh"
echo
echo "Build commands (run from flutter_app/, Flutter 3.35.5 in CI). Keep any existing"
echo "--dart-define flags next to --dart-define-from-file:"
echo
echo "  flutter build appbundle --release --dart-define-from-file=otlp_config.json"
echo "  flutter build ios --release --dart-define-from-file=otlp_config.json"
echo
echo "otlp_config.json contains the token and is gitignored in flutter_app/.gitignore."
