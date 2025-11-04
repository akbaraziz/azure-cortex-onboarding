# Terraform Plan Walkthrough Guide
**Project:** azure-cortex-ui
**Date:** October 23, 2025
**Purpose:** Understanding what `terraform plan` will show you

---

## 🎯 Overview

This guide walks you through how to read and understand the Terraform plan output for your Azure Cortex UI deployment.

---

## 📋 Prerequisites

Before running `terraform plan`, you need to provide your Azure and Cortex Cloud credentials.

### Step 1: Create `terraform.tfvars`

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your actual values (DO NOT commit this file!)
nano terraform.tfvars
```

### Required Values:
```hcl
# Azure Configuration
subscription_id = "YOUR-AZURE-SUBSCRIPTION-ID"
tenant_id       = "YOUR-AZURE-TENANT-ID"

# Cortex Cloud Configuration
cortex_api_url     = "https://api.prismacloud.io"  # Or your region
cortex_access_key  = "YOUR-CORTEX-ACCESS-KEY"
cortex_secret_key  = "YOUR-CORTEX-SECRET-KEY"

# Azure Account Name
azure_account_name = "Azure-Production"
environment        = "prod"
```

### Step 2: Authenticate with Azure

```bash
# Login to Azure
az login

# Set the correct subscription
az account set --subscription YOUR-SUBSCRIPTION-ID

# Verify
az account show
```

---

## 🚀 Running Terraform Plan

```bash
# Generate the plan
terraform plan -out=migration.tfplan

# OR save output to a file for review
terraform plan -out=migration.tfplan 2>&1 | tee plan-output.txt
```

---

## 📊 Understanding the Plan Output

### Section 1: Header Information

```
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create
  ~ update in-place
  - destroy
  -/+ destroy and then create replacement

Terraform will perform the following actions:
```

**What this means:**
- **`+` (green)**: New resource will be created
- **`~` (yellow)**: Existing resource will be modified
- **`-` (red)**: Resource will be destroyed
- **`-/+` (red/green)**: Resource will be replaced (destroyed then recreated)

---

### Section 2: Resource Details

For each resource, you'll see:

```hcl
# azurerm_resource_group.cortex will be created
+ resource "azurerm_resource_group" "cortex" {
    + id       = (known after apply)
    + location = "eastus"
    + name     = "rg-cortex-prod"
    + tags     = {
        + "Environment" = "Production"
        + "ManagedBy"   = "Terraform"
        + "Project"     = "Cortex Cloud CSPM"
      }
  }
```

**Breaking this down:**
- **Resource Type**: `azurerm_resource_group` (Azure Resource Group)
- **Resource Name**: `cortex` (Terraform reference name)
- **Action**: Will be created (indicated by `+`)
- **Attributes**:
  - `id = (known after apply)` - Value won't be known until after creation
  - `location = "eastus"` - Region where it will be created
  - `name = "rg-cortex-prod"` - Actual Azure name
  - `tags` - Metadata tags

---

## 📝 Expected Resources in Your Plan

Based on your configuration with all features enabled, here's what you should see:

### ✅ New Resources to be Created (Total: ~20-25)

#### 1. **Core Infrastructure** (5 resources)
```
+ azurerm_resource_group.cortex
  - Creates: Resource group "rg-cortex-prod" in East US
  - Purpose: Container for all Cortex resources

+ azurerm_log_analytics_workspace.cortex[0]
  - Creates: Log Analytics workspace for flow logs
  - Purpose: Centralized logging and monitoring
  - Retention: 30 days (configurable)

+ random_string.storage_suffix[0]
  - Creates: 8-character random suffix
  - Purpose: Ensures storage account name uniqueness
```

#### 2. **Azure AD Application & Service Principal** (5 resources)
```
+ azuread_application.cortex
  - Creates: Azure AD App Registration "CortexCloudApp"
  - Purpose: Identity for Cortex Cloud
  - Permissions: Microsoft Graph API access

