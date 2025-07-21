#!/bin/bash

KEY_VAULT_NAME="indbank-dev-kv"

get_secret() {
  az keyvault secret show --name "$1" --vault-name "$KEY_VAULT_NAME" --query value -o tsv
}

export CLIENT_ID=$(get_secret "appregistration-clientid")
export CLIENT_SECRET=$(get_secret "appregistration-clientsecret")
export TENANT_ID=$(get_secret "appregistration-tenantid")
export SUBSCRIPTION_ID=$(get_secret "subscription-id")

echo "✅ Secrets loaded from Key Vault"
