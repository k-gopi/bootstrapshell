#!/bin/bash
set -euo pipefail

KEYVAULT_NAME="indbank-dev-kv"
LOCATION="eastus"
IMAGE_VERSION="1.0.2"  # Change this as needed

echo "📥 Loading secrets from Azure Key Vault..."

RESOURCE_GROUP=$(az keyvault secret show --vault-name $KEYVAULT_NAME --name "indbank-dev-rg" --query value -o tsv 2>/dev/null || echo "indbank-dev-rg")
SIG_NAME=$(az keyvault secret show --vault-name $KEYVAULT_NAME --name "indbank-dev-sig-name" --query value -o tsv 2>/dev/null || echo "indbankdevsig")
IMAGE_DEFINITION_NAME=$(az keyvault secret show --vault-name $KEYVAULT_NAME --name "indbank-dev-image-definition" --query value -o tsv 2>/dev/null || echo "win2022image")
MANAGED_IMAGE_NAME=$(az keyvault secret show --vault-name $KEYVAULT_NAME --name "golden-image-win2022" --query value -o tsv 2>/dev/null || echo "golden-image-win2022")

echo "✅ Secrets loaded."

echo "🆔 Fetching Managed Image ID..."
MANAGED_IMAGE_ID=$(az image show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$MANAGED_IMAGE_NAME" \
  --query id -o tsv)

echo "✅ Managed Image ID: $MANAGED_IMAGE_ID"

echo "🚀 Publishing image version $IMAGE_VERSION to SIG..."
az sig image-version create \
  --resource-group "$RESOURCE_GROUP" \
  --gallery-name "$SIG_NAME" \
  --gallery-image-definition "$IMAGE_DEFINITION_NAME" \
  --gallery-image-version "$IMAGE_VERSION" \
  --managed-image "$MANAGED_IMAGE_ID" \
  --location "$LOCATION" \
  --replica-count 1 \
  --verbose

echo "🎉 Image version $IMAGE_VERSION successfully published to SIG!"
