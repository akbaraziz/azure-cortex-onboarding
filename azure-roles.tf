# Custom Role Definition for Cortex Cloud
# Created if any Cortex Cloud feature is enabled
resource "azurerm_role_definition" "cortex_custom_reader" {
  count       = (var.enable_cloud_visibility || var.enable_agentless_scanning || var.enable_serverless_scanning || var.enable_agent_based_protection || var.enable_remediation) ? 1 : 0
  name        = "Cortex Cloud Custom Reader - ${var.environment}"
  scope       = data.azurerm_subscription.current.id
  description = "Custom role for Cortex Cloud with additional read permissions for security monitoring and compliance"

  permissions {
    actions = concat(
      [
        # Core Read Permissions - CSPM requires extensive read access
        "*/read",

        # Critical Actions (beyond read)
        # Network Security and Flow Logs
        "Microsoft.Network/networkWatchers/queryFlowLogStatus/*",
        "Microsoft.Network/networkWatchers/queryConnectionMonitors/action",
        "Microsoft.Network/networkWatchers/securityGroupView/action",
        "Microsoft.Network/networkInterfaces/effectiveNetworkSecurityGroups/action",
        "Microsoft.Network/networkInterfaces/effectiveRouteTable/action",
        "Microsoft.Network/virtualwans/vpnconfiguration/action",

        # Storage and Access
        "Microsoft.Storage/storageAccounts/listKeys/action",
        "Microsoft.Storage/storageAccounts/blobServices/containers/read",
        "Microsoft.Web/sites/config/list/action",

        # Container and Registry
        "Microsoft.ContainerRegistry/registries/webhooks/getCallbackConfig/action",
        "Microsoft.ContainerRegistry/registries/pull/read",
        "Microsoft.ContainerInstance/containerGroups/containers/exec/action",

        # Database Keys and Connection Strings
        "Microsoft.DocumentDB/databaseAccounts/listConnectionStrings/action",
        "Microsoft.DocumentDB/databaseAccounts/listKeys/action",
        "Microsoft.DocumentDB/databaseAccounts/readonlykeys/action",

        # Compute Disk Access
        "Microsoft.Compute/disks/beginGetAccess/action",

        # Policy Insights
        "Microsoft.PolicyInsights/policyStates/queryResults/action",

        # Resource Graph
        "Microsoft.ResourceGraph/resources/read"
      ],
      var.custom_role_actions
    )

    not_actions = [
      # Explicitly deny destructive operations
      "*/write",
      "*/delete",
      "Microsoft.Authorization/*/write",
      "Microsoft.Authorization/*/delete",
      "Microsoft.Resources/deployments/write",
      "Microsoft.Resources/deployments/delete"
    ]

    data_actions = [
      # Storage blob read access for audit logs and flow logs
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"
    ]

    not_data_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id
  ]
}

# Optional: Create Management Group level role assignment if needed
# Uncomment and configure if you need management group level access
/*
resource "azurerm_role_assignment" "management_group_reader" {
  count                = var.enable_management_group_access ? 1 : 0
  scope                = "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.cortex.object_id

  depends_on = [time_sleep.wait_for_sp_propagation]
}
*/

# Grant Azure AD Directory Reader role for Cloud Visibility feature
# Required for reading Azure AD information and user/group data
resource "azuread_directory_role" "directory_readers" {
  count        = var.enable_cloud_visibility ? 1 : 0
  display_name = "Directory Readers"
}

resource "azuread_directory_role_assignment" "cortex_directory_reader" {
  count               = var.enable_cloud_visibility ? 1 : 0
  role_id             = azuread_directory_role.directory_readers[0].template_id
  principal_object_id = azuread_service_principal.cortex.object_id

  depends_on = [time_sleep.wait_for_sp_propagation]
}

# Security Reader role for Azure Security Center
resource "azurerm_role_assignment" "security_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Security Reader"
  principal_id         = azuread_service_principal.cortex.object_id

  depends_on = [time_sleep.wait_for_sp_propagation]
}