+ azuread_service_principal.cortex
  - Creates: Service Principal for the app
  - Purpose: Enables authentication
  - Tags: Cortex, CSPM, Terraform

+ azuread_application_password.cortex
  - Creates: Client Secret (password)
  - Purpose: Authentication credential
  - Expiry: 1 year from creation (with auto-rotation)
  - ⚠️  This is SENSITIVE - store securely!

+ time_rotating.password_rotation
  - Creates: Rotation trigger
  - Purpose: Auto-rotate password every 365 days

+ time_sleep.wait_for_sp_propagation
  - Creates: 30-second wait period
  - Purpose: Prevents race conditions
```

#### 3. **RBAC Roles & Assignments** (3 resources)
```
+ azurerm_role_definition.cortex_custom_reader[0]
  - Creates: Custom "Cortex Cloud Custom Reader" role
  - Scope: Subscription-level
  - Permissions: Extensive read access + specific actions
  - Restrictions: No write/delete/auth changes

+ azurerm_role_assignment.security_reader
  - Assigns: Built-in "Security Reader" role
  - To: Cortex service principal
  - Scope: Subscription

+ azurerm_role_assignment.cortex_custom_reader[0]
  - Assigns: Custom reader role
  - To: Cortex service principal
  - Scope: Subscription
```

#### 4. **Azure AD Directory Access** (2 resources)
```
+ azuread_directory_role.directory_readers[0]
  - Creates: Reference to "Directory Readers" role
  - Purpose: Tenant-level read access

+ azuread_directory_role_assignment.cortex_directory_reader[0]
  - Assigns: Directory Readers role
  - To: Cortex service principal
  - Purpose: Read Azure AD users, groups, apps
```

#### 5. **Audit Logs Infrastructure** (9 resources)
```
+ azurerm_storage_account.audit_logs[0]
  - Creates: Storage account "stcortexaudit<random>"
  - Security: TLS 1.2, HTTPS-only, no public access
  - Purpose: Audit log storage

+ azurerm_eventhub_namespace.audit_logs[0]
  - Creates: Event Hub namespace "eh-cortex-audit-prod"
  - SKU: Standard
  - Capacity: 1 throughput unit

+ azurerm_eventhub.azure_audit[0]
  - Creates: Event Hub "azure-audit-logs"
  - Partitions: 2
  - Retention: 1 day

+ azurerm_eventhub_consumer_group.cortex[0]
  - Creates: Consumer group "cortex-consumer-group"
  - Purpose: Cortex Cloud reads from this

+ azurerm_eventhub_authorization_rule.cortex_listen[0]
  - Creates: "cortex-listen-rule"
  - Permissions: Listen only (no send/manage)

+ azuread_application.audit_logs[0]
  - Creates: Separate app "auditlogsapp-CortexCloudApp"
  - Purpose: Dedicated identity for audit log access

+ azuread_service_principal.audit_logs[0]
  - Creates: Service principal for audit logs app

+ azuread_application_password.audit_logs[0]
  - Creates: Client secret for audit logs
  - Expiry: 1 year with auto-rotation

+ time_rotating.audit_password_rotation[0]
  - Creates: Rotation trigger for audit password
```

#### 6. **Role Assignments for Audit Logs** (2 resources)
```
+ azurerm_role_assignment.audit_eventhub_receiver[0]
  - Assigns: "Azure Event Hubs Data Receiver" role
  - To: Audit logs service principal
  - Scope: Event Hub namespace

+ azurerm_role_assignment.audit_storage_reader[0]
  - Assigns: "Storage Blob Data Reader" role
  - To: Audit logs service principal
  - Scope: Storage account
```

#### 7. **Diagnostic Settings** (2 resources)
```
+ azurerm_monitor_diagnostic_setting.subscription_audit_logs[0]
  - Creates: Subscription-level diagnostics
  - Logs: Administrative, Security, ServiceHealth, Alert,
          Recommendation, Policy, Autoscale, ResourceHealth
  - Destination: Event Hub

