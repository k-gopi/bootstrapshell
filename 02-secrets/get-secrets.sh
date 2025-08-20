#!/bin/bash
set -euo pipefail

# =========================
# Project variables (update if needed)
# =========================
PROJECT_NAME="indbank"
ENVIRONMENT="dev"
KEYVAULT_NAME="${PROJECT_NAME}-${ENVIRONMENT}-kv"

echo "🔑 Fetching secrets from Key Vault: $KEYVAULT_NAME"

# =========================
# Fetch secrets from Azure Key Vault
# =========================
export SUBSCRIPTION_ID=$(az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "${PROJECT_NAME}-${ENVIRONMENT}-subscription-id" --query value -o tsv)
export TENANT_ID=$(az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "${PROJECT_NAME}-${ENVIRONMENT}-tenant-id" --query value -o tsv)
export CLIENT_ID=$(az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "${PROJECT_NAME}-${ENVIRONMENT}-client-id" --query value -o tsv)
export CLIENT_SECRET=$(az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "${PROJECT_NAME}-${ENVIRONMENT}-client-secret" --query value -o tsv)

echo "✅ Secrets loaded into environment variables"
