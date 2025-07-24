#!/bin/bash
set -euo pipefail

source ../02-secrets/get-secrets.sh

# Set or auto-generate a semantic version
export IMAGE_VERSION="1.0.1"  # ✅ Export this

echo "🔐 Generating packer.auto.pkrvars.hcl..."
cat > packer.auto.pkrvars.hcl <<EOF
client_id       = "$CLIENT_ID"
client_secret   = "$CLIENT_SECRET"
tenant_id       = "$TENANT_ID"
subscription_id = "$SUBSCRIPTION_ID"
image_version   = "$IMAGE_VERSION"
EOF

echo "✅ packer.auto.pkrvars.hcl created with version $IMAGE_VERSION"
