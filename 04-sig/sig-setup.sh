#!/bin/bash
set -euo pipefail

RESOURCE_GROUP="indbank-dev-rg"
GALLERY_NAME="indbankdevsig"
IMAGE_DEFINITION_NAME="win2022image"
LOCATION="eastus"

echo "🛠️ Creating or updating SIG image definition with Hyper-V generation V2..."

az sig image-definition create \
  --resource-group "$RESOURCE_GROUP" \
  --gallery-name "$GALLERY_NAME" \
  --gallery-image-definition "$IMAGE_DEFINITION_NAME" \
  --publisher "indbank" \
  --offer "windowsserver" \
  --sku "2022-datacenter" \
  --os-type "Windows" \
  --hyper-v-generation "V2" \
  --location "$LOCATION" || \
az sig image-definition update \
  --resource-group "$RESOURCE_GROUP" \
  --gallery-name "$GALLERY_NAME" \
  --gallery-image-definition "$IMAGE_DEFINITION_NAME" \
  --hyper-v-generation "V2"

echo "✅ SIG image definition is ready with Hyper-V Generation V2."
