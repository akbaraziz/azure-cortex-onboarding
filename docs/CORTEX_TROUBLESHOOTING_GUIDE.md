# Cortex Cloud – Azure Onboarding Troubleshooting Guide

**Based on Palo Alto Networks Internal Guide v1.2 (October 2025)**

This guide provides detailed solutions for common errors encountered during Azure onboarding to Cortex Cloud.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Common Errors and Solutions](#common-errors-and-solutions)
   - [Error 1: InvalidAuthenticationToken](#error-1-invalidauthenticationtoken)
   - [Error 2: AuthorizationFailed](#error-2-authorizationfailed)
   - [Error 3: PrincipalNotFound](#error-3-principalnotfound)
   - [Error 4: PartitionCount](#error-4-partitioncount)
   - [Error 5: Deprecated Action](#error-5-deprecated-action)
   - [Error 6: Insufficient Privileges (Graph API)](#error-6-insufficient-privileges-graph-api)
   - [Error 7: Resource Provider Not Registered](#error-7-resource-provider-not-registered)
   - [Error 8: Policy Compliance](#error-8-policy-compliance)
3. [Best Practices](#best-practices)

---

## Prerequisites

Before starting onboarding, run the validation scripts:

```bash
# Validate prerequisites
./check-prerequisites.sh

# Validate permissions
./scripts/validate-permissions.sh
```

### Required Permissions

- **Azure AD**: Global Administrator role
- **Azure Subscription**: Owner role at subscription or management group level
- **Resource Providers**:
  - `Microsoft.Insights` - **MUST** be Registered
  - `Microsoft.Aadiam` - **MUST** be Registered

---

## Common Errors and Solutions

### Error 1: InvalidAuthenticationToken

**Symptom:**
```
{"code":"InvalidAuthenticationToken","message":""}
[ERROR] Compliance policy creation failed.
```

**Root Cause:** Expired or invalid Azure authentication token when updating diagnostic settings.

**Solution:**

1. **Assign Owner role at management group level:**
   ```bash
   # Get your user ID
   USER_ID=$(az ad signed-in-user show --query id -o tsv)

   # Get management group ID
   MG_ID=$(az account management-group list --query "[0].name" -o tsv)

   # Assign Owner role
   az role assignment create \
     --assignee $USER_ID \
     --role Owner \
     --scope /providers/Microsoft.Management/managementGroups/$MG_ID
   ```

2. **Refresh Azure login:**
   ```bash
   az account clear
   az login
   ```

3. **Wait 2-10 minutes** for permissions to propagate across Azure AD.

4. **Rerun the onboarding process.**

**Validation:**
Navigate to Azure Portal → Microsoft Entra ID → Monitoring → Diagnostic settings to verify access.

---

### Error 2: AuthorizationFailed

**Symptom:**
```
ERROR: Authorization failed for template resource...
does not have permission to perform action 'Microsoft.Insights/diagnosticSettings/write'
```

**Root Cause:** User lacks Owner role at management group level for ARM template deployments.

**Solution:**

Same as [Error 1](#error-1-invalidauthenticationtoken) - Assign Owner role and refresh login.

---

### Error 3: PrincipalNotFound

**Symptom:**
```
{"code":"PrincipalNotFound","message":"Principal e047c2b633a444cbb0c11560157ff671
does not exist in the directory..."}
```

**Root Cause:**
- Cortex Enterprise Application not created in Azure AD
- Object ID or Client ID mismatch
- Replication delay after principal creation

**Solution:**

#### Step 1: Verify Cortex Enterprise Application Exists

1. Navigate to **Azure Portal → Microsoft Entra ID → Enterprise Applications**
2. Search for **"Cortex"**
3. If NOT found:
   - Log into **Cortex Console**
   - Go to **Settings → Data Sources**
   - Right-click your Azure instance → **Configuration**
   - Click **"Approve in Azure"** (creates the enterprise app)
   - Download the new **Azure Resource Manager** template

#### Step 2: Verify Correct IDs (if using scripts)

If using `parameters.sh` or `template.json`:

1. Get IDs from Azure Portal:
   - Enterprise Applications → Search "Cortex" → Overview
   - Note **Object ID** and **Application (Client) ID**

2. Update configuration files:
   ```bash
   # parameters.sh
   customer_object_id="<Object-ID-from-Azure>"
   outpost_client_id="<Application-Client-ID-from-Azure>"

   # template.json
   "customerObjectId": {
     "defaultValue": "<Object-ID-from-Azure>"
   },
   "outpostClientId": {
     "defaultValue": "<Application-Client-ID-from-Azure>"
   }
   ```

#### Step 3: Wait for Replication

If the application was just created:
- **Wait 2-10 minutes** for Azure AD replication
- Then retry deployment

---

### Error 4: PartitionCount

**Symptom:**
```
SubCode=40000. PartitionCount can only be changed on a Dedicated Event Hub
cluster or Premium namespace.
```

**Root Cause:** Event Hub partition count set to 20 (not supported on Standard tier).

**Solution:**

**This project now handles this automatically** with configurable variables in `variables.tf`:

```hcl
variable "event_hub_partition_count" {
  default = 4  # Safe for Standard tier
}

variable "event_hub_sku" {
  default = "Standard"
}
```

**To customize:**

Add to your `terraform.tfvars`:
```hcl
event_hub_partition_count = 4   # Standard tier: max 32
event_hub_sku            = "Standard"  # or "Premium" / "Dedicated"
```

**For Premium/Dedicated tiers**, you can increase the partition count as needed.

---

### Error 5: Deprecated Action

**Symptom:**
```
{"code":"InvalidActionOrNotAction",
"message":"'microsoft.security/autoprovisioningsettings/read' does not match
any of the actions supported by the providers."}
```

**Root Cause:** Azure deprecated this permission.

**Solution:**

If you encounter this error, manually edit `template.json`:

1. Search for `"microsoft.security/autoprovisioningsettings/read"`
2. Remove this line entirely
3. Save and redeploy

**Note:** This project's Terraform templates do **not** include this deprecated permission.

---

### Error 6: Insufficient Privileges (Graph API)

**Symptom:**
```
"Insufficient privileges to complete the operation. Graph client request id..."
```

**Root Cause:** Missing Global Administrator role for Graph API operations.

**Solution:**

#### Option 1: Azure CLI
```bash
az login
az rest --method post \
  --url "/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01"
```

#### Option 2: Azure Portal
1. Navigate to **Microsoft Entra ID → Properties**
2. Find **"Access management for Azure resources"**
3. Toggle it **ON**
4. **After deployment**, toggle it **OFF** (to revert elevated privileges)

---

### Error 7: Resource Provider Not Registered

**Symptom:**
```
{"code":"InvalidAuthenticationToken"} (misleading)
Provider Microsoft.Insights registration state: NotRegistered
Provider Microsoft.Aadiam registration state: NotRegistered
```

**Root Cause:** Required resource providers not registered on the subscription.

**Solution:**

1. **Register providers:**
   ```bash
   SUBSCRIPTION_ID=$(az account show --query id -o tsv)

   az provider register \
     --namespace Microsoft.Insights \
     --subscription $SUBSCRIPTION_ID

   az provider register \
     --namespace Microsoft.Aadiam \
     --subscription $SUBSCRIPTION_ID
   ```

2. **Wait for registration** (5-15 minutes):
   ```bash
   # Check status
   az provider show --namespace Microsoft.Insights --query "registrationState"
   az provider show --namespace Microsoft.Aadiam --query "registrationState"
   ```

3. **Refresh authentication:**
   ```bash
   az logout
   az login
   ```

4. **Retry deployment** once both show `"Registered"`.

---

### Error 8: Policy Compliance

**Symptom:**
```
[INFO] 0 out of 2 subscriptions are compliant.
```

**Root Cause:** Azure Policy compliance evaluation not complete.

**Solution:**

1. Navigate to **Azure Portal → Management Groups**
2. Select your **Tenant Root Group**
3. Go to **Governance → Policy**
4. Search for **"Cortex"**
5. If **Compliance Status** shows **"Non-compliant"**:
   - Select the non-compliant policy
   - Click **"Create remediation task"**
   - Do **NOT** modify settings
   - Click **"Remediate"**

6. **Wait 2-15 minutes**, then refresh

7. Once policy shows **"Compliant"**, the deployment will complete successfully

---

## Best Practices

### Before Onboarding

1. ✅ **Validate prerequisites:**
   ```bash
   ./check-prerequisites.sh
   ./scripts/validate-permissions.sh
   ```

2. ✅ **Ensure Owner role** at tenant root and subscription level

3. ✅ **Verify Global Administrator** role in Azure AD

4. ✅ **Register resource providers:**
   - Microsoft.Insights
   - Microsoft.Aadiam

5. ✅ **Refresh Azure login:**
   ```bash
   az logout && az login
   ```

### During Onboarding

1. ⏱ **Wait 2-10 minutes** after role or permission changes
2. 🔄 **Refresh authentication** if encountering token errors
3. 📊 **Monitor policy compliance** in Azure Portal
4. 🔍 **Check diagnostic settings** access before deployment

### After Errors

1. **Don't immediately retry** - wait for propagation
2. **Check logs** in Azure Portal → Activity Log
3. **Validate permissions** haven't changed
4. **Re-download templates** from Cortex Console if needed

---

## Quick Reference Commands

```bash
# Get current user info
az ad signed-in-user show --query id -o tsv
az ad signed-in-user show --query userPrincipalName -o tsv

# Check subscription context
az account show

# List role assignments
az role assignment list --assignee <your-user-id>

# Check resource provider status
az provider show --namespace Microsoft.Insights --query "registrationState"
az provider show --namespace Microsoft.Aadiam --query "registrationState"

# Refresh authentication
az logout
az login

# Validate prerequisites
./check-prerequisites.sh
./scripts/validate-permissions.sh
```

---

## Getting Help

If issues persist after following this guide:

1. **Check Azure Activity Logs** for detailed error messages
2. **Review Prerequisites**: See `PREREQUISITES.md`
3. **Contact Palo Alto Support** with:
   - Deployment ID (if using web UI)
   - Full error messages
   - Output from validation scripts

---

**Document Version:** 1.0
**Last Updated:** November 2025
**Based on:** Palo Alto Networks Cortex Cloud Azure Onboarding Troubleshooting Guide v1.2
