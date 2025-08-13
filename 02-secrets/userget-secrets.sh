#!/bin/bash
set -euo pipefail

# =========================
# Key Vault name
# =========================
KEY_VAULT_NAME="indbank-dev-kv"

# =========================
# Function to fetch a secret
# =========================
get_secret() {
    az keyvault secret show \
        --name "$1" \
        --vault-name "$KEY_VAULT_NAME" \
        --query value -o tsv
}

# =========================
# Export essential secrets
# =========================
export CLIENT_ID=$(get_secret "indbank-dev-client-id")
export CLIENT_SECRET=$(get_secret "indbank-dev-client-secret")
export TENANT_ID=$(get_secret "indbank-dev-tenant-id")
export SUBSCRIPTION_ID=$(get_secret "indbank-dev-subscription-id")

echo "✅ Essential secrets loaded from Key Vault: $KEY_VAULT_NAME"
