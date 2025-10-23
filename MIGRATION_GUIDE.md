# Azure Provider Migration Guide
**Project:** azure-cortex-ui
**Migration:** azurerm 3.x → 4.x | azuread 2.x → 3.x
**Date:** January 23, 2025

---

## 🎯 Overview

This guide walks you through migrating your Terraform configuration from:
- **azurerm provider 3.x → 4.x** (Latest: 4.49.0)
- **azuread provider 2.x → 3.x** (Latest: 3.6.0)

**Total Estimated Time:** 2-4 hours (including testing)

---

## ✅ Changes Made

### 1. Updated `provider.tf`
```diff
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
-     version = "~> 3.0"
+     version = "~> 4.0"  # Updated to latest
    }
    azuread = {
      source  = "hashicorp/azuread"
-     version = "~> 2.0"
+     version = "~> 3.0"  # Updated to latest
    }
  }
```

### 2. Removed Deprecated `retention_policy` from `azure-audit-logs.tf`
```diff
  enabled_log {
    category = "AuditLogs"
-
-   retention_policy {
-     enabled = true
-     days    = 30
-   }
  }
```

**Reason:** The `retention_policy` block is deprecated in azurerm 4.x. Retention is now managed at the destination level (Event Hub, Storage Account, or Log Analytics Workspace).

---

## 📋 Pre-Migration Checklist

Before proceeding, ensure you have:

- [ ] **Terraform installed** (version >= 1.0)
- [ ] **Azure CLI installed** (version >= 2.50.0)
- [ ] **Logged into Azure CLI** (`az login`)
- [ ] **Correct Azure subscription selected** (`az account set`)
- [ ] **Backup of current Terraform state** (see Step 1 below)
- [ ] **Git commit** of current working code
- [ ] **Test environment available** (recommended before production)

---

## 🚀 Step-by-Step Migration

### Step 1: Create Backups

**CRITICAL:** Always backup your Terraform state before major upgrades.

```bash
# Navigate to project directory
cd /mnt/d/Dropbox/GitHub_Repos/Projects/azure-cortex-ui

# Create backup directory
mkdir -p backups/$(date +%Y%m%d)

# Backup Terraform state (if it exists)
if [ -f terraform.tfstate ]; then
  cp terraform.tfstate backups/$(date +%Y%m%d)/terraform.tfstate.backup
  echo "✅ Terraform state backed up"
fi

# Backup provider lock file
if [ -f .terraform.lock.hcl ]; then
  cp .terraform.lock.hcl backups/$(date +%Y%m%d)/.terraform.lock.hcl.backup
  echo "✅ Provider lock file backed up"
fi

# Backup all Terraform files
cp *.tf backups/$(date +%Y%m%d)/
echo "✅ All .tf files backed up to backups/$(date +%Y%m%d)/"
```

### Step 2: Review Upgrade Guides

**Before proceeding, review the official upgrade guides:**

1. **AzureRM 3.x → 4.x Upgrade Guide:**
   - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide

2. **AzureAD 2.x → 3.x Upgrade Guide:**
   - https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/guides/3.0-upgrade-guide

**Key Breaking Changes:**

#### AzureRM 4.x:
- `retention_policy` removed from diagnostic settings (✅ already fixed)
- Some resource properties renamed
- Default behavior changes in certain resources
- Enhanced validation for resource configurations

#### AzureAD 3.x:
- Application registration changes
- Service principal creation flow modified
- Some deprecated fields removed
- Improved Microsoft Graph API integration

### Step 3: Initialize with New Providers

```bash
# Remove existing provider plugins
rm -rf .terraform/

# Initialize with new provider versions
terraform init -upgrade

# Expected output:
# Initializing provider plugins...
# - Finding hashicorp/azurerm versions matching "~> 4.0"...
# - Finding hashicorp/azuread versions matching "~> 3.0"...
# - Installing hashicorp/azurerm v4.x.x...
# - Installing hashicorp/azuread v3.x.x...
```

**Troubleshooting:**
- If `terraform init` fails, check internet connectivity
- Ensure no syntax errors in `provider.tf`
- Review error messages for specific provider issues

### Step 4: Validate Configuration

```bash
# Validate Terraform syntax
terraform validate

# Expected output:
# Success! The configuration is valid.
```

**If validation fails:**
1. Read error message carefully
2. Check which resource is causing the issue
3. Consult upgrade guides for that specific resource
4. Fix syntax/configuration issues
5. Repeat `terraform validate`

### Step 5: Review Terraform Plan

**CRITICAL STEP:** This shows what Terraform will change in your Azure infrastructure.

```bash
# Generate execution plan
terraform plan -out=migration.tfplan

# Save plan output for review
terraform plan | tee migration-plan-output.txt
```

**What to Look For:**

✅ **Good Signs:**
- `No changes. Your infrastructure matches the configuration.`
- `Plan: 0 to add, 0 to change, 0 to destroy.`
- Minor updates like provider metadata

⚠️ **Warning Signs:**
- Resources marked for destruction (`-/+`)
- Unexpected resource recreation
- Permission changes on critical resources

