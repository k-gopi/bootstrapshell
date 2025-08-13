resource "azurerm_subnet" "subnet" {
  for_each             = var.subnets
  name                 = "${each.key}-subnet"
  resource_group_name  = var.rg_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [each.value.cidr]
}

output "subnet_ids" {
  value = { for k, v in azurerm_subnet.subnet : k => v.id }
}

output "subnet_names" {
  value = { for k, v in azurerm_subnet.subnet : k => v.name }
}
