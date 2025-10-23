variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "app_name" {
  description = "Name of the Azure AD Application for Cortex Cloud"
  type        = string
  default     = "CortexCloudApp"
}

variable "cortex_api_url" {
  description = "Cortex Cloud API URL (e.g., https://api.prismacloud.io)"
  type        = string
}

variable "cortex_access_key" {
  description = "Cortex Cloud Access Key"
  type        = string
  sensitive   = true
}

variable "cortex_secret_key" {
  description = "Cortex Cloud Secret Key"
  type        = string
  sensitive   = true
}

variable "azure_account_name" {
  description = "Name for the Azure account in Cortex Cloud"
  type        = string
  default     = "Azure-Prod"
}

variable "environment" {
  description = "Environment name (e.g., prod, dev, staging)"
  type        = string
  default     = "prod"
}

variable "azure_region" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

# Cortex Cloud Feature Configuration
variable "enable_cloud_visibility" {
  description = "Enable Cloud Visibility Compliance and Governance - Basic resource discovery and compliance monitoring (Requires: Reader role)"
  type        = bool
  default     = true
}

variable "enable_agentless_scanning" {
  description = "Enable Agentless Scanning - VM and container vulnerability scanning via snapshots (Requires: Reader + Disk access)"
  type        = bool
  default     = true
}

variable "enable_serverless_scanning" {
  description = "Enable Serverless Function Scanning - Scan Azure Functions for vulnerabilities (Requires: Reader role)"
  type        = bool
  default     = true
}

variable "enable_agent_based_protection" {
  description = "Enable Agent-Based Workload Protection - Install and manage Defender agents (Requires: Contributor role on targeted resources)"
  type        = bool
  default     = false
}

variable "enable_remediation" {
  description = "Enable Remediation - Auto-remediate security findings (Requires: Contributor role on specific resources)"
  type        = bool
  default     = false
}

# Azure Infrastructure Options
# These are Azure infrastructure features (not Cortex Cloud features)
# They are typically enabled by default for security best practices
variable "monitor_flow_logs" {
  description = "Enable network flow logs monitoring"
  type        = bool
  default     = true
}

variable "enable_audit_logs" {
  description = "Enable Azure activity and diagnostic log collection"
  type        = bool
  default     = true
}

variable "enable_azure_ad" {
  description = "Enable Azure AD Directory Reader role for enhanced visibility"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics Workspace"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    "Environment" = "Production"
    "Application" = "Cortex Cloud"
    "Terraform"   = "true"
  }
}

variable "custom_role_actions" {
  description = "Additional actions for custom role (beyond standard Reader permissions)"
  type        = list(string)
  default = [
    # Network Watcher and Flow Logs
    "Microsoft.Network/networkWatchers/queryFlowLogStatus/*",
    "Microsoft.Network/networkWatchers/securityGroupView/action",
    "Microsoft.Network/networkInterfaces/effectiveNetworkSecurityGroups/action",
    "Microsoft.Network/networkInterfaces/effectiveRouteTable/action",
    "Microsoft.Network/virtualwans/vpnconfiguration/action",

    # Storage Account Keys and SAS (required for audit logs)
    "Microsoft.Storage/storageAccounts/listKeys/action",
    "Microsoft.Web/sites/config/list/action",

    # Container Registry
    "Microsoft.ContainerRegistry/registries/webhooks/getCallbackConfig/action",

    # Cosmos DB and DocumentDB
    "Microsoft.DocumentDB/databaseAccounts/listConnectionStrings/action",
    "Microsoft.DocumentDB/databaseAccounts/listKeys/action",
    "Microsoft.DocumentDB/databaseAccounts/readonlykeys/action",

    # Container Instance Exec (for debugging/scanning)
    "Microsoft.ContainerInstance/containerGroups/containers/exec/action"
  ]
}
