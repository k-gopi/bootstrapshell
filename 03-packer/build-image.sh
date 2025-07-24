#!/bin/bash
set -euo pipefail

echo "📥 Loading secrets from Azure Key Vault..."
source ../02-secrets/get-secrets.sh

echo "🔐 Generating packer.auto.pkrvars.hcl..."
source ./generate-vars.sh   # ✅ Use `source` to preserve environment

echo "🏗️ Ensuring Shared Image Gallery and Image Definition exist..."

# Create SIG
az sig create \
  --resource-group indbank-dev-rg \
  --gallery-name indbankdevsig \
  --location eastus

# Create image definition
az sig image-definition create \
  --resource-group indbank-dev-rg \
  --gallery-name indbankdevsig \
  --gallery-image-definition win2022image \
  --os-type Windows \
  --publisher indbank \
  --offer windowsserver \
  --sku 2022-datacenter \
  --hyper-v-generation V2 \
  --os-state Generalized

echo "📦 Initializing Packer plugins..."
packer init .

echo "🚀 Starting image build with version: ${IMAGE_VERSION}"
packer build -force \
  -var-file="packer.auto.pkrvars.hcl" \
  windows-golden-image.pkr.hcl
