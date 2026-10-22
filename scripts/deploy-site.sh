#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# deploy-site.sh — Upload src/ to the Static Web App and smoke-test it
#
# Usage:
#   ./scripts/deploy-site.sh
#   ./scripts/deploy-site.sh --dry-run
#
# Deploys to two SWA environments: "production" (the random default hostname
# a custom domain will attach to) and "embiggenizer" (a named environment
# whose hostname contains the word). See docs/decisions/0001.
#
# Lifecycle: routine — safe to re-run; use --dry-run to preview.
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/lib/clock.sh"    # format_duration
source "$SCRIPT_DIR/lib/target.sh"   # SUBSCRIPTION, RESOURCE_GROUP, SWA_NAME, SLUG_ENV

# Pinned: an unpinned npx would hand the deployment token to whatever
# version npm calls latest at the moment the script runs.
SWA_CLI="@azure/static-web-apps-cli@2.0.10"
APP_DIR="$REPO_ROOT/src"
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Upload src/ to the Embiggenizer's Static Web App, in both the "production"
and "$SLUG_ENV" environments, then check that each one serves the page.
Lifecycle: routine — safe to re-run; use --dry-run to preview.

Options:
  --subscription <id>  Azure subscription (default: $DEFAULT_SUBSCRIPTION_NAME, $DEFAULT_SUBSCRIPTION)
  --dry-run            Show what would be deployed without deploying
  -h, --help           Show this help

Examples:
  $(basename "$0")
  $(basename "$0") --dry-run
EOF
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help|help) usage ;;
    --dry-run)      DRY_RUN=true; shift ;;
    --subscription)
      [[ -n "${2:-}" ]] || { echo "Error: --subscription requires an id" >&2; usage 1; }
      SUBSCRIPTION="$2"; shift 2 ;;
    *)              echo "Error: unknown option '$1'" >&2; usage 1 ;;
  esac
done

need() {
  command -v "$1" &>/dev/null && return 0
  echo "Error: '$1' is not installed."
  echo "  $2"
  exit 1
}
need az   "brew install azure-cli"
need npx  "brew install node"
need curl "brew install curl"

[[ -f "$APP_DIR/index.html" ]] || { echo "Error: $APP_DIR/index.html not found."; exit 1; }

if ! az account show --subscription "$SUBSCRIPTION" --output none 2>/dev/null; then
  echo "Error: not logged in, or no access to subscription '$SUBSCRIPTION'."
  echo "  az login"
  exit 1
fi

if ! az staticwebapp show \
    --subscription "$SUBSCRIPTION" \
    --resource-group "$RESOURCE_GROUP" \
    --name "$SWA_NAME" \
    --output none 2>/dev/null; then
  echo "Error: Static Web App '$SWA_NAME' not found in '$RESOURCE_GROUP'."
  echo "  ./scripts/provision-swa.sh"
  exit 1
fi

START_TIME=$(date +%s)
echo "🚀 clock started ($(date '+%H:%M:%S'))"

echo "==> Deploying the Embiggenizer"
echo "    Subscription:   $SUBSCRIPTION"
echo "    Static Web App: $SWA_NAME ($RESOURCE_GROUP)"
echo "    Source:         $APP_DIR"
echo "    Environments:   production, $SLUG_ENV"

if [[ "$DRY_RUN" == true ]]; then
  echo "    Dry run: no changes will be made. Files that would be uploaded:"
  (cd "$APP_DIR" && find . -type f | sort | sed 's/^\.\//      /')
else
  # The token goes to the CLI through its environment, not argv, so it
  # never shows up in the process list.
  SWA_CLI_DEPLOYMENT_TOKEN="$(az staticwebapp secrets list \
    --subscription "$SUBSCRIPTION" \
    --resource-group "$RESOURCE_GROUP" \
    --name "$SWA_NAME" \
    --query properties.apiKey --output tsv --only-show-errors)"
  export SWA_CLI_DEPLOYMENT_TOKEN

  for env_name in production "$SLUG_ENV"; do
    echo "==> Uploading to $env_name"
    npx --yes "$SWA_CLI" deploy "$APP_DIR" --env "$env_name" --no-use-keychain
  done
  unset SWA_CLI_DEPLOYMENT_TOKEN
fi

# host_for_env <env> -> the environment's hostname, or nothing if it doesn't
# exist. SWA lists production under the build id "default".
host_for_env() {
  local build_id="$1"
  [[ "$build_id" == production ]] && build_id=default
  az staticwebapp environment list \
    --subscription "$SUBSCRIPTION" \
    --resource-group "$RESOURCE_GROUP" \
    --name "$SWA_NAME" \
    --query "[?buildId=='$build_id'].hostname | [0]" --output tsv --only-show-errors
}

echo "==> URLs"
FAILED=false
for env_name in production "$SLUG_ENV"; do
  host="$(host_for_env "$env_name")"
  if [[ -z "$host" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      echo "    $env_name: not there yet; the first deploy creates it"
    else
      echo "    ❌ $env_name: environment not found"
      FAILED=true
    fi
    continue
  fi
  url="https://$host/"
  if [[ "$DRY_RUN" == true ]]; then
    echo "    $env_name: $url"
  elif curl --fail --silent --show-error --max-time 30 "$url" | grep -q "<title>Embiggenizer</title>"; then
    echo "    ✅ $env_name: $url"
  else
    echo "    ❌ $env_name: $url did not serve the Embiggenizer"
    FAILED=true
  fi
done

DURATION=$(( $(date +%s) - START_TIME ))
echo "🏁 clock stopped (took $(format_duration "$DURATION"), ended $(date '+%H:%M:%S'))"

[[ "$FAILED" == false ]] || exit 1
