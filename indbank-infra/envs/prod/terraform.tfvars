project        = "indbank"
environment    = "prod"
location       = "eastus2"

rg_name        = "indbank-prod-rg"
key_vault_name = "indbank-prod-kv"

backend_rg             = "indbank-prod-rg"
backend_storage_account = "indbankprodstg"
backend_container       = "indbank-prod-tfstate"

vnet_name        = "indbank-prod-vnet"
vnet_address_space = "10.20.0.0/16"

subnets = {
  jump   = { cidr = "10.20.1.0/24" }
  web    = { cidr = "10.20.2.0/24" }
  app    = { cidr = "10.20.3.0/24" }
  db     = { cidr = "10.20.4.0/24" }
  appgw  = { cidr = "10.20.5.0/24" }
}

# VM Sizes (bigger for production)
vm_sizes = {
  jump     = "Standard_B2ms"
  frontend = "Standard_D2s_v3"
  app      = "Standard_D2s_v3"
  db       = "Standard_D4s_v3"
}

disk_types = {
  jump     = "Standard_LRS"
  frontend = "Premium_LRS"
  app      = "Premium_LRS"
  db       = "Premium_LRS"
}

disk_sizes = {
  jump     = 64
  frontend = 128
  app      = 128
  db       = 256
}
