#!/bin/bash

set -euo pipefail

# Variables
subscription_id="27339cb4-7869-4ef0-b766-ee6720081396"
location="eastus"
resource_group="indbank-dev-rg"
storage_account="indbankdevblobstorage"
container_name="indbank-dev-tfstate"
key_vault_name="indbank-dev-kv"
app_name="indbank-dev-app"
external_user_upn="klakshmi1929_gmail.com#EXT#@klakshmi1929gmail.onmicrosoft.com"

# Azure Login Check
echo "🔐 Checking Azure login..."
az account show > /dev/null || az login

# Create Resource Group
echo "📦 Creating Resource Group: $resource_group"
az group create --name "$resource_group" --location "$location" --subscription "$subscription_id"

# Create Storage Account
echo "💾 Creating Storage Account: $storage_account"
az storage account create --name "$storage_account" --resource-group "$resource_group" --location "$location" --sku Standard_LRS --kind StorageV2

# Create Blob Container
echo "🪣 Creating Blob Container: $container_name"
az storage container create --name "$container_name" --account-name "$storage_account"

# Create Key Vault
echo "🔐 Creating Key Vault: $key_vault_name"
az keyvault create --name "$key_vault_name" --resource-group "$resource_group" --location "$location" --enable-rbac-authorization true

# App Registration
echo "🔧 Creating or Getting App Registration: $app_name"
app_id=$(az ad app list --display-name "$app_name" --query "[0].appId" -o tsv || echo "")
if [[ -z "$app_id" ]]; then
  app_id=$(az ad app create --display-name "$app_name" --query "appId" -o tsv)
  echo "✅ Created App Registration with App ID: $app_id"
else
  echo "✅ Found existing App Registration with App ID: $app_id"
fi

# Service Principal
echo "🔍 Checking Service Principal..."
sp_id=$(az ad sp list --filter "appId eq '$app_id'" --query "[0].id" -o tsv || echo "")
if [[ -z "$sp_id" ]]; then
  sp_id=$(az ad sp create --id "$app_id" --query "id" -o tsv)
  echo "✅ Created Service Principal: $sp_id"
else
  echo "✅ Found existing Service Principal: $sp_id"
fi

# Create Client Secret
echo "🔑 Creating client secret..."
client_secret=$(az ad app credential reset --id "$app_id" --append --query "password" -o tsv)
tenant_id=$(az account show --query "tenantId" -o tsv)

# Get external user objectId
echo "👤 Getting external user object ID..."
external_user_oid=$(az ad user show --id "$external_user_upn" --query id -o tsv)

# Assign 'Key Vault Secrets Officer' to external user
echo "🔁 Assigning 'Key Vault Secrets Officer' role to external user..."
az role assignment create \
  --assignee-object-id "$external_user_oid" \
  --assignee-principal-type User \
  --role "Key Vault Secrets Officer" \
  --scope "/subscriptions/$subscription_id/resourceGroups/$resource_group/providers/Microsoft.KeyVault/vaults/$key_vault_name" || echo "⚠️ Role may already exist."

# Wait for RBAC propagation
echo "🕒 Waiting 90 seconds for role assignment propagation..."
sleep 90

# Store Secret Function
store_secret() {
  local name="$1"
  local value="$2"
  echo "🔐 Storing secret: $name"
  az keyvault secret set --vault-name "$key_vault_name" --name "$name" --value "$value" > /dev/null
}

# Store app registration info
store_secret "appregistration-clientid" "$app_id"
store_secret "appregistration-clientsecret" "$client_secret"
store_secret "appregistration-tenantid" "$tenant_id"
store_secret "subscription-id" "$subscription_id"

# Prompt for VM credentials
echo "🧑‍💻 Enter VM credentials (stored in Key Vault):"

read -p "Jump VM Username: " jumpvm_username
read -s -p "Jump VM Password: " jumpvm_password && echo
read -p "Frontend VM Username: " frontendvm_username
read -s -p "Frontend VM Password: " frontendvm_password && echo
read -p "Application VM Username: " applicationvm_username
read -s -p "Application VM Password: " applicationvm_password && echo
read -p "DB VM Username: " dbvm_username
read -s -p "DB VM Password: " dbvm_password && echo

# Store credentials
store_secret "jumpvm-username" "$jumpvm_username"
store_secret "jumpvm-password" "$jumpvm_password"
store_secret "frontendvm-username" "$frontendvm_username"
store_secret "frontendvm-password" "$frontendvm_password"
store_secret "applicationvm-username" "$applicationvm_username"
store_secret "applicationvm-password" "$applicationvm_password"
store_secret "dbvm-username" "$dbvm_username"
store_secret "dbvm-password" "$dbvm_password"

echo "✅ All secrets stored in Key Vault: $key_vault_name"
