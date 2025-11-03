# Azure Audit Logs Configuration for Cortex Cloud
# This file creates the infrastructure for collecting Azure audit logs via Event Hub

# Create Storage Account for Audit Logs
resource "azurerm_storage_account" "audit_logs" {
  count                    = var.enable_audit_logs ? 1 : 0
  name                     = "stcortexaudit${random_string.storage_suffix[0].result}"
  resource_group_name      = azurerm_resource_group.cortex.name
  location                 = azurerm_resource_group.cortex.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security settings
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true # Updated for azurerm 4.x
  allow_nested_items_to_be_public = false

  tags = merge(
    var.tags,
    {
      "ManagedBy" = "Terraform"
      "Purpose"   = "Cortex Audit Logs Storage"
    }
  )
}

# Random string for storage account name uniqueness
resource "random_string" "storage_suffix" {
  count   = var.enable_audit_logs ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

# Create Event Hub Namespace for Audit Logs
resource "azurerm_eventhub_namespace" "audit_logs" {
  count               = var.enable_audit_logs ? 1 : 0
  name                = "eh-cortex-audit-${var.environment}"
  location            = azurerm_resource_group.cortex.location
  resource_group_name = azurerm_resource_group.cortex.name
  sku                 = var.event_hub_sku
  capacity            = 1

  tags = merge(
    var.tags,
    {
      "ManagedBy" = "Terraform"
      "Purpose"   = "Cortex Audit Logs Event Hub"
    }
  )
}

# Create Event Hub for Azure Audit Logs
resource "azurerm_eventhub" "azure_audit" {
  count               = var.enable_audit_logs ? 1 : 0
  name                = "azure-audit-logs"
  namespace_name      = azurerm_eventhub_namespace.audit_logs[0].name
  resource_group_name = azurerm_resource_group.cortex.name
  partition_count     = var.event_hub_partition_count
  message_retention   = 1
}

# Create Consumer Group for Cortex Cloud
resource "azurerm_eventhub_consumer_group" "cortex" {
  count               = var.enable_audit_logs ? 1 : 0
  name                = "cortex-consumer-group"
  namespace_name      = azurerm_eventhub_namespace.audit_logs[0].name
  eventhub_name       = azurerm_eventhub.azure_audit[0].name
  resource_group_name = azurerm_resource_group.cortex.name
}

# Create Authorization Rule for Event Hub
resource "azurerm_eventhub_authorization_rule" "cortex_listen" {
  count               = var.enable_audit_logs ? 1 : 0
  name                = "cortex-listen-rule"
  namespace_name      = azurerm_eventhub_namespace.audit_logs[0].name
  eventhub_name       = azurerm_eventhub.azure_audit[0].name
  resource_group_name = azurerm_resource_group.cortex.name

  listen = true
  send   = false
  manage = false
}

# Create Application Registration for Audit Logs
resource "azuread_application" "audit_logs" {
  count        = var.enable_audit_logs ? 1 : 0
  display_name = "auditlogsapp-${var.app_name}"
  owners       = [data.azuread_client_config.current.object_id]

  # Minimal required permissions for audit log collection
  required_resource_access {
    # Microsoft Graph
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      # User.Read
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }
}

# Create Service Principal for Audit Logs App
# Updated for azuread 3.x: uses client_id instead of application_id
resource "azuread_service_principal" "audit_logs" {
  count                        = var.enable_audit_logs ? 1 : 0
  client_id                    = azuread_application.audit_logs[0].client_id # UPDATED FOR AZUREAD 3.x
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

# Create Application Password for Audit Logs
# Updated for azuread 3.x: uses application_id and end_date with timeadd()
resource "azuread_application_password" "audit_logs" {
  count          = var.enable_audit_logs ? 1 : 0
  application_id = azuread_application.audit_logs[0].id # UPDATED FOR AZUREAD 3.x
  display_name   = "Cortex Audit Logs Secret"
  end_date       = timeadd(timestamp(), "8760h") # 1 year from now (UPDATED FOR AZUREAD 3.x)
  rotate_when_changed = {
    rotation = time_rotating.audit_password_rotation[0].id
  }
}

# Rotation trigger for audit logs password
resource "time_rotating" "audit_password_rotation" {
  count         = var.enable_audit_logs ? 1 : 0
  rotation_days = 365 # Rotate every year
}

# Wait for audit logs service principal propagation
resource "time_sleep" "wait_for_audit_sp_propagation" {
  count           = var.enable_audit_logs ? 1 : 0
  depends_on      = [azuread_service_principal.audit_logs]
  create_duration = "30s"
}

# Assign Event Hub Data Receiver role to audit logs Service Principal
resource "azurerm_role_assignment" "audit_eventhub_receiver" {
  count                = var.enable_audit_logs ? 1 : 0
  scope                = azurerm_eventhub_namespace.audit_logs[0].id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = azuread_service_principal.audit_logs[0].object_id

  depends_on = [time_sleep.wait_for_audit_sp_propagation]
}

# Assign Storage Blob Data Reader role to audit logs Service Principal
resource "azurerm_role_assignment" "audit_storage_reader" {
  count                = var.enable_audit_logs ? 1 : 0
  scope                = azurerm_storage_account.audit_logs[0].id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.audit_logs[0].object_id

  depends_on = [time_sleep.wait_for_audit_sp_propagation]
}

# Configure Diagnostic Settings for Subscription-level Audit Logs
resource "azurerm_monitor_diagnostic_setting" "subscription_audit_logs" {
  count              = var.enable_audit_logs ? 1 : 0
  name               = "cortex-subscription-audit-logs"
  target_resource_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"

  eventhub_authorization_rule_id = azurerm_eventhub_authorization_rule.cortex_listen[0].id
  eventhub_name                  = azurerm_eventhub.azure_audit[0].name

  # Enable Activity Logs
  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "ServiceHealth"
  }

  enabled_log {
    category = "Alert"
  }

  enabled_log {
    category = "Recommendation"
  }

  enabled_log {
    category = "Policy"
  }

  enabled_log {
    category = "Autoscale"
  }

  enabled_log {
    category = "ResourceHealth"
  }
}

# Configure Diagnostic Settings for Azure AD Audit Logs (Tenant-level)
resource "azurerm_monitor_aad_diagnostic_setting" "tenant_audit_logs" {
  count = var.enable_audit_logs && var.enable_azure_ad ? 1 : 0
  name  = "cortex-tenant-audit-logs"

  eventhub_authorization_rule_id = azurerm_eventhub_authorization_rule.cortex_listen[0].id
  eventhub_name                  = azurerm_eventhub.azure_audit[0].name

  # Enable Azure AD Audit Logs
  # Note: retention_policy removed - deprecated in azurerm 4.x
  # Retention now managed at Event Hub or Storage Account level
  enabled_log {
    category = "AuditLogs"
  }

  # Enable Azure AD Sign-in Logs
  enabled_log {
    category = "SignInLogs"
  }

  # Enable Non-Interactive User Sign-In Logs
  enabled_log {
    category = "NonInteractiveUserSignInLogs"
  }

  # Enable Service Principal Sign-In Logs
  enabled_log {
    category = "ServicePrincipalSignInLogs"
  }
}

# Output audit logs configuration for Cortex Cloud manual registration
output "audit_logs_configuration" {
  description = "Audit Logs configuration details for Cortex Cloud"
  value = var.enable_audit_logs ? {
    storage_account_name                     = azurerm_storage_account.audit_logs[0].name
    client_id                                = azuread_application.audit_logs[0].client_id # Updated for azuread 3.x
    namespace                                = azurerm_eventhub_namespace.audit_logs[0].name
    eventhub_name                            = azurerm_eventhub.azure_audit[0].name
    azure_audit_eventhub_consumer_group_name = azurerm_eventhub_consumer_group.cortex[0].name
    tenant_id                                = var.tenant_id
  } : null
}

output "audit_logs_client_secret" {
  description = "Audit Logs Application Client Secret"
  value       = var.enable_audit_logs ? azuread_application_password.audit_logs[0].value : null
  sensitive   = true
}
