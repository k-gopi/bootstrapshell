packer {
  required_plugins {
    azure = {
      version = ">= 2.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

source "azure-arm" "win2022" {
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

  managed_image_resource_group_name = "indbank-dev-rg"
  managed_image_name                = "golden-image-win2022"
  location                          = "East US"

  os_type         = "Windows"

  # ✅ Use a Hyper-V Gen2 compatible image SKU
  image_publisher = "MicrosoftWindowsServer"
  image_offer     = "WindowsServer"
  image_sku       = "2022-datacenter-smalldisk-g2"  # 👈 This is Gen2 compatible

  communicator    = "winrm"
  winrm_use_ssl   = true
  winrm_insecure  = true
  winrm_username  = "packeradmin"
  winrm_password  = "SecureP@ssword123!"  # Change this before production
  vm_size         = "Standard_B2ms"

  temp_resource_group_name = "packer-temp-rg"
}

build {
  sources = ["source.azure-arm.win2022"]

  provisioner "powershell" {
    inline = [
      "Set-ExecutionPolicy Unrestricted -Scope Process -Force"
    ]
  }

  provisioner "powershell" {
    scripts = [
      "install-scripts/install-azure-cli.ps1"
    ]
  }
}
