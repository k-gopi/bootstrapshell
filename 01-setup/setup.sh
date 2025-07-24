#!/bin/bash
set -euo pipefail

# 📋 Configurable variables
project="indbank"
env="dev"
location="eastus"
resource_group="${project}-${env}-rg"
storage_account="${project}${env}stg"
container_name="${project}-${env}-tfstate"
key_vault_name="${project}-${env}-kv"
app_name="${project}-${env}-app"

echo "📋 Available Azure subscriptions:"
az account list --query "[].{Name:name, ID:id}" -o table

read -p "👉 Enter the Subscription ID to use: " subscription_id
az account set --subscription "$subscription_id"
echo "✅ Selected Subscription: $subscription_id"

read -p "External User UPN (e.g. user@example.com): " external_user_upn

echo "🔐 Azure login check..."
az account show > /dev/null || az login

echo "📦 Creating resource group: $resource_group"
az group create --name "$resource_group" --location "$location"

echo "💾 Creating or checking Storage Account: $storage_account"
if ! az storage account show --name "$storage_account" --resource-group "$resource_group" &>/dev/null; then
  az storage account create --name "$storage_account" --resource-group "$resource_group" --location "$location" --sku Standard_LRS --kind StorageV2
fi

echo "🪣 Creating blob container: $container_name"
az storage container create --name "$container_name" --account-name "$storage_account" --fail-on-exist || echo "⚠️ Blob container may already exist."

echo "🔐 Creating Key Vault: $key_vault_name"
az keyvault create --name "$key_vault_name" --resource-group "$resource_group" --location "$location" --enable-rbac-authorization true

echo "🔧 Creating or retrieving App Registration: $app_name"
app_id=$(az ad app list --display-name "$app_name" --query "[0].appId" -o tsv || echo "")
if [[ -z "$app_id" ]]; then
  app_id=$(az ad app create --display-name "$app_name" --query "appId" -o tsv)
fi

if [[ -z "$app_id" ]]; then
  echo "❌ Failed to retrieve or create App Registration. Exiting..."
  exit 1
fi
echo "✅ App ID: $app_id"

echo "🔍 Creating or retrieving Service Principal..."
sp_id=$(az ad sp list --filter "appId eq '$app_id'" --query "[0].id" -o tsv || echo "")
if [[ -z "$sp_id" ]]; then
  sp_id=$(az ad sp create --id "$app_id" --query "id" -o tsv)
fi
echo "✅ Service Principal ID: $sp_id"

echo "🔑 Generating new client secret..."
client_secret=$(az ad app credential reset --id "$app_id" --append --query "password" -o tsv)

if [[ -z "$client_secret" ]]; then
  echo "❌ Failed to generate client secret. Exiting..."
  exit 1
fi

tenant_id=$(az account show --query "tenantId" -o tsv)

echo "👤 Getting external user object ID..."
external_user_oid=$(az ad user show --id "$external_user_upn" --query id -o tsv)

echo "🔁 Assigning 'Key Vault Secrets Officer' to external user..."
az role assignment create \
  --assignee-object-id "$external_user_oid" \
  --assignee-principal-type User \
  --role "Key Vault Secrets Officer" \
  --scope "/subscriptions/$subscription_id/resourceGroups/$resource_group/providers/Microsoft.KeyVault/vaults/$key_vault_name" || echo "⚠️ Role may already exist."

echo "🔁 Assigning 'Contributor' to Service Principal on Resource Group..."
az role assignment create \
  --assignee "$sp_id" \
  --role "Contributor" \
  --scope "/subscriptions/$subscription_id/resourceGroups/$resource_group" || echo "⚠️ Role may already exist."

echo "🔁 Assigning 'Contributor' to Service Principal on Subscription..."
az role assignment create \
  --assignee "$sp_id" \
  --role "Contributor" \
  --scope "/subscriptions/$subscription_id" || echo "⚠️ Role may already exist."

echo "⏳ Waiting 90 seconds for role assignments to propagate..."
sleep 60

# 📦 Retrieve Storage Key
storage_account_key=$(az storage account keys list --resource-group "$resource_group" --account-name "$storage_account" --query "[0].value" -o tsv)

# 🔐 Function to store secrets
store_secret() {
  local name=$1
  local value=$2
  echo "🔐 Storing secret: $name"
  az keyvault secret set --vault-name "$key_vault_name" --name "$name" --value "$value" > /dev/null
}

# 🔐 Store only indbank-dev-* secrets with tenant ID stored as indbank-dev-tenant-id
store_secret "${project}-${env}-client-id" "$app_id"
store_secret "${project}-${env}-client-secret" "$client_secret"
store_secret "indbank-dev-tenant-id" "$tenant_id"
store_secret "${project}-${env}-subscription-id" "$subscription_id"
store_secret "${project}-${env}-storage-account-name" "$storage_account"
store_secret "${project}-${env}-storage-account-key" "$storage_account_key"

# 🧑‍💻 Prompt for VM credentials
read -p "Jump VM Username: " jump_user
read -s -p "Jump VM Password: " jump_pass && echo
read -p "Web VM Username: " web_user
read -s -p "Web VM Password: " web_pass && echo
read -p "App VM Username: " app_user
read -s -p "App VM Password: " app_pass && echo
read -p "DB VM Username: " db_user
read -s -p "DB VM Password: " db_pass && echo

# 🔐 Store VM credentials
store_secret "${project}-${env}-jump-vm-username" "$jump_user"
store_secret "${project}-${env}-jump-vm-password" "$jump_pass"
store_secret "${project}-${env}-web-vm-username" "$web_user"
store_secret "${project}-${env}-web-vm-password" "$web_pass"
store_secret "${project}-${env}-app-vm-username" "$app_user"
store_secret "${project}-${env}-app-vm-password" "$app_pass"
store_secret "${project}-${env}-db-vm-username" "$db_user"
store_secret "${project}-${env}-db-vm-password" "$db_pass"

# 🧑‍💻 Prompt for PostgreSQL DB details
read -p "PostgreSQL Server Name (FQDN): " psql_server
read -p "PostgreSQL Admin Username: " psql_user
read -s -p "PostgreSQL Admin Password: " psql_pass && echo
read -p "PostgreSQL DB Name: " psql_db

psql_conn_string="Host=$psql_server;Database=$psql_db;Username=$psql_user;Password=$psql_pass;Port=5432;SSL Mode=Require;"

# 🔐 Store DB secrets
store_secret "${project}-${env}-psql-server-name" "$psql_server"
store_secret "${project}-${env}-psql-admin-username" "$psql_user"
store_secret "${project}-${env}-psql-admin-password" "$psql_pass"
store_secret "${project}-${env}-psql-db-name" "$psql_db"
store_secret "${project}-${env}-psql-conn-string" "$psql_conn_string"

echo "✅ All secrets have been securely stored in Key Vault: $key_vault_name"
