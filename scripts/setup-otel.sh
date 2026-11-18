#!/bin/bash

# Dash0 + GitHub secrets setup for Minecraft Finder
#
# Creates the Dash0 datasets and ingest-only tokens for the Flutter app and
# stores the OTLP endpoint and headers as GitHub Actions secrets. Run it from
# your own machine. No token value is stored in the repository, printed, or
# passed as a command line argument. See SETUP_OTEL.md.

set -euo pipefail

REPO="Lock128/minecraft-finder"
OTLP_ENDPOINT="https://ingress.eu-west-1.aws.dash0.com"
DEFAULT_API_URL="https://api.eu-west-1.aws.dash0.com"
MIN_DASH0_VERSION="1.22"

DRY_RUN=false
ROTATE=false
ONLY=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
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
Usage: DASH0_AUTH_TOKEN=<admin token> scripts/setup-otel.sh [options]

Creates or updates the Dash0 datasets and ingest-only tokens for Minecraft
Finder and sets these GitHub Actions secrets on Lock128/minecraft-finder:
  NONPROD_FLUTTER_OTLP_ENDPOINT, NONPROD_FLUTTER_OTLP_HEADERS
  PROD_FLUTTER_OTLP_ENDPOINT,    PROD_FLUTTER_OTLP_HEADERS

Options:
  --dry-run             Validate with dash0 --dry-run and print the plan. Sets nothing.
  --rotate              Delete an existing "<slug>-flutter-ingest" token and create a new one.
                        Without it, an existing token makes the script fail.
  --only nonprod|prod   Handle only one environment.
  --help                Show this help.

Environment:
  DASH0_AUTH_TOKEN      Required. Dash0 admin token (never accepted as an argument).
  DASH0_API_URL         Optional. Default: https://api.eu-west-1.aws.dash0.com

Prerequisites:
  dash0 CLI >= 1.22, jq, and gh logged in with permission to write Actions
  secrets on Lock128/minecraft-finder (classic token with "repo" scope, or
  fine-grained token with Repository permission "Secrets: Read and write").
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        --rotate) ROTATE=true ;;
        --only)
            [ $# -ge 2 ] || die "--only needs a value: nonprod or prod"
            ONLY="$2"
            shift
            ;;
        --only=*) ONLY="${1#--only=}" ;;
        --help|-h)
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

case "$ONLY" in
    ""|nonprod|prod) ;;
    *) die "--only must be nonprod or prod, got: $ONLY" ;;
esac

# Environments: label, slug, secret prefix
ENV_LABELS=()
ENV_SLUGS=()
ENV_PREFIXES=()
if [ "$ONLY" != "prod" ]; then
    ENV_LABELS+=("nonprod"); ENV_SLUGS+=("nonprod-minecraft-finder"); ENV_PREFIXES+=("NONPROD")
fi
if [ "$ONLY" != "nonprod" ]; then
    ENV_LABELS+=("prod"); ENV_SLUGS+=("minecraft-finder"); ENV_PREFIXES+=("PROD")
fi

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------

