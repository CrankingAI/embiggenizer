#!/usr/bin/env bash
# target.sh — where the Embiggenizer lives in Azure. Sourced, not executed.
# Defines variables only. Every script passes --subscription "$SUBSCRIPTION"
# explicitly; none of them runs `az account set`.
#
# shellcheck disable=SC2034  # every variable here is read by a sourcing script

DEFAULT_SUBSCRIPTION_NAME="EffAz-Run"
DEFAULT_SUBSCRIPTION="32c6835c-b37c-47d6-b34a-fbd262a70ef9"
SUBSCRIPTION="$DEFAULT_SUBSCRIPTION"

RESOURCE_GROUP="rg-embiggenizer"
SWA_NAME="swa-embiggenizer"
LOCATION="eastus2"
SKU="Free"
TAGS=(project=embiggenizer env=prod)

# A named SWA environment's hostname includes its name, which the
# production hostname cannot. See docs/decisions/0001.
SLUG_ENV="embiggenizer"