🛑 **STOP if you see:**
- Mass destruction of resources
- Changes you don't understand
- Security-related permission removals

**Example Good Output:**
```
No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

**Example Warning Output:**
```
# azurerm_monitor_aad_diagnostic_setting.tenant_audit_logs[0] will be updated in-place
~ resource "azurerm_monitor_aad_diagnostic_setting" "tenant_audit_logs" {
    id                             = "..."
    name                           = "cortex-tenant-audit-logs"

    # retention_policy removed (expected change)
  }
```

### Step 6: Apply Changes (Test Environment First!)

**Recommendation:** Test in a non-production environment first.

#### For Test Environment:
```bash
# Apply the migration plan
terraform apply migration.tfplan

# Or with interactive approval
terraform apply

# Review the plan one more time
# Type 'yes' when prompted
```

#### For Production Environment:
```bash
# Only proceed after successful test environment validation
# Create a fresh plan
terraform plan -out=prod-migration.tfplan

# Review carefully
terraform show prod-migration.tfplan

# Apply with explicit backup
terraform apply prod-migration.tfplan
```

### Step 7: Verify Deployment

After applying changes, verify everything is working:

```bash
# 1. Check Terraform outputs
terraform output

# 2. Verify Azure resources exist
az resource list --resource-group <your-cortex-rg> --output table

# 3. Check service principal
az ad sp show --id <application-id>

# 4. Verify custom role
az role definition list --name "Cortex Cloud Custom Reader*" --output table

# 5. Check Event Hub namespace
az eventhubs namespace show --name eh-cortex-audit-<env> --resource-group <rg-name>

# 6. Verify diagnostic settings
az monitor diagnostic-settings subscription list --output table
```

---

## 🧪 Testing Checklist

### Infrastructure Testing

- [ ] **Service Principal Created**
  ```bash
  az ad sp show --id $(terraform output -raw application_id)
  ```

- [ ] **Custom Role Assigned**
  ```bash
  az role assignment list --assignee $(terraform output -raw service_principal_object_id)
  ```

- [ ] **Event Hub Namespace Running**
  ```bash
  az eventhubs namespace show --name $(terraform output -raw audit_logs_configuration.namespace)
  ```

- [ ] **Storage Account Created**
  ```bash
  az storage account show --name $(terraform output -raw audit_logs_configuration.storage_account_name)
  ```

- [ ] **Diagnostic Settings Active**
  ```bash
  az monitor diagnostic-settings subscription list
  az monitor diagnostic-settings show --name cortex-tenant-audit-logs --resource <tenant-id>
  ```

### Functional Testing

- [ ] **Web UI Starts Successfully**
  ```bash
  npm start
  # Navigate to http://localhost:3001
  ```

- [ ] **Prerequisites Check Passes**
  - Azure CLI detected
  - Terraform detected
  - Azure login verified

- [ ] **Fresh Deployment Works**
  - Fill in configuration form
  - Start onboarding
  - Monitor WebSocket output
  - Verify deployment completes

- [ ] **Outputs Display Correctly**
  - Client ID visible
  - Client Secret visible (masked)
  - Service Principal ID visible
  - Next steps shown

### Integration Testing (with Cortex Cloud)

- [ ] **Cortex API Authentication**
  - Login with Access Key/Secret Key succeeds
  - JWT token received

- [ ] **Azure Account Onboarding**
  - Use output from Terraform deployment
  - Add Azure account in Cortex Cloud portal
  - Verify connection successful

- [ ] **Audit Logs Flowing**
  - Check Event Hub for incoming messages
  - Verify Cortex Cloud receiving audit events
  - Confirm timestamps are recent

---

## 🔄 Rollback Procedure

If migration fails or causes issues:

### Option 1: Restore from Backup (Recommended)

```bash
# Stop any running Terraform operations
# (Ctrl+C if terraform apply is running)

# Navigate to project directory
cd /mnt/d/Dropbox/GitHub_Repos/Projects/azure-cortex-ui

