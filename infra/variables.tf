variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group where the MySQL Flexible Server exists."
  default     = "rg-name"
}

variable "mysql_server_name" {
  type        = string
  description = "The name of the Azure Database for MySQL Flexible Server."
  default     = "mysql-server-name"
}

variable "database_name" {
  type        = string
  description = "The logical database name to create inside MySQL."
  default     = "ecommerce_store"
}
