project      = "indbank"
environment  = "dev"
location     = "eastus"
rg_name      = "indbank-dev-rg"
key_vault_name = "indbank-dev-kv"

backend_rg               = "indbank-dev-rg"
backend_storage_account  = "indbankdevstg"
backend_container        = "indbank-dev-tfstate"

vnet_name          = "indbank-dev-vnet"
vnet_address_space = ["10.0.0.0/16"]

subnets = {
  jump  = { cidr = "10.0.1.0/24" }
  web   = { cidr = "10.0.2.0/24" }
  app   = { cidr = "10.0.3.0/24" }
  db    = { cidr = "10.0.4.0/24" }
  appgw = { cidr = "10.0.5.0/24" }
}

vm_sizes = {
  jump     = "Standard_B1s"
  frontend = "Standard_B1s"
  app      = "Standard_B1s"
  db       = "Standard_B1s"
}

disk_types = {
  jump     = "Standard_LRS"
  frontend = "Standard_LRS"
  app      = "Standard_LRS"
  db       = "Standard_LRS"
}

disk_sizes = {
  jump     = 30
  frontend = 30
  app      = 30
  db       = 30
}
