terraform {
  required_version = ">=1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }

  # Backend configuration is passed via backend-dev.hcl at init
  backend "azurerm" {}
}
