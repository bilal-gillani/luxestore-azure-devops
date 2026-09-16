variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group where resources exist or will be deployed."
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

variable "acr_name" {
  type        = string
  description = "The name of the Azure Container Registry."
  default     = "acr-name"
}

variable "backend_image_repository" {
  type        = string
  description = "The repository name for the backend image in ACR."
  default     = "luxestore-backend"
}

variable "frontend_image_repository" {
  type        = string
  description = "The repository name for the frontend image in ACR."
  default     = "luxestore-frontend"
}

variable "image_tag" {
  type        = string
  description = "The container image tag to deploy (e.g. Build.BuildId or latest)."
  default     = "latest"
}

variable "db_user" {
  type        = string
  description = "The application database username."
  default     = "ecommerce_user"
}

variable "db_password" {
  type        = string
  description = "The application database password."
  sensitive   = true
}

variable "jwt_secret" {
  type        = string
  description = "JWT secret key for backend authentication token signing."
  sensitive   = true
}