+ azurerm_monitor_aad_diagnostic_setting.tenant_audit_logs[0]
  - Creates: Tenant-level Azure AD diagnostics
  - Logs: AuditLogs, SignInLogs, NonInteractiveUserSignInLogs,
          ServicePrincipalSignInLogs
  - Destination: Event Hub
  - ⚠️  No retention_policy blocks (deprecated in azurerm 4.x)
```

---

## 📈 Expected Plan Summary

At the end, you'll see a summary like this:

```
Plan: 25 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + application_id              = "00000000-0000-0000-0000-000000000000"
  + application_object_id       = "00000000-0000-0000-0000-000000000000"
  + application_secret          = (sensitive value)
  + audit_logs_client_secret    = (sensitive value)
  + audit_logs_configuration    = {
      + client_id                                = "00000000-0000-0000-0000-000000000000"
      + azure_audit_eventhub_consumer_group_name = "cortex-consumer-group"
      + eventhub_name                            = "azure-audit-logs"
      + namespace                                = "eh-cortex-audit-prod"
      + storage_account_name                     = "stcortexaudit<random>"
      + tenant_id                                = "00000000-0000-0000-0000-000000000000"
    }
  + cortex_onboarding_info      = {
      + audit_logs_config    = {
          + client_id            = "00000000-0000-0000-0000-000000000000"
          + consumer_group_name  = "cortex-consumer-group"
          + eventhub_name        = "azure-audit-logs"
          + namespace            = "eh-cortex-audit-prod"
          + storage_account_name = "stcortexaudit<random>"
        }
      + audit_logs_enabled   = true
      + azure_account_name   = "Azure-Production"
      + client_id            = "00000000-0000-0000-0000-000000000000"
      + environment          = "prod"
      + service_principal_id = "00000000-0000-0000-0000-000000000000"
      + subscription_id      = "00000000-0000-0000-0000-000000000000"
      + tenant_id            = "00000000-0000-0000-0000-000000000000"
    }
  + custom_role_id              = "/subscriptions/.../providers/Microsoft.Authorization/roleDefinitions/..."
  + log_analytics_workspace_id  = "/subscriptions/.../resourceGroups/rg-cortex-prod/providers/Microsoft.OperationalInsights/workspaces/la-cortex-prod"
  + next_steps                  = <<-EOT
        Next Steps:
        1. Login to Cortex Cloud Portal
        2. Navigate to Settings > Cloud Accounts
        3. Click "Add Cloud Account" and select "Azure"
        4. Use the following information:
           - Subscription ID: ...
           - Tenant ID: ...
           - Client ID: ...
           - Client Secret: (Use the application_secret output)
        5. Configure monitoring and compliance policies
        6. Verify the integration status
    EOT
  + resource_group_name         = "rg-cortex-prod"
  + service_principal_object_id = "00000000-0000-0000-0000-000000000000"
  + subscription_id             = "00000000-0000-0000-0000-000000000000"
  + tenant_id                   = "00000000-0000-0000-0000-000000000000"
