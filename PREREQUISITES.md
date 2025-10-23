# Azure Cortex Cloud Onboarding - Prerequisites

## Required Permissions

### Azure Permissions
Before running the onboarding process, ensure you have the following permissions:

1. **Owner Role** at the Management Group or Subscription level
   ```bash
   # Check your current role assignments
   az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) \
     --scope /providers/Microsoft.Management/managementGroups/<management-group-id>
   ```

2. **Global Administrator** role in Azure AD (Entra ID)
   - Navigate to: Azure Portal → Microsoft Entra ID → Roles and administrators
   - Verify you have "Global Administrator" assigned

### Required Azure Resource Providers

The following resource providers **must be registered** before onboarding:

```bash
# Register Microsoft.Insights (required for diagnostic settings)
az provider register --namespace Microsoft.Insights --subscription <subscription-id>

# Register Microsoft.Aadiam (required for Azure AD diagnostics)
az provider register --namespace Microsoft.Aadiam --subscription <subscription-id>

# Verify registration status (should show "Registered")
az provider show --namespace Microsoft.Insights --query "registrationState"
az provider show --namespace Microsoft.Aadiam --query "registrationState"
```

**Note:** Provider registration can take 5-15 minutes. Wait for both to show "Registered" before proceeding.

## Required Tools

1. **Azure CLI** (v2.50.0 or higher)
   ```bash
   az --version
   ```

2. **Node.js** (v18+ recommended for the UI server)
   ```bash
   node --version
   ```

3. **npm** (v9+ recommended)
   ```bash
   npm --version
   ```

## Cortex Cloud Requirements

1. **Cortex Cloud Access Keys**
   - Log in to Cortex Cloud Console
   - Navigate to: **Settings → Access Keys**
   - Create new access key (save both Access Key ID and Secret Key)

2. **Cortex Cloud API URL**
   - Determine your region's API URL:
     - US: `https://api.prismacloud.io`
     - EU: `https://api.eu.prismacloud.io`
     - APAC: `https://api.anz.prismacloud.io`
     - Gov: `https://api.gov.prismacloud.io`

## Pre-Onboarding Checklist

Before running `npm run dev` and starting onboarding:

- [ ] Azure CLI installed and logged in (`az login`)
- [ ] Correct subscription selected (`az account set --subscription <id>`)
- [ ] Owner role assigned at Management Group/Subscription level
- [ ] Global Administrator role in Azure AD
- [ ] Microsoft.Insights provider registered
- [ ] Microsoft.Aadiam provider registered
- [ ] Cortex Cloud Access Key and Secret obtained
- [ ] Cortex Cloud API URL identified for your region

## Common Permission Issues

### Issue: "InvalidAuthenticationToken"
**Cause:** Stale Azure CLI token or insufficient permissions

**Solution:**
```bash
# Logout and login again
az account clear
az login

# Wait 2-10 minutes for permission propagation
```

### Issue: "AuthorizationFailed"
**Cause:** Missing Owner role at Management Group level

**Solution:**
```bash
# Assign Owner role (requires existing admin)
az role assignment create \
  --assignee <your-user-id> \
  --role "Owner" \
  --scope /providers/Microsoft.Management/managementGroups/<mg-id>
```

### Issue: "Insufficient privileges to complete the operation"
**Cause:** Missing Global Admin access for Graph API operations

**Solution:**
1. **Azure Portal Method:**
   - Go to Microsoft Entra ID → Properties
   - Toggle "Access management for Azure resources" to **ON**

2. **Azure CLI Method:**
   ```bash
   az rest --method post --url \
     "/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01"
   ```

**Important:** Toggle this back to OFF after deployment completes.

## Validation Script

Run this script to validate prerequisites before onboarding:

```bash
#!/bin/bash

echo "=== Azure Cortex Cloud Onboarding - Prerequisites Check ==="
echo ""

# Check Azure CLI
if command -v az &> /dev/null; then
    echo "✅ Azure CLI installed: $(az version --query '\"azure-cli\"' -o tsv)"
else
    echo "❌ Azure CLI not installed"
    exit 1
fi

# Check login status
if az account show &> /dev/null; then
    echo "✅ Logged in to Azure"
    SUBSCRIPTION=$(az account show --query name -o tsv)
    echo "   Current subscription: $SUBSCRIPTION"
else
    echo "❌ Not logged in to Azure. Run: az login"
    exit 1
fi

# Check Microsoft.Insights provider
INSIGHTS_STATUS=$(az provider show --namespace Microsoft.Insights --query "registrationState" -o tsv 2>/dev/null)
if [ "$INSIGHTS_STATUS" == "Registered" ]; then
    echo "✅ Microsoft.Insights provider registered"
else
    echo "⚠️  Microsoft.Insights provider not registered (Status: $INSIGHTS_STATUS)"
    echo "   Run: az provider register --namespace Microsoft.Insights"
fi

# Check Microsoft.Aadiam provider
AADIAM_STATUS=$(az provider show --namespace Microsoft.Aadiam --query "registrationState" -o tsv 2>/dev/null)
if [ "$AADIAM_STATUS" == "Registered" ]; then
    echo "✅ Microsoft.Aadiam provider registered"
else
    echo "⚠️  Microsoft.Aadiam provider not registered (Status: $AADIAM_STATUS)"
    echo "   Run: az provider register --namespace Microsoft.Aadiam"
fi

echo ""
echo "=== Prerequisites check complete ==="
```

Save this as `check-prerequisites.sh`, make it executable (`chmod +x check-prerequisites.sh`), and run it before onboarding.

## Next Steps

Once all prerequisites are met:

1. Start the UI server: `npm run dev`
2. Open browser: `http://localhost:5173`
3. Fill in the onboarding form with:
   - Azure Subscription ID
   - Azure Tenant ID
   - Cortex Cloud Access Key
   - Cortex Cloud Secret Key
   - Select desired Cortex Cloud features
4. Click "Start Onboarding"

## Support

For issues during onboarding, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md).
