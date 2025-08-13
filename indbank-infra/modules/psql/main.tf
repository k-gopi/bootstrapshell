resource "azurerm_postgresql_flexible_server" "psql" {
  name                   = var.server_name
  location               = var.location
  resource_group_name    = var.rg_name
  administrator_login    = var.admin_user
  administrator_password = var.admin_pass
  version                = "13"

  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
  zone                   = "1"
  backup_retention_days  = 7

  public_network_access_enabled = true
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.psql.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}
