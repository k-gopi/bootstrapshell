module "vnet" {
  source        = "./modules/vnet"
  location      = var.location
  rg_name       = var.rg_name
  vnet_name     = var.vnet_name
  address_space = var.vnet_address_space
}
# module "subnet" {
#   source    = "./modules/subnet"
#   subnets   = var.subnets
#   vnet_name = module.vnet.vnet_name
#   rg_name   = var.rg_name
# }

# module "nsg" {
#   source    = "./modules/nsg"
#   subnets   = var.subnets
#   rg_name   = var.rg_name
#   location  = var.location
# }

# module "jump_vm" {
#   source      = "./modules/vms"
#   vm_name     = "${var.project}-${var.environment}-jumpvm"
#   location    = var.location
#   rg_name     = var.rg_name
#   subnet_id   = module.subnet.subnet_ids["jump"]
#   vm_size     = var.vm_sizes["jump"]
#   disk_type   = var.disk_types["jump"]
#   disk_size_gb = var.disk_sizes["jump"]
#   username    = data.azurerm_key_vault_secret.jump_user.value
#   password    = data.azurerm_key_vault_secret.jump_pass.value
#   public_ip   = true
# }

# # Similar modules for web_vm, app_vm, db_vm

# module "appgw" {
#   source     = "./modules/appgateway"
#   rg_name    = var.rg_name
#   location   = var.location
#   subnet_id  = module.subnet.subnet_ids["appgw"]
#   backend_vms = [
#     module.web_vm.vm_private_ip,
#     module.app_vm.vm_private_ip
#   ]
# }

# module "psql" {
#   source      = "./modules/psql"
#   rg_name     = var.rg_name
#   location    = var.location
#   server_name = data.azurerm_key_vault_secret.psql_server_name.value
#   admin_user  = data.azurerm_key_vault_secret.psql_admin.value
#   admin_pass  = data.azurerm_key_vault_secret.psql_pass.value
#   db_name     = data.azurerm_key_vault_secret.psql_db_name.value
# }
