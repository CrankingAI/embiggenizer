#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# provision-swa.sh — Create the resource group and Free-tier Static Web App
#
# Usage:
#   ./scripts/provision-swa.sh
#   ./scripts/provision-swa.sh --dry-run
#
# Lifecycle: rare — run once per environment; idempotent, safe to re-run.
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/clock.sh"    # format_duration
source "$SCRIPT_DIR/lib/target.sh"   # SUBSCRIPTION, RESOURCE_GROUP, SWA_NAME, ...

DRY_RUN=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Create the resource group and the Free-tier Azure Static Web App that host
the Embiggenizer. Existing resources are left as they are.
Lifecycle: rare — run once per environment; idempotent, safe to re-run.

Options:
  --subscription <id>  Azure subscription (default: $DEFAULT_SUBSCRIPTION_NAME, $DEFAULT_SUBSCRIPTION)
  --dry-run            Show what would be created without creating it
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
need az "brew install azure-cli"

if ! az account show --subscription "$SUBSCRIPTION" --output none 2>/dev/null; then
  echo "Error: not logged in, or no access to subscription '$SUBSCRIPTION'."
  echo "  az login"
  exit 1
fi

START_TIME=$(date +%s)
echo "🚀 clock started ($(date '+%H:%M:%S'))"

echo "==> Provisioning the Embiggenizer"
echo "    Subscription:   $SUBSCRIPTION"
echo "    Resource group: $RESOURCE_GROUP ($LOCATION)"
echo "    Static Web App: $SWA_NAME ($SKU)"
[[ "$DRY_RUN" == true ]] && echo "    Dry run: no changes will be made"

echo "==> Resource group"
if [[ "$(az group exists --subscription "$SUBSCRIPTION" --name "$RESOURCE_GROUP")" == true ]]; then
  echo "    exists"
elif [[ "$DRY_RUN" == true ]]; then
  echo "    would create"
else
  az group create \
    --subscription "$SUBSCRIPTION" \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --tags "${TAGS[@]}" \
    --only-show-errors --output none
  echo "    created"
fi

echo "==> Static Web App"
# A missing app is the expected failure here, so its error is replaced by
# the "would create" / "created" path below.
if HOSTNAME_PROD="$(az staticwebapp show \
    --subscription "$SUBSCRIPTION" \
    --resource-group "$RESOURCE_GROUP" \
    --name "$SWA_NAME" \
    --query defaultHostname --output tsv 2>/dev/null)"; then
  echo "    exists: https://$HOSTNAME_PROD"
elif [[ "$DRY_RUN" == true ]]; then
  echo "    would create"
else
  HOSTNAME_PROD="$(az staticwebapp create \
    --subscription "$SUBSCRIPTION" \
    --resource-group "$RESOURCE_GROUP" \
    --name "$SWA_NAME" \
    --location "$LOCATION" \
    --sku "$SKU" \
    --tags "${TAGS[@]}" \
    --query defaultHostname --output tsv --only-show-errors)"
  echo "    created: https://$HOSTNAME_PROD"
fi

echo "==> Next: ./scripts/deploy-site.sh"

DURATION=$(( $(date +%s) - START_TIME ))
echo "🏁 clock stopped (took $(format_duration "$DURATION"), ended $(date '+%H:%M:%S'))"
