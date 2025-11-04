# Azure Cortex Cloud Onboarding - Troubleshooting Guide

This guide covers common errors encountered during Azure onboarding to Cortex Cloud using the **azure-cortex-ui** application.

---

## Error 1: InvalidAuthenticationToken (Diagnostic Settings)

### Symptoms
```
DeploymentFailed with InvalidAuthenticationToken
Unable to create diagnostic settings for Azure AD or Management Group
```

### Root Cause
- Azure CLI token is expired or invalid
- Insufficient permissions to modify diagnostic settings
- Permissions haven't propagated after role assignment

### Solution

1. **Refresh your Azure CLI session:**
   ```bash
   az account clear
   az login
   ```

2. **Verify Owner role at Management Group level:**
   ```bash
   # Get your user ID
   USER_ID=$(az ad signed-in-user show --query id -o tsv)

   # List role assignments
   az role assignment list --assignee $USER_ID \
     --scope /providers/Microsoft.Management/managementGroups/<mg-id>
   ```

3. **If Owner role is missing, assign it:**
   ```bash
   az role assignment create \
     --assignee <your-user-id> \
     --role "Owner" \
     --scope /providers/Microsoft.Management/managementGroups/<mg-id>
   ```

4. **Wait 2-10 minutes** for permissions to propagate across Azure

5. **Retry the onboarding** from the UI

---

## Error 2: AuthorizationFailed (ARM Template Deployment)

### Symptoms
```
Authorization failed for template resource
Client does not have permission to perform action 'Microsoft.Insights/diagnosticSettings/write'
```

### Root Cause
Logged-in Azure user lacks required permissions for ARM template deployments at Management Group level.

### Solution

Follow the same steps as Error 1 above.

---

## Error 3: PrincipalNotFound (Service Principal Missing)

### Symptoms
```
Principal <guid> does not exist in the directory
Check that you have the correct principal ID
```

### Root Cause
- Cortex Enterprise Application not created in Azure AD
- Object ID mismatch between Azure and configuration

### Solution

#### Step 1: Verify Cortex Enterprise Application Exists

1. Go to **Azure Portal** → **Microsoft Entra ID** → **Enterprise Applications**
2. Search for "Cortex" or application name from Cortex Cloud
3. Verify the application exists

**If it doesn't exist:**
1. Log in to **Cortex Cloud Console**
2. Navigate to **Settings → Data Sources**
3. Click on your Azure instance
4. Select **Configuration**
5. Click **"Approve in Azure"** - this creates the Enterprise Application
6. Download the new Azure Resource Manager template
7. Re-run the onboarding from the UI

#### Step 2: Handle Replication Delays

If the application was just created:
1. Wait **2-10 minutes** for Azure AD replication
2. Retry the deployment from the UI

---

## Error 4: Resource Providers Not Registered

### Symptoms
```
Deployment fails with "not registered to use microsoft.insights" or "microsoft.aadiam"
```

### Root Cause
Required Azure resource providers (`Microsoft.Insights` and `Microsoft.Aadiam`) are not registered for your subscription.

### Solution

1. **Register the providers:**
   ```bash
   az provider register --namespace Microsoft.Insights --subscription <subscription-id>
   az provider register --namespace Microsoft.Aadiam --subscription <subscription-id>
   ```

2. **Wait for registration to complete (5-15 minutes):**
   ```bash
   # Check status (should show "Registered")
   az provider show --namespace Microsoft.Insights --query "registrationState"
   az provider show --namespace Microsoft.Aadiam --query "registrationState"
   ```

3. **Refresh Azure CLI session:**
   ```bash
   az logout
   az login
   ```

4. **Retry deployment** from the UI

---

## Error 5: Insufficient Privileges (Graph API)

### Symptoms
```
Insufficient privileges to complete the operation
Graph client request failed
```

### Root Cause
User doesn't have **Global Administrator** access for certain Microsoft Graph operations.

### Solution

#### Option 1: Azure CLI

```bash
az login
az rest --method post --url \
  "/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01"
```

#### Option 2: Azure Portal

1. Log in to **Azure Portal**
2. Go to **Microsoft Entra ID → Properties**
3. Find **"Access management for Azure resources"**
4. Toggle it **ON**

**Important:** Toggle this back to **OFF** after deployment completes.

---

## Error 6: Terraform Deployment Failures

### Symptoms
```
Terraform apply failed
Resource creation timeout
```

