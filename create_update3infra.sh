#!/bin/bash
set -euo pipefail

echo "📋 Mee Azure account lo available subscriptions:"
az account list --query "[].{Name:name, ID:id}" -o table

read -p "👉 Use cheyyali anukune Subscription ID ivvandi: " subscription_id
az account set --subscription "$subscription_id"
echo "✅ Selected Subscription: $subscription_id"

location="eastus"
resource_group="indbank-dev-rg"
storage_account="indbankdevblobstorage"
container_name="indbank-dev-tfstate"
key_vault_name="indbank-dev-kv"
app_name="indbank-dev-app"

read -p "External User UPN (e.g. user@example.com): " external_user_upn

echo "🔐 Azure login check..."
az account show > /dev/null || az login

echo "📦 Creating Resource Group: $resource_group"
az group create --name "$resource_group" --location "$location"

echo "💾 Checking Storage Account existence..."
if ! az storage account show --name "$storage_account" --resource-group "$resource_group" &>/dev/null; then
  echo "Creating Storage Account: $storage_account"
  az storage account create --name "$storage_account" --resource-group "$resource_group" --location "$location" --sku Standard_LRS --kind StorageV2
else
  echo "Storage Account already exists."
fi

echo "🪣 Creating Blob Container: $container_name"
az storage container create --name "$container_name" --account-name "$storage_account" --fail-on-exist

echo "🔐 Creating Key Vault: $key_vault_name"
az keyvault create --name "$key_vault_name" --resource-group "$resource_group" --location "$location" --enable-rbac-authorization true

echo "🔧 Creating or Getting App Registration: $app_name"
app_id=$(az ad app list --display-name "$app_name" --query "[0].appId" -o tsv || echo "")
if [[ -z "$app_id" ]]; then
  app_id=$(az ad app create --display-name "$app_name" --query "appId" -o tsv)
  echo "✅ Created App Registration with App ID: $app_id"
else
  echo "✅ Found existing App Registration with App ID: $app_id"
fi

echo "🔍 Checking Service Principal..."
sp_id=$(az ad sp list --filter "appId eq '$app_id'" --query "[0].id" -o tsv || echo "")
if [[ -z "$sp_id" ]]; then
  sp_id=$(az ad sp create --id "$app_id" --query "id" -o tsv)
  echo "✅ Created Service Principal: $sp_id"
else
  echo "✅ Found existing Service Principal: $sp_id"
fi

echo "🔑 Creating client secret..."
client_secret=$(az ad app credential reset --id "$app_id" --append --query "password" -o tsv)
tenant_id=$(az account show --query "tenantId" -o tsv)

echo "👤 Getting external user object ID..."
external_user_oid=$(az ad user show --id "$external_user_upn" --query id -o tsv)

echo "🔁 Assigning 'Key Vault Secrets Officer' role to external user..."
az role assignment create \
  --assignee-object-id "$external_user_oid" \
  --assignee-principal-type User \
  --role "Key Vault Secrets Officer" \
  --scope "/subscriptions/$subscription_id/resourceGroups/$resource_group/providers/Microsoft.KeyVault/vaults/$key_vault_name" || echo "⚠️ Role may already exist."

echo "🕒 Waiting 90 seconds for role assignment propagation..."
sleep 90

store_secret() {
  local name="$1"
  local value="$2"
  echo "🔐 Storing secret: $name"
  az keyvault secret set --vault-name "$key_vault_name" --name "$name" --value "$value" > /dev/null
}

store_secret "appregistration-clientid" "$app_id"
store_secret "appregistration-clientsecret" "$client_secret"
store_secret "appregistration-tenantid" "$tenant_id"
store_secret "subscription-id" "$subscription_id"

echo "🧑‍💻 Enter VM credentials (stored securely in Key Vault):"

read -p "Jump VM Username: " jumpvm_username
read -s -p "Jump VM Password: " jumpvm_password && echo

read -p "Frontend VM Username: " frontendvm_username
read -s -p "Frontend VM Password: " frontendvm_password && echo

read -p "Application VM Username: " applicationvm_username
read -s -p "Application VM Password: " applicationvm_password && echo

read -p "DB VM Username: " dbvm_username
read -s -p "DB VM Password: " dbvm_password && echo

store_secret "jumpvm-username" "$jumpvm_username"
store_secret "jumpvm-password" "$jumpvm_password"
store_secret "frontendvm-username" "$frontendvm_username"
store_secret "frontendvm-password" "$frontendvm_password"
store_secret "applicationvm-username" "$applicationvm_username"
store_secret "applicationvm-password" "$applicationvm_password"
store_secret "dbvm-username" "$dbvm_username"
store_secret "dbvm-password" "$dbvm_password"

echo "✅ All secrets stored successfully in Key Vault: $key_vault_name"
