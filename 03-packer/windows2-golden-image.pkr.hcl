# Variable Declarations
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "subscription_id" {}

# Azure ARM Source
source "azure-arm" "win2022" {
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

  managed_image_resource_group_name = "indbank-dev-rg"
  managed_image_name                = "golden-image-win2022"
  location                          = "East US"

  os_type         = "Windows"

  image_publisher = "MicrosoftWindowsServer"
  image_offer     = "WindowsServer"
  image_sku       = "2022-datacenter-smalldisk-g2"

  communicator    = "winrm"
  winrm_use_ssl   = true
  winrm_insecure  = true
  winrm_username  = "packeradmin"
  winrm_password  = "SecureP@ssword123!"  # ⚠️ Change before prod
  vm_size         = "Standard_B2ms"

  temp_resource_group_name = "packer-temp-rg"
}

# Build Section
build {
  sources = ["source.azure-arm.win2022"]

  provisioner "powershell" {
    inline = [
      "Set-ExecutionPolicy Unrestricted -Scope Process -Force"
    ]
  }

  provisioner "powershell" {
    scripts = [
      "install-scripts/install-azure-cli.ps1",
      "install-scripts/install-dotnet.ps1",
      "install-scripts/install-docker.ps1",
      "install-scripts/install-node.ps1",
      "install-scripts/install-java.ps1",
      "install-scripts/install-git.ps1",
      "install-scripts/install-packer.ps1",
      "install-scripts/install-terraform.ps1"
    ]
  }
}
