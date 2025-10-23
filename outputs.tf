output "subscription_id" {
  description = "Azure Subscription ID"
  value       = data.azurerm_subscription.current.subscription_id
}

output "tenant_id" {
  description = "Azure Tenant ID"
  value       = var.tenant_id
}

output "application_id" {
  description = "Application (Client) ID"
  value       = azuread_application.cortex.client_id # Updated for azuread 3.x
}

output "application_object_id" {
  description = "Application Object ID"
  value       = azuread_application.cortex.object_id
}

output "service_principal_object_id" {
  description = "Service Principal Object ID"
  value       = azuread_service_principal.cortex.object_id
}

output "application_secret" {
  description = "Application Secret (Client Secret)"
  value       = azuread_application_password.cortex.value
  sensitive   = true
}

output "custom_role_id" {
  description = "Custom Role Definition ID"
  value       = var.create_custom_role ? azurerm_role_definition.cortex_custom_reader[0].id : null
}

output "resource_group_name" {
  description = "Resource Group Name for Cortex resources"
  value       = azurerm_resource_group.cortex.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = var.enable_flow_logs ? azurerm_log_analytics_workspace.cortex[0].id : null
}

output "cortex_onboarding_info" {
  description = "Information needed for Cortex Cloud onboarding"
  value = {
    subscription_id      = data.azurerm_subscription.current.subscription_id
    tenant_id            = var.tenant_id
    client_id            = azuread_application.cortex.client_id # Updated for azuread 3.x
    service_principal_id = azuread_service_principal.cortex.object_id
    azure_account_name   = var.azure_account_name
    environment          = var.environment

    # Audit Logs Configuration (if enabled)
    audit_logs_enabled = var.enable_audit_logs
    audit_logs_config = var.enable_audit_logs ? {
      storage_account_name = try(azurerm_storage_account.audit_logs[0].name, null)
      client_id            = try(azuread_application.audit_logs[0].client_id, null) # Updated for azuread 3.x
      namespace            = try(azurerm_eventhub_namespace.audit_logs[0].name, null)
      eventhub_name        = try(azurerm_eventhub.azure_audit[0].name, null)
      consumer_group_name  = try(azurerm_eventhub_consumer_group.cortex[0].name, null)
    } : null
  }
}

output "next_steps" {
  description = "Next steps for completing the integration"
  value       = <<-EOT
    Next Steps:
    1. Login to Cortex Cloud Portal
    2. Navigate to Settings > Cloud Accounts
    3. Click "Add Cloud Account" and select "Azure"
    4. Use the following information:
       - Subscription ID: ${data.azurerm_subscription.current.subscription_id}
       - Tenant ID: ${var.tenant_id}
       - Client ID: ${azuread_application.cortex.client_id}  # Updated for azuread 3.x
       - Client Secret: (Use the application_secret output - run: terraform output -raw application_secret)
    5. Configure monitoring and compliance policies
    6. Verify the integration status
  EOT
}