### Root Cause
- Network connectivity issues
- Azure API rate limiting
- Resource provider issues

### Solution

1. **Check Terraform state:**
   ```bash
   cd deployments/<deployment-id>
   terraform show
   ```

2. **Retry with increased timeout:**
   Edit the deployment and increase timeout values in the Terraform configuration.

3. **Check WebSocket connection:**
   - Open browser developer console (F12)
   - Check for WebSocket connection errors
   - Ensure `ws://localhost:3001/ws/<deployment-id>` is connected

4. **Review deployment logs:**
   - Check the terminal output in the UI
   - Look for specific error messages
   - Check the server.js console for backend errors

---

## Error 7: Feature Selection Not Working

### Symptoms
- Cortex Cloud features not appearing in UI
- Checkboxes not saving selections

### Root Cause
- Browser cache issue
- JavaScript errors in console

### Solution

1. **Hard refresh the page:**
   - Windows/Linux: `Ctrl + Shift + R`
   - Mac: `Cmd + Shift + R`

2. **Clear browser cache:**
   - Chrome: Settings → Privacy and security → Clear browsing data
   - Select "Cached images and files"

3. **Check browser console:**
   - Press F12
   - Look for JavaScript errors in the Console tab
   - Report any errors found

4. **Verify UI is running:**
   ```bash
   # In the project directory
   npm run dev
   ```
   - Should show: "Local: http://localhost:5173"

---

## Prevention Best Practices

### Before Starting Onboarding

1. ✅ Run the prerequisites check script (see [PREREQUISITES.md](./PREREQUISITES.md))
2. ✅ Ensure you have **Owner** role at Management Group/Subscription level
3. ✅ Ensure you have **Global Administrator** role in Azure AD
4. ✅ Register required resource providers:
   - Microsoft.Insights
   - Microsoft.Aadiam
5. ✅ Refresh Azure CLI session: `az logout && az login`

### During Onboarding

1. ⏱️ **Wait for permission propagation** (2-10 minutes) after any role changes
2. 🔍 **Monitor the WebSocket terminal output** in the UI for real-time progress
3. 📊 **Check Azure Portal** if deployment seems stuck:
   - Navigate to Management Groups → Deployments
   - Check deployment status

### After Errors

1. 🔁 **Don't immediately retry** - wait 2-10 minutes for Azure replication
2. 📝 **Review error messages carefully** - they often contain the exact issue
3. 🧹 **Clean up failed deployments** before retrying:
   ```bash
   # List failed deployments
   az deployment mg list --management-group <mg-id> \
     --query "[?properties.provisioningState=='Failed'].name"
   ```

---

## Still Having Issues?

### Debugging Steps

1. **Check the server logs:**
   - Look at the Node.js server console where `npm run dev` is running
   - Check for detailed error messages

2. **Verify Terraform configuration:**
   ```bash
   cd deployments/<deployment-id>
   terraform validate
   terraform plan
   ```

3. **Check Azure Portal activity log:**
   - Azure Portal → Monitor → Activity Log
   - Filter by subscription and time range
   - Look for failed operations

4. **Verify feature configuration:**
   - Ensure the features you selected are supported for your Cortex Cloud license
   - Some features require Contributor role (Agent-Based Protection, Remediation)

### Get Help

1. Review the official Cortex Cloud documentation
2. Check the project's GitHub issues
3. Contact Palo Alto Networks support with:
   - Deployment ID
   - Error messages from UI terminal output
   - Azure subscription ID
   - Cortex Cloud region

---

## Appendix: Common Error Codes

| Error Code | Meaning | Quick Fix |
|------------|---------|-----------|
| `InvalidAuthenticationToken` | Stale or invalid Azure token | `az logout && az login` |
| `AuthorizationFailed` | Missing permissions | Assign Owner role + wait 5-10min |
| `PrincipalNotFound` | Service principal doesn't exist | Create in Cortex Cloud + approve in Azure |
| `Conflict` | Resource already exists | Delete existing resource or use different name |
| `InvalidActionOrNotAction` | Deprecated API action | Update Terraform templates |
| `MessagingGatewayBadRequest` | Event Hub configuration issue | Check partition count settings |

---

## Version Information

**Document Version:** 1.0
**Last Updated:** October 2025
**Application:** azure-cortex-ui
**Tested with:** Azure CLI 2.50+, Terraform 1.5+, Node.js 18+
