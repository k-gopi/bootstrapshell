resource "azurerm_network_security_group" "nsg" {
  for_each            = var.subnets
  name                = "${each.key}-nsg"
  location            = var.location
  resource_group_name = var.rg_name
}

# ✅ Example rules: allow RDP to jump, allow HTTP to web, deny all inbound to DB
resource "azurerm_network_security_rule" "allow_rdp_jump" {
  name                        = "allow-rdp"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = azurerm_network_security_group.nsg["jump"].name
}