```

**What this means:**
- **25 new resources** will be created
- **0 resources** will be modified
- **0 resources** will be destroyed
- **Multiple outputs** will be available for Cortex Cloud configuration

---

## ✅ What to Look For (Quality Checks)

### ✅ **Good Signs:**
1. **No Destroy Actions** - No `-` symbols (no resources deleted)
2. **No Replacements** - No `-/+` symbols (no resources recreated)
3. **All Creates** - Only `+` symbols (new resources only)
4. **Sensitive Values Hidden** - Secrets show `(sensitive value)`
5. **Logical Resource Names** - Clear, consistent naming convention
6. **Proper Scopes** - Roles assigned at correct subscription/tenant levels
7. **Security Settings** - TLS 1.2, HTTPS-only, etc.

### ⚠️ **Warning Signs to Review:**
1. **Any `-` (destroy)** - Investigate why resource is being deleted
2. **Any `-/+` (replace)** - May cause downtime or data loss
3. **Unexpected updates** - Check what's changing and why
4. **Missing resources** - Compare against expected list above
5. **Incorrect names** - Check environment suffix, region, etc.

### 🛑 **Stop If You See:**
1. **Mass destruction** - Many resources marked for deletion
2. **Permission downgrades** - Custom role losing critical permissions
3. **Security config changes** - TLS version, HTTPS enforcement disabled
4. **Unknown resources** - Resources you didn't expect

---

## 🔍 Detailed Review Checklist

Before applying the plan, verify:

### Azure AD Resources:
- [ ] Application name is correct ("CortexCloudApp" or your custom name)
- [ ] Service principal has correct tags
- [ ] Password rotation is configured (time_rotating resources present)
- [ ] Microsoft Graph permissions are included
- [ ] Directory Readers role assignment is present (if enable_azure_ad = true)

### RBAC Roles:
- [ ] Custom role name includes environment ("Cortex Cloud Custom Reader - prod")
- [ ] Custom role has read permissions (*/read)
- [ ] Custom role denies write/delete (not_actions present)
- [ ] Security Reader role is assigned
- [ ] Custom role is assigned (if create_custom_role = true)

### Audit Logs (if enabled):
- [ ] Storage account name follows pattern (stcortexaudit<random>)
- [ ] Storage account has TLS 1.2 + HTTPS-only
- [ ] Event Hub namespace name follows pattern (eh-cortex-audit-<env>)
- [ ] Event Hub is named "azure-audit-logs"
- [ ] Consumer group is "cortex-consumer-group"
- [ ] Authorization rule has LISTEN permissions only
- [ ] Separate audit logs app + service principal created
- [ ] Event Hub Data Receiver role assigned
- [ ] Storage Blob Data Reader role assigned

### Diagnostic Settings:
- [ ] Subscription-level diagnostics configured
- [ ] Tenant-level AAD diagnostics configured (if enable_azure_ad = true)
- [ ] All log categories enabled (Administrative, Security, etc.)
- [ ] NO retention_policy blocks (deprecated in azurerm 4.x)
- [ ] Event Hub authorization rule ID referenced correctly

### Resource Group & Log Analytics:
- [ ] Resource group name follows pattern (rg-cortex-<env>)
- [ ] Resource group location matches azure_region variable
- [ ] Log Analytics workspace created (if enable_flow_logs = true)
- [ ] Log Analytics retention matches log_retention_days variable

### Outputs:
- [ ] All sensitive values marked as `(sensitive value)`
- [ ] Client ID output present
- [ ] Application secret output present (sensitive)
- [ ] Service principal object ID output present
- [ ] Custom role ID output present (if enabled)
- [ ] Audit logs configuration output present (if enabled)
- [ ] Next steps output includes helpful instructions

---

## 📝 Sample Plan Review Session

Here's how a typical plan review should go:

```bash
# 1. Generate the plan
terraform plan -out=migration.tfplan 2>&1 | tee plan-output.txt

# 2. Review the summary
tail -50 plan-output.txt

# 3. Search for specific resources
grep "azuread_application.cortex" plan-output.txt
grep "azurerm_role_assignment" plan-output.txt
grep "azurerm_monitor_diagnostic_setting" plan-output.txt

# 4. Check for warnings
grep -i "warning" plan-output.txt

# 5. Check for errors
grep -i "error" plan-output.txt

# 6. Count resource actions
grep "will be created" plan-output.txt | wc -l
grep "will be updated" plan-output.txt | wc -l
grep "will be destroyed" plan-output.txt | wc -l

