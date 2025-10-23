# Main Terraform Configuration for Cortex Cloud Azure Onboarding
# This file contains core resources required by other modules

# Data Sources - Get current Azure context
data "azurerm_subscription" "current" {}

data "azuread_client_config" "current" {}

# Resource Group for all Cortex Cloud resources
resource "azurerm_resource_group" "cortex" {
  name     = "rg-cortex-${var.environment}"
  location = var.azure_region

  tags = merge(
    var.tags,
    {
      "ManagedBy"   = "Terraform"
      "Environment" = var.environment
      "Purpose"     = "Cortex Cloud Integration"
    }
  )
}

# Azure AD Application for Cortex Cloud Service Principal
resource "azuread_application" "cortex" {
  display_name = var.app_name
  owners       = [data.azuread_client_config.current.object_id]

  # Required API permissions for CSPM
  required_resource_access {
    # Microsoft Graph
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      # User.Read
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }

    resource_access {
      # Directory.Read.All
      id   = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
      type = "Role"
    }
  }
}

# Service Principal for the Cortex Cloud Application
resource "azuread_service_principal" "cortex" {
  client_id                    = azuread_application.cortex.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]

  tags = ["Cortex", "CSPM", "Terraform"]
}

# Application Password (Client Secret) for Cortex Cloud
# Updated for azuread 3.x: uses application_id and end_date with timeadd()
resource "azuread_application_password" "cortex" {
  display_name   = "Cortex Cloud Client Secret"
  application_id = azuread_application.cortex.id # UPDATED FOR AZUREAD 3.x
  end_date       = timeadd(timestamp(), "8760h") # 1 year from now (UPDATED FOR AZUREAD 3.x)
  rotate_when_changed = {
    rotation = time_rotating.password_rotation.id
  }
}

# Rotation trigger for service principal password
resource "time_rotating" "password_rotation" {
  rotation_days = 365 # Rotate every year
}

# Wait for Service Principal propagation across Azure AD
# This prevents race conditions when assigning roles
resource "time_sleep" "wait_for_sp_propagation" {
  depends_on = [azuread_service_principal.cortex]

  create_duration = "30s"
}

# Optional: Log Analytics Workspace for flow logs and diagnostics
resource "azurerm_log_analytics_workspace" "cortex" {
  count               = var.enable_flow_logs ? 1 : 0
  name                = "la-cortex-${var.environment}"
  location            = azurerm_resource_group.cortex.location
  resource_group_name = azurerm_resource_group.cortex.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = merge(
    var.tags,
    {
      "ManagedBy" = "Terraform"
      "Purpose"   = "Cortex Flow Logs & Diagnostics"
    }
  )
}

# Assign the Custom Reader Role to the Service Principal
resource "azurerm_role_assignment" "cortex_custom_reader" {
  count              = var.create_custom_role ? 1 : 0
  scope              = data.azurerm_subscription.current.id
  role_definition_id = azurerm_role_definition.cortex_custom_reader[0].role_definition_resource_id
  principal_id       = azuread_service_principal.cortex.object_id

  depends_on = [time_sleep.wait_for_sp_propagation]
}
