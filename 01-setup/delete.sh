#!/bin/bash

resourceGroup="indbank-dev-rg"

echo "⏳ Deleting resource group: $resourceGroup ..."
az group delete --name "$resourceGroup" --yes --no-wait

echo "🗑️ Deletion started. All resources in $resourceGroup will be deleted asynchronously."