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

output "container_app_environment_id" {
  description = "The ID of the Azure Container Apps Environment."
  value       = azurerm_container_app_environment.env.id
}

output "frontend_url" {
  description = "The public HTTPS URL of the Frontend Container App."
  value       = "https://${azurerm_container_app.frontend.ingress[0].fqdn}"
}

output "backend_internal_fqdn" {
  description = "The internal FQDN of the Backend Container App."
  value       = azurerm_container_app.backend.ingress[0].fqdn
}
