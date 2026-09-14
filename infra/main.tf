# Reference the existing Azure Database for MySQL Flexible Server
data "azurerm_mysql_flexible_server" "mysql" {
  name                = var.mysql_server_name
  resource_group_name = var.resource_group_name
}

# Create the logical database (ecommerce_store)
resource "azurerm_mysql_flexible_database" "ecommerce" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  server_name         = data.azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Allow Azure Services and hosted agents to connect (0.0.0.0 - 0.0.0.0)
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure_services" {
  name                = "AllowAzureServices"
  resource_group_name = var.resource_group_name
  server_name         = data.azurerm_mysql_flexible_server.mysql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
