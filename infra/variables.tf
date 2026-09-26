variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group where resources exist or will be deployed."
  default     = "rg-name"
}

variable "mysql_server_name" {
  type        = string
  description = "The name of the Azure Database for MySQL Flexible Server."
  default     = "mysql-name"
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

# ------------------------------------------------------------------------------
# Blue-Green Deployment Variables
# ------------------------------------------------------------------------------

variable "is_initial_deployment" {
  type        = bool
  description = "True on first pipeline run when no blue revision exists yet. Switches traffic_weight to latest_revision=true mode instead of named revision suffixes."
  default     = false
}

variable "green_revision_suffix" {
  type        = string
  description = "Suffix for the new green (staging) revision being deployed. Format: v-{Build.BuildId}. Must start with a letter."
  default     = "v-initial"
}

variable "backend_blue_revision_suffix" {
  type        = string
  description = "Suffix of the currently live (blue) backend revision. Fetched from Azure CLI before Terraform Plan. Unused when is_initial_deployment=true."
  default     = "none"
}

variable "frontend_blue_revision_suffix" {
  type        = string
  description = "Suffix of the currently live (blue) frontend revision. Fetched from Azure CLI before Terraform Plan. Unused when is_initial_deployment=true."
  default     = "none"
}

variable "blue_traffic_weight" {
  type        = number
  description = "Traffic % to route to the blue (live) revision. 100 during DeployGreen stage, 0 during TrafficSwitch stage."
  default     = 100
}

variable "green_traffic_weight" {
  type        = number
  description = "Traffic % to route to the green (staging) revision. 0 during DeployGreen stage, 100 during TrafficSwitch stage."
  default     = 0
}