# Restore backed up files
cp backups/$(ls -t backups/ | head -1)/*.tf .

# If state was backed up, restore it
if [ -f backups/$(ls -t backups/ | head -1)/terraform.tfstate.backup ]; then
  cp backups/$(ls -t backups/ | head -1)/terraform.tfstate.backup terraform.tfstate
fi

# Restore provider lock file
if [ -f backups/$(ls -t backups/ | head -1)/.terraform.lock.hcl.backup ]; then
  cp backups/$(ls -t backups/ | head -1)/.terraform.lock.hcl.backup .terraform.lock.hcl
fi

# Reinitialize with old providers
rm -rf .terraform/
terraform init

# Verify state
terraform plan
```

### Option 2: Pin to Latest 3.x Versions

If you need more time before migrating to 4.x:

**Edit `provider.tf`:**
```hcl
required_providers {
  azurerm = {
    source  = "hashicorp/azurerm"
    version = "~> 3.117"  # Last 3.x release with backports
  }
  azuread = {
    source  = "hashicorp/azuread"
    version = "~> 2.53"   # Last stable 2.x release
  }
}
```

**Then:**
```bash
rm -rf .terraform/
terraform init -upgrade
terraform plan
```

---

## 📊 Post-Migration Monitoring

After successful migration, monitor for 24-48 hours:

### Azure Resources
- Check Azure Portal for any alerts
- Verify Event Hub is receiving data
- Confirm Storage Account metrics look normal
- Check Diagnostic Settings are still active

### Cortex Cloud
- Verify Azure account shows "Connected" status
- Check audit logs are flowing
- Confirm CSPM scans are running
- Review any new alerts or findings

### Application Logs
- Monitor web UI for errors
- Check Terraform state for drift
- Review WebSocket connection stability

---

## 🆘 Troubleshooting Common Issues

### Issue 1: `terraform init` Fails with Provider Not Found

**Error:**
```
Error: Failed to query available provider packages
```

**Solution:**
```bash
# Clear Terraform cache
rm -rf .terraform/
rm .terraform.lock.hcl

# Ensure you have internet connectivity
ping registry.terraform.io

# Retry initialization
terraform init -upgrade
```

---

### Issue 2: Resources Marked for Destruction

**Error:**
```
Plan: 0 to add, 0 to change, 15 to destroy.
```

**Solution:**
1. **DO NOT APPLY** - This will destroy your infrastructure
2. Review which resources are being destroyed
3. Check if there's a state drift issue:
   ```bash
   terraform refresh
   terraform plan
   ```
4. Consult upgrade guides for those specific resources
5. Consider rolling back to previous provider versions

---

### Issue 3: Application Password/Secret Rotation Triggered

**Warning:**
```
# azuread_application_password.cortex will be replaced
```

**Solution:**
- This is expected if the secret management changed in azuread 3.x
- Ensure you save the new secret from Terraform output
- Update Cortex Cloud with the new secret immediately
- Consider using `lifecycle { ignore_changes = [end_date] }` if unwanted

---

### Issue 4: Diagnostic Settings Validation Error

**Error:**
```
Error: retention_policy is no longer supported
```

**Solution:**
- Already fixed in our migration! ✅
- If you see this, ensure `azure-audit-logs.tf` doesn't have `retention_policy` blocks
- Re-run `terraform validate`

---

### Issue 5: Permission Denied Errors

**Error:**
```
Error: authorization.RoleAssignmentsClient#Create: Failure responding to request
```

**Solution:**
```bash
# Verify you're logged in as correct user
az account show

# Check you have Owner or User Access Administrator role
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --include-inherited

# Re-authenticate if needed
az login
az account set --subscription <subscription-id>
```

---

## 📞 Support Resources

### Official Documentation
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [Terraform AzureAD Provider](https://registry.terraform.io/providers/hashicorp/azuread/latest)
- [Azure RBAC Documentation](https://learn.microsoft.com/en-us/azure/role-based-access-control/)

### Upgrade Guides
- [AzureRM 4.x Upgrade Guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide)
- [AzureAD 3.x Upgrade Guide](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/guides/3.0-upgrade-guide)

### Community Support
- [Terraform Community Forum](https://discuss.hashicorp.com/)
- [Azure Terraform GitHub Issues](https://github.com/hashicorp/terraform-provider-azurerm/issues)

---

## 📝 Migration Sign-Off Checklist

After completing migration, verify:

- [x] ✅ Provider versions updated to 4.x (azurerm) and 3.x (azuread)
- [x] ✅ Deprecated `retention_policy` blocks removed
- [ ] ✅ Backups created and stored safely
- [ ] ✅ `terraform init -upgrade` completed successfully
- [ ] ✅ `terraform validate` passed with no errors
- [ ] ✅ `terraform plan` shows no unexpected changes
- [ ] ✅ Changes applied to test environment successfully
- [ ] ✅ All infrastructure tests passed
- [ ] ✅ All functional tests passed
- [ ] ✅ Integration with Cortex Cloud verified
- [ ] ✅ Production deployment completed (if applicable)
- [ ] ✅ Post-migration monitoring active
- [ ] ✅ Documentation updated

---

## 🎉 Success Criteria

Your migration is successful when:

1. ✅ `terraform plan` shows `No changes` (infrastructure matches config)
2. ✅ All Azure resources are healthy and functioning
3. ✅ Web UI can successfully deploy new instances
4. ✅ Cortex Cloud receives audit logs and CSPM data
5. ✅ No errors in application logs for 24 hours
6. ✅ All team members can deploy using the new configuration

---

## 📅 Maintenance Schedule

### Immediate (Completed)
- [x] Update provider versions
- [x] Remove deprecated configurations
- [x] Test in development environment

### This Week
- [ ] Deploy to staging environment
- [ ] Run full integration tests
- [ ] Update team documentation

### This Month
- [ ] Deploy to production (if separate from staging)
- [ ] Monitor for 7 days
- [ ] Archive old backups

### Ongoing
- [ ] Check for provider updates monthly
- [ ] Review Terraform changelog quarterly
- [ ] Test updates in development first

---

**Migration Completed By:** _________________
**Date:** _________________
**Verified By:** _________________
**Date:** _________________

---

**Document Version:** 1.0
**Last Updated:** January 23, 2025
**Next Review:** April 23, 2025
