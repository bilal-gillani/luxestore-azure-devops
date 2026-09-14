output "mysql_server_fqdn" {
  description = "The fully qualified domain name (FQDN) of the MySQL server."
  value       = data.azurerm_mysql_flexible_server.mysql.fqdn
}

output "mysql_server_name" {
  description = "The name of the MySQL server."
  value       = data.azurerm_mysql_flexible_server.mysql.name
}

output "database_name" {
  description = "The name of the database created."
  value       = azurerm_mysql_flexible_database.ecommerce.name
}