# 7. Review sensitive outputs
grep "(sensitive value)" plan-output.txt
```

---

## 🎯 Decision Matrix

| Plan Output | Action | Reason |
|-------------|--------|--------|
| **Plan: 25 to add, 0 to change, 0 to destroy** | ✅ APPLY | Perfect! All new resources, nothing destroyed |
| **Plan: 20 to add, 5 to update in-place, 0 to destroy** | ⚠️ REVIEW | Check what's being updated and why |
| **Plan: 25 to add, 0 to change, 1 to destroy** | 🛑 INVESTIGATE | Find out why 1 resource is being destroyed |
| **Plan: 0 to add, 0 to change, 0 to destroy** | ✅ APPLY | Infrastructure already matches config (idempotent) |
| **Plan: Many resources marked for destruction** | 🛑 STOP | Do NOT apply - something is wrong |

---

## 🚀 Next Steps After Plan Review

### If Plan Looks Good:

```bash
# Apply the plan
terraform apply migration.tfplan

# Monitor the apply process
# Should take 3-5 minutes for all resources
```

### If Plan Shows Issues:

```bash
# Don't apply! Review the issues first
# Check:
1. Are your variables correct in terraform.tfvars?
2. Are you authenticated to the right Azure subscription?
3. Do you have the required permissions?
4. Are there any typos in variable values?

# Make corrections and re-run plan
terraform plan -out=migration.tfplan
```

---

## 💡 Pro Tips

### 1. **Save Every Plan**
```bash
# Always save plans with timestamps
terraform plan -out=plans/plan-$(date +%Y%m%d-%H%M%S).tfplan
```

### 2. **Review Before Bedtime**
- Generate plan at end of day
- Review it fresh in the morning
- Apply with clear head

### 3. **Use Target for Testing**
```bash
# Test one resource at a time
terraform plan -target=azurerm_resource_group.cortex
terraform apply -target=azurerm_resource_group.cortex
```

### 4. **Diff Against Previous Plans**
```bash
# Compare current plan with previous
terraform show migration.tfplan > plan-current.txt
diff plan-previous.txt plan-current.txt
```

### 5. **Validate Outputs**
```bash
# After apply, verify outputs
terraform output
terraform output -json | jq .
terraform output -raw application_secret  # Get secret value
```

---

## 🆘 Common Issues

### Issue 1: "No changes" when you expect changes

**Cause:** State already matches configuration
**Solution:** This is actually good! Infrastructure is in desired state

### Issue 2: Resources marked for replacement

**Cause:** Breaking changes in provider, attribute changes
**Solution:** Review upgrade guide, may need to accept replacement

### Issue 3: "Resource not found" errors

**Cause:** Data sources can't find Azure resources
**Solution:** Verify subscription, tenant IDs, Azure CLI authentication

### Issue 4: Permission denied errors

**Cause:** Insufficient Azure permissions
**Solution:** Need Owner or User Access Administrator role

---

## 📚 Additional Resources

- [Terraform Plan Command Docs](https://www.terraform.io/docs/commands/plan.html)
- [Azure RBAC Best Practices](https://learn.microsoft.com/en-us/azure/role-based-access-control/best-practices)
- [Terraform State Management](https://www.terraform.io/docs/state/index.html)

---

## ✅ Pre-Apply Checklist

Before running `terraform apply`:

- [ ] Plan saved to file (`terraform.tfplan`)
- [ ] Plan output reviewed line-by-line
- [ ] No unexpected destroy actions
- [ ] All resource names are correct
- [ ] Security settings verified (TLS, HTTPS)
- [ ] Sensitive outputs are masked
- [ ] Team notified (if production)
- [ ] Backup of current state created
- [ ] Rollback plan documented
- [ ] Maintenance window scheduled (if needed)

---

**Ready to proceed?**

```bash
# When you're confident:
terraform apply migration.tfplan

# Then verify:
terraform output
az resource list --resource-group rg-cortex-prod --output table
```

---

**Document Version:** 1.0
**Last Updated:** October 23, 2025
**Status:** Ready for Use ✅
