resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip_id
  }
}

output "nic_id" {
  value = azurerm_network_interface.nic.id
}

output "private_ip" {
  value = azurerm_network_interface.nic.private_ip_address
}
