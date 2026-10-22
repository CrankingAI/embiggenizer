#!/usr/bin/env bash
# target.sh — where the Embiggenizer lives in Azure. Sourced, not executed.
# Defines variables only. Every script passes --subscription "$SUBSCRIPTION"
# explicitly; none of them runs `az account set`.
#
# shellcheck disable=SC2034  # every variable here is read by a sourcing script

# EffAz-Prod, the subscription the other CrankingAI static sites use.
DEFAULT_SUBSCRIPTION="f906a716-7602-4c74-bb5b-f98fbc385b0c"
SUBSCRIPTION="$DEFAULT_SUBSCRIPTION"

RESOURCE_GROUP="rg-embiggenizer"
SWA_NAME="swa-embiggenizer"
LOCATION="eastus2"
SKU="Free"
TAGS=(project=embiggenizer env=prod)

# A named SWA environment's hostname includes its name, which the
# production hostname cannot. See docs/decisions/0001.
SLUG_ENV="embiggenizer"