check_prerequisites() {
    print_status "Checking prerequisites"

    command -v jq >/dev/null 2>&1 || die "jq is not installed. Install it (for example: brew install jq)."
    command -v gh >/dev/null 2>&1 || die "gh is not installed. See https://cli.github.com/"
    command -v dash0 >/dev/null 2>&1 || die "dash0 CLI is not installed. Install it with: brew install --cask dash0hq/dash0-cli/dash0 (or see https://github.com/dash0hq/dash0-cli/releases)"

    [ -n "${DASH0_AUTH_TOKEN:-}" ] || die "DASH0_AUTH_TOKEN is not set. Export a Dash0 admin token first (do not pass it as an argument): export DASH0_AUTH_TOKEN=<admin token>"

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

    if [ "$DRY_RUN" = true ]; then
        print_warning "Dry run: skipping GitHub secret permission check"
        if ! gh auth status >/dev/null 2>&1; then
            print_warning "gh is not logged in. A real run needs: gh auth login"
        fi
        return
    fi

    gh auth status >/dev/null 2>&1 || die "gh is not logged in. Run: gh auth login"
    if ! gh api "repos/$REPO/actions/secrets/public-key" >/dev/null 2>&1; then
        print_error "gh cannot access Actions secrets of $REPO (typically HTTP 403)."
        print_error "Fix: log in with a token that may write Actions secrets:"
        print_error "  - classic token with the 'repo' scope, or"
        print_error "  - fine-grained token for $REPO with Repository permission 'Secrets: Read and write'."
        print_error "Then run 'gh auth login' (or 'gh auth refresh -s repo') and check with:"
        print_error "  gh api repos/$REPO/actions/secrets/public-key"
        print_error "If GH_TOKEN or GITHUB_TOKEN is set in your shell, it overrides the gh login: unset it."
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Working directory for temporary files (removed on exit)
# ---------------------------------------------------------------------------

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

write_dataset_yaml() {
    local slug="$1" file="$2"
    cat >"$file" <<EOF
apiVersion: dash0.com/v1alpha1
kind: Dash0Dataset
metadata:
  name: $slug
  labels:
    dash0.com/id: $slug
spec:
  slug: $slug
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
EOF
}

write_token_yaml() {
    local slug="$1" file="$2"
    cat >"$file" <<EOF
apiVersion: dash0.com/v1alpha1
kind: Dash0AuthToken
metadata:
  name: ${slug}-flutter-ingest
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

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

check_prerequisites
make_work_dir

print_status "Repository:   $REPO"
print_status "Dash0 API:    $DASH0_API_URL"
print_status "OTLP ingress: $OTLP_ENDPOINT"
[ "$DRY_RUN" = true ] && print_status "Mode:         dry run (nothing is created or set)"
[ "$ROTATE" = true ] && print_status "Rotation:     existing tokens are deleted and recreated"

# Step 1: look up existing tokens for every environment before changing anything.
EXISTING_IDS=()
for i in "${!ENV_SLUGS[@]}"; do
    slug="${ENV_SLUGS[$i]}"
    token_name="${slug}-flutter-ingest"
    existing_id="$(find_token_id "$token_name")"
    EXISTING_IDS+=("$existing_id")
    if [ -n "$existing_id" ] && [ "$ROTATE" != true ]; then
        die "Auth token '$token_name' already exists. Dash0 returns a token secret only at creation, so it cannot be read again. Re-run with --rotate to delete it and create a new one (the old token stops working at once), or set the GitHub secrets manually from a token you saved."
    fi
done

# Step 2: datasets and tokens per environment.
for i in "${!ENV_SLUGS[@]}"; do
    label="${ENV_LABELS[$i]}"
    slug="${ENV_SLUGS[$i]}"
    prefix="${ENV_PREFIXES[$i]}"
    token_name="${slug}-flutter-ingest"
    existing_id="${EXISTING_IDS[$i]}"

    echo
    print_status "Environment $label (dataset $slug)"

    ds_yaml="$WORK_DIR/ds-$slug.yaml"
    tok_yaml="$WORK_DIR/tok-$slug.yaml"
    secret_file="$WORK_DIR/$slug.secret"
    write_dataset_yaml "$slug" "$ds_yaml"
    write_token_yaml "$slug" "$tok_yaml"

    if [ "$DRY_RUN" = true ]; then
        dash0 -X datasets create -f "$ds_yaml" --dry-run || die "Dataset definition for $slug failed validation."
        if [ -n "$existing_id" ]; then
            print_status "Plan: delete auth token $token_name (id $existing_id), then create it again"
        fi
        # A dry run cannot validate a token creation while the same name exists.
        if [ -z "$existing_id" ]; then
            dash0 -X auth-tokens create -f "$tok_yaml" --dry-run || die "Token definition for $slug failed validation."
        fi
        print_status "Plan: upsert dataset $slug"
        print_status "Plan: create ingest-only token $token_name (ingest:*, restricted to dataset $slug)"
        print_status "Plan: set secrets ${prefix}_FLUTTER_OTLP_ENDPOINT and ${prefix}_FLUTTER_OTLP_HEADERS on $REPO"
        continue
    fi

    dash0 -X datasets create -f "$ds_yaml" || die "Could not create or update dataset $slug."
    print_success "Dataset $slug is up to date"

    if [ -n "$existing_id" ]; then
        print_warning "Deleting existing auth token $token_name"
        dash0 -X auth-tokens delete "$existing_id" --force || die "Could not delete auth token $token_name."
    fi

    dash0 -X auth-tokens create -f "$tok_yaml" --secret-file "$secret_file" >/dev/null || die "Could not create auth token $token_name."
    [ -s "$secret_file" ] || die "Dash0 did not write a secret for $token_name."
    print_success "Created auth token $token_name"

    # The token never appears in a command line: it is read from the file and
    # piped to gh on stdin (gh reads the secret value from stdin without --body).
    token="$(tr -d '\r\n' <"$secret_file")"
    printf '%s' "$OTLP_ENDPOINT" | gh secret set "${prefix}_FLUTTER_OTLP_ENDPOINT" --repo "$REPO" \
        || die "Could not set ${prefix}_FLUTTER_OTLP_ENDPOINT."
    printf 'Authorization=Bearer %s,Dash0-Dataset=%s' "$token" "$slug" \
        | gh secret set "${prefix}_FLUTTER_OTLP_HEADERS" --repo "$REPO" \
        || die "Could not set ${prefix}_FLUTTER_OTLP_HEADERS. The token for $slug was created and is lost: re-run with --rotate."
    unset token
    rm -f "$secret_file"
    print_success "Set ${prefix}_FLUTTER_OTLP_ENDPOINT and ${prefix}_FLUTTER_OTLP_HEADERS"
done

echo
if [ "$DRY_RUN" = true ]; then
    print_success "Dry run finished. Nothing was created or set."
else
    print_success "Done. Re-run the web deployment so the new secrets take effect."
fi
