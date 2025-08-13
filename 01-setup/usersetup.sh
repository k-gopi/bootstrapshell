#!/bin/bash
set -euo pipefail

# =========================
# Variables - customize as needed
# =========================
PROJECT_NAME="indbank"
ENVIRONMENT="dev"
LOCATION="eastus"

# Resource names
RG_NAME="${PROJECT_NAME}-${ENVIRONMENT}-rg"
STORAGE_ACCOUNT_NAME="${PROJECT_NAME}${ENVIRONMENT}stg"   # must be globally unique, lowercase
CONTAINER_NAME="${PROJECT_NAME}-${ENVIRONMENT}-tfstate"
KEYVAULT_NAME="${PROJECT_NAME}-${ENVIRONMENT}-kv"
APP_REG_NAME="${PROJECT_NAME}-${ENVIRONMENT}-app"

# =========================
# 1. Ensure logged in
# =========================
echo "Ensure you are logged in with Owner/Contributor/User Access Admin/Key Vault Admin roles."
az account show --query "{user:user.name, subscription:id}" -o table

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

# =========================
# 2. Resource Group
# =========================
echo "Creating Resource Group: $RG_NAME"
az group create --name "$RG_NAME" --location "$LOCATION"

# =========================
# 3. Storage Account
# =========================
echo "Creating Storage Account: $STORAGE_ACCOUNT_NAME"
az storage account create \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --https-only true

echo "Enabling blob versioning"
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --enable-versioning true

echo "Getting Storage Account Key..."
STORAGE_KEY=$(az storage account keys list \
  --resource-group "$RG_NAME" \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --query "[0].value" -o tsv)

echo "Creating Blob Container: $CONTAINER_NAME"
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --account-key "$STORAGE_KEY"

# =========================
# 4. Key Vault
# =========================
echo "Creating Key Vault: $KEYVAULT_NAME"
az keyvault create \
  --name "$KEYVAULT_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku standard \
  --enable-rbac-authorization true

# Wait for Key Vault readiness
echo "Waiting 120 seconds for Key Vault readiness..."
sleep 120

# =========================
# 5. App Registration & Service Principal
# =========================
APP_REG_ID=$(az ad app list --display-name "$APP_REG_NAME" --query "[0].appId" -o tsv || echo "")
if [ -z "$APP_REG_ID" ]; then
    echo "Creating App Registration: $APP_REG_NAME"
    APP_REG_ID=$(az ad app create --display-name "$APP_REG_NAME" --query appId -o tsv)
else
    echo "✅ App Registration already exists."
fi

echo "Waiting 120 seconds for App Registration..."
sleep 120

SP_APP_ID=$(az ad sp list --filter "appId eq '$APP_REG_ID'" --query "[0].appId" -o tsv || echo "")
if [ -z "$SP_APP_ID" ]; then
    az ad sp create --id "$APP_REG_ID"
    SP_APP_ID="$APP_REG_ID"
fi

echo "Waiting 120 seconds for SP propagation..."
sleep 120

SP_PASS=$(az ad app credential reset --id "$APP_REG_ID" --query password -o tsv)

# =========================
# 6. Safe secret storage function
# =========================
safe_store_secret() {
  local name=$1
  local value=$2

  # Purge deleted secrets if they exist
  deleted=$(az keyvault secret list-deleted --vault-name "$KEYVAULT_NAME" --query "[?name=='$name'].name" -o tsv)
  if [[ -n "$deleted" ]]; then
    echo "Purging deleted secret: $name"
    az keyvault secret purge --vault-name "$KEYVAULT_NAME" --name "$name"
    sleep 5
  fi

  echo "Storing secret: $name"
  az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "$name" --value "$value" > /dev/null
}

# =========================
# 7. Store basic secrets
# =========================
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-subscription-id" "$SUBSCRIPTION_ID"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-tenant-id" "$TENANT_ID"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-client-id" "$APP_REG_ID"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-client-secret" "$SP_PASS"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-storage-account-name" "$STORAGE_ACCOUNT_NAME"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-storage-account-key" "$STORAGE_KEY"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-keyvault-name" "$KEYVAULT_NAME"

# =========================
# 8. Prompt for VM credentials
# =========================
read -p "Jump VM Username: " jump_user
read -s -p "Jump VM Password: " jump_pass && echo
read -p "Web VM Username: " web_user
read -s -p "Web VM Password: " web_pass && echo
read -p "App VM Username: " app_user
read -s -p "App VM Password: " app_pass && echo
read -p "DB VM Username: " db_user
read -s -p "DB VM Password: " db_pass && echo

safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-jump-vm-username" "$jump_user"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-jump-vm-password" "$jump_pass"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-web-vm-username" "$web_user"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-web-vm-password" "$web_pass"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-app-vm-username" "$app_user"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-app-vm-password" "$app_pass"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-db-vm-username" "$db_user"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-db-vm-password" "$db_pass"

# =========================
# 9. Prompt for PostgreSQL details
# =========================
read -p "PostgreSQL Server Name (FQDN): " psql_server
read -p "PostgreSQL Admin Username: " psql_user
read -s -p "PostgreSQL Admin Password: " psql_pass && echo
read -p "PostgreSQL DB Name: " psql_db

PSQL_CONN="Host=$psql_server;Database=$psql_db;Username=$psql_user;Password=$psql_pass;Port=5432;SSL Mode=Require;"

safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-psql-server-name" "$psql_server"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-psql-admin-username" "$psql_user"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-psql-admin-password" "$psql_pass"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-psql-db-name" "$psql_db"
safe_store_secret "${PROJECT_NAME}-${ENVIRONMENT}-psql-conn-string" "$PSQL_CONN"

# =========================
# 10. Output summary
# =========================
echo "-----------------------------------"
echo "✅ All secrets stored in Key Vault: $KEYVAULT_NAME"
echo "-----------------------------------"
