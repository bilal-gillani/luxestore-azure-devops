# Reference the existing Resource Group
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Reference the existing Azure Database for MySQL Flexible Server
data "azurerm_mysql_flexible_server" "mysql" {
  name                = var.mysql_server_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Reference the existing Azure Container Registry
data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ------------------------------------------------------------------------------
# MySQL Logical Database & Firewall Rules
# ------------------------------------------------------------------------------

# Create the logical database (ecommerce_store)
resource "azurerm_mysql_flexible_database" "ecommerce" {
  name                = var.database_name
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = data.azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Allow Azure Services and hosted agents to connect (0.0.0.0 - 0.0.0.0)
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure_services" {
  name                = "AllowAzureServices"
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = data.azurerm_mysql_flexible_server.mysql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# ------------------------------------------------------------------------------
# Monitoring & Azure Container Apps Environment
# ------------------------------------------------------------------------------

# Log Analytics Workspace for Container Apps diagnostic and console logs
resource "azurerm_log_analytics_workspace" "law" {
  name                = "log-analytics-workspace-name"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Shared Azure Container Apps Environment
resource "azurerm_container_app_environment" "env" {
  name                       = "cae-luxestore"
  location                   = data.azurerm_resource_group.rg.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

locals {
  backend_revision_url = "http://backend--${var.green_revision_suffix}.internal.${azurerm_container_app_environment.env.default_domain}"
}

# ------------------------------------------------------------------------------
# Managed Identity & ACR Role Assignment
# ------------------------------------------------------------------------------

# User-Assigned Managed Identity for Container Apps to authenticate with ACR
resource "azurerm_user_assigned_identity" "aca_identity" {
  name                = "uai-luxestore-aca"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Grant AcrPull role to the User-Assigned Identity on the ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}

# ------------------------------------------------------------------------------
# Backend Container App (Node.js 20 Express REST API - Internal Ingress)
# ------------------------------------------------------------------------------
resource "azurerm_container_app" "backend" {
  name                         = "backend"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = data.azurerm_resource_group.rg.name

  # Multiple mode: allows two revisions (blue + green) to coexist simultaneously.
  # Blue = live production revision. Green = staging candidate at 0% traffic.
  revision_mode = "Multiple"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = data.azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  ingress {
    external_enabled           = false
    target_port                = 3000
    allow_insecure_connections = true
    transport                  = "auto"

    # ── BOOTSTRAP MODE (is_initial_deployment = true) ────────────────────────
    # First pipeline run: no blue revision exists yet.
    # Use latest_revision=true so the single created revision gets 100% traffic.
    dynamic "traffic_weight" {
      for_each = var.is_initial_deployment ? [1] : []
      content {
        latest_revision = true
        percentage      = 100
      }
    }

    # ── NORMAL MODE (is_initial_deployment = false, run 2+) ──────────────────
    # Blue: existing live revision (fetched from Azure CLI before TF Plan).
    # DeployGreen stage: blue=100%, green=0% — users unaffected.
    # TrafficSwitch stage: blue=0%, green=100% — green goes live.
    dynamic "traffic_weight" {
      for_each = var.is_initial_deployment ? [] : [1]
      content {
        revision_suffix = var.backend_blue_revision_suffix
        percentage      = var.blue_traffic_weight
      }
    }

    # Green: newly deployed revision — always at 0% during DeployGreen stage.
    # Backend is internal-only so no label URL is needed (frontend tests via proxy).
    dynamic "traffic_weight" {
      for_each = var.is_initial_deployment ? [] : [1]
      content {
        revision_suffix = var.green_revision_suffix
        percentage      = var.green_traffic_weight
      }
    }
  }

  secret {
    name  = "db-password"
    value = var.db_password
  }

  secret {
    name  = "jwt-secret"
    value = var.jwt_secret
  }

  template {
    # Explicitly name the revision being created on this pipeline run.
    # Format: v-{Build.BuildId} e.g. v-5123 → full name: backend--v-5123
    revision_suffix = var.green_revision_suffix
    min_replicas    = 1
    max_replicas    = 3

    container {
      name   = "backend"
      image  = "${data.azurerm_container_registry.acr.login_server}/${var.backend_image_repository}:${var.image_tag}"
      cpu    = 0.5
      memory = "1.0Gi"

      env {
        name  = "PORT"
        value = "3000"
      }
      env {
        name  = "NODE_ENV"
        value = "production"
      }
      env {
        name  = "DB_HOST"
        value = data.azurerm_mysql_flexible_server.mysql.fqdn
      }
      env {
        name  = "DB_PORT"
        value = "3306"
      }
      env {
        name  = "DB_USER"
        value = var.db_user
      }
      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }
      env {
        name  = "DB_NAME"
        value = azurerm_mysql_flexible_database.ecommerce.name
      }
      env {
        name        = "JWT_SECRET"
        secret_name = "jwt-secret"
      }
      env {
        name  = "JWT_EXPIRES_IN"
        value = "7d"
      }
      env {
        name  = "CORS_ORIGIN"
        value = "*"
      }
    }
  }

  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_mysql_flexible_database.ecommerce,
    azurerm_mysql_flexible_server_firewall_rule.allow_azure_services
  ]
}


# ------------------------------------------------------------------------------
# Frontend Container App (Nginx 1.27 Static + Reverse Proxy - External Ingress)
# ------------------------------------------------------------------------------
resource "azurerm_container_app" "frontend" {
  name                         = "frontend"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = data.azurerm_resource_group.rg.name

  # Multiple mode: allows blue and green revisions to coexist simultaneously.
  revision_mode = "Multiple"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = data.azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  ingress {
    external_enabled = true
    target_port      = 80
    transport        = "auto"

    # ── BOOTSTRAP MODE (is_initial_deployment = true) ────────────────────────
    # First pipeline run: no blue revision exists yet.
    # Use latest_revision=true so the single created revision gets 100% traffic.
    dynamic "traffic_weight" {
      for_each = var.is_initial_deployment ? [1] : []
      content {
        latest_revision = true
        percentage      = 100
      }
    }

    # ── NORMAL MODE (is_initial_deployment = false, run 2+) ──────────────────
    # Blue: existing live revision receiving all user traffic.
    # DeployGreen stage: blue=100%, green=0%.
    # TrafficSwitch stage: blue=0%, green=100%.
    dynamic "traffic_weight" {
      for_each = var.is_initial_deployment ? [] : [1]
      content {
        revision_suffix = var.frontend_blue_revision_suffix
        percentage      = var.blue_traffic_weight
      }
    }

    # Green: staging revision at 0% public traffic during DeployGreen stage.
    # The "green" label generates a dedicated public URL for smoke testing:
    # https://frontend---green.{hash}.southindia.azurecontainerapps.io
    dynamic "traffic_weight" {
      for_each = var.is_initial_deployment ? [] : [1]
      content {
        revision_suffix = var.green_revision_suffix
        percentage      = var.green_traffic_weight
        label           = "green"
      }
    }
  }

  template {
    # Explicitly name the revision being created on this pipeline run.
    # Format: v-{Build.BuildId} e.g. v-5123 → full name: frontend--v-5123
    revision_suffix = var.green_revision_suffix
    min_replicas    = 1
    max_replicas    = 3

    container {
      name   = "frontend"
      image  = "${data.azurerm_container_registry.acr.login_server}/${var.frontend_image_repository}:${var.image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "BACKEND_URL"
        value = local.backend_revision_url # was: "http://backend"
      }
    }
  }

  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_container_app.backend
  ]
}
