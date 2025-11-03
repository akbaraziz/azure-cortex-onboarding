#!/bin/bash

#####################################################################
# Azure Cortex Cloud Onboarding - Permission Validation Script
# Based on Cortex Cloud Troubleshooting Guide v1.2
#####################################################################
# This script validates Azure permissions before onboarding
# to prevent common errors: InvalidAuthenticationToken,
# AuthorizationFailed, and PrincipalNotFound
#####################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "═══════════════════════════════════════════════════════════"
echo " Azure Permissions Validation for Cortex Cloud Onboarding"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Get current user and subscription info
echo "Retrieving current Azure session information..."
USER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")
USER_EMAIL=$(az ad signed-in-user show --query userPrincipalName -o tsv 2>/dev/null || echo "")
SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null || echo "")
TENANT_ID=$(az account show --query tenantId -o tsv 2>/dev/null || echo "")

if [ -z "$USER_ID" ] || [ -z "$SUBSCRIPTION_ID" ]; then
    echo -e "${RED}✗ FAILED: Not logged into Azure${NC}"
    echo "Run: az login"
    exit 1
fi

echo -e "${GREEN}✓ Logged in as:${NC} $USER_EMAIL"
echo -e "${GREEN}✓ User ID:${NC} $USER_ID"
echo -e "${GREEN}✓ Subscription ID:${NC} $SUBSCRIPTION_ID"
echo -e "${GREEN}✓ Tenant ID:${NC} $TENANT_ID"
echo ""

#####################################################################
# Check 1: Verify Azure AD Global Administrator Role
#####################################################################
echo "Checking Azure AD roles..."
ADMIN_ROLES=$(az rest --method GET \
    --url "https://graph.microsoft.com/v1.0/me/memberOf" \
    --query "value[?contains(@odata.type, 'directoryRole')].displayName" \
    -o tsv 2>/dev/null || echo "")

HAS_GLOBAL_ADMIN=false
if echo "$ADMIN_ROLES" | grep -q "Global Administrator"; then
    echo -e "${GREEN}✓ Has Global Administrator role${NC}"
    HAS_GLOBAL_ADMIN=true
else
    echo -e "${YELLOW}⚠ WARNING: Global Administrator role not detected${NC}"
    echo "  This role is required for:"
    echo "  - Creating diagnostic settings for Azure AD"
    echo "  - Graph API operations"
    echo "  "
    echo "  To elevate access:"
    echo "  Azure Portal → Microsoft Entra ID → Properties"
    echo "  → Enable 'Access management for Azure resources'"
    echo ""
fi

#####################################################################
# Check 2: Verify Owner Role at Subscription Level
#####################################################################
echo "Checking subscription-level permissions..."
OWNER_ROLE=$(az role assignment list \
    --assignee "$USER_ID" \
    --scope "/subscriptions/$SUBSCRIPTION_ID" \
    --query "[?roleDefinitionName=='Owner'].roleDefinitionName" \
    -o tsv 2>/dev/null || echo "")

if [ -n "$OWNER_ROLE" ]; then
    echo -e "${GREEN}✓ Has Owner role at subscription level${NC}"
else
    echo -e "${RED}✗ FAILED: Missing Owner role at subscription level${NC}"
    echo "  Required for:"
    echo "  - Creating service principals"
    echo "  - Assigning RBAC roles"
    echo "  - Deploying ARM templates"
    echo ""
    echo "  To assign Owner role:"
    echo "  az role assignment create \\"
    echo "    --assignee $USER_ID \\"
    echo "    --role Owner \\"
    echo "    --scope /subscriptions/$SUBSCRIPTION_ID"
    echo ""
    exit 1
fi

#####################################################################
# Check 3: Check Management Group Access (if applicable)
#####################################################################
echo "Checking management group permissions..."
MG_ID=$(az account management-group list \
    --query "[0].name" -o tsv 2>/dev/null || echo "")

if [ -n "$MG_ID" ]; then
    echo -e "${BLUE}ℹ Found Management Group: $MG_ID${NC}"

    MG_OWNER=$(az role assignment list \
        --assignee "$USER_ID" \
        --scope "/providers/Microsoft.Management/managementGroups/$MG_ID" \
        --query "[?roleDefinitionName=='Owner'].roleDefinitionName" \
        -o tsv 2>/dev/null || echo "")

    if [ -n "$MG_OWNER" ]; then
        echo -e "${GREEN}✓ Has Owner role at management group level${NC}"
    else
        echo -e "${YELLOW}⚠ WARNING: Missing Owner role at management group level${NC}"
        echo "  This may cause deployment failures if deploying to management groups"
        echo ""
        echo "  To assign Owner role at management group:"
        echo "  az role assignment create \\"
        echo "    --assignee $USER_ID \\"
        echo "    --role Owner \\"
        echo "    --scope /providers/Microsoft.Management/managementGroups/$MG_ID"
        echo ""
    fi
else
    echo -e "${BLUE}ℹ No management groups found (subscription-level deployment)${NC}"
fi
echo ""

#####################################################################
# Check 4: Verify Resource Provider Registration
#####################################################################
echo "Checking critical resource provider registrations..."

# Microsoft.Insights
INSIGHTS_STATUS=$(az provider show --namespace Microsoft.Insights \
    --query "registrationState" -o tsv 2>/dev/null || echo "NotRegistered")

if [ "$INSIGHTS_STATUS" == "Registered" ]; then
    echo -e "${GREEN}✓ Microsoft.Insights: Registered${NC}"
elif [ "$INSIGHTS_STATUS" == "Registering" ]; then
    echo -e "${YELLOW}⚠ Microsoft.Insights: Registering (wait 5-15 minutes)${NC}"
else
    echo -e "${RED}✗ Microsoft.Insights: $INSIGHTS_STATUS${NC}"
    echo "  To register:"
    echo "  az provider register --namespace Microsoft.Insights --subscription $SUBSCRIPTION_ID"
    echo ""
fi

# Microsoft.Aadiam
AADIAM_STATUS=$(az provider show --namespace Microsoft.Aadiam \
    --query "registrationState" -o tsv 2>/dev/null || echo "NotRegistered")

if [ "$AADIAM_STATUS" == "Registered" ]; then
    echo -e "${GREEN}✓ Microsoft.Aadiam: Registered${NC}"
elif [ "$AADIAM_STATUS" == "Registering" ]; then
    echo -e "${YELLOW}⚠ Microsoft.Aadiam: Registering (wait 5-15 minutes)${NC}"
else
    echo -e "${RED}✗ Microsoft.Aadiam: $AADIAM_STATUS${NC}"
    echo "  To register:"
    echo "  az provider register --namespace Microsoft.Aadiam --subscription $SUBSCRIPTION_ID"
    echo ""
fi
echo ""

#####################################################################
# Check 5: Verify Authentication Token Validity
#####################################################################
echo "Checking Azure authentication token validity..."
TOKEN_EXPIRY=$(az account get-access-token --query expiresOn -o tsv 2>/dev/null || echo "")

if [ -n "$TOKEN_EXPIRY" ]; then
    echo -e "${GREEN}✓ Authentication token is valid${NC}"
    echo "  Expires: $TOKEN_EXPIRY"
    echo ""
    echo -e "${BLUE}ℹ TIP: If you encounter 'InvalidAuthenticationToken' errors:${NC}"
    echo "  1. az account clear"
    echo "  2. az login"
    echo "  3. Wait 2-10 minutes for permissions to propagate"
    echo ""
else
    echo -e "${RED}✗ FAILED: Could not retrieve authentication token${NC}"
    echo "  Run: az login"
    exit 1
fi

#####################################################################
# Check 6: Test Diagnostic Settings Permissions
#####################################################################
echo "Testing diagnostic settings permissions..."
TEST_DIAG=$(az rest --method GET \
    --url "https://management.azure.com/providers/microsoft.aadiam/diagnosticSettings?api-version=2017-04-01-preview" \
    2>&1 || echo "FAILED")

if echo "$TEST_DIAG" | grep -q "FAILED\|Forbidden\|InvalidAuthenticationToken"; then
    echo -e "${YELLOW}⚠ WARNING: Cannot access diagnostic settings${NC}"
    echo "  This may indicate:"
    echo "  - Expired authentication token"
    echo "  - Missing Global Administrator role"
    echo "  - Insufficient Microsoft.Insights permissions"
    echo ""
else
    echo -e "${GREEN}✓ Can access diagnostic settings API${NC}"
fi
echo ""

#####################################################################
# Summary and Recommendations
#####################################################################
echo "═══════════════════════════════════════════════════════════"
echo " Validation Summary"
echo "═══════════════════════════════════════════════════════════"
echo ""

READY=true

if [ "$HAS_GLOBAL_ADMIN" == "false" ]; then
    echo -e "${YELLOW}⚠ Recommended: Global Administrator role${NC}"
    READY=false
fi

if [ "$INSIGHTS_STATUS" != "Registered" ]; then
    echo -e "${RED}✗ Required: Register Microsoft.Insights provider${NC}"
    READY=false
fi

if [ "$AADIAM_STATUS" != "Registered" ]; then
    echo -e "${RED}✗ Required: Register Microsoft.Aadiam provider${NC}"
    READY=false
fi

if [ "$READY" == "true" ]; then
    echo -e "${GREEN}✓ All critical permissions and providers are configured!${NC}"
    echo ""
    echo "You can proceed with Azure Cortex Cloud onboarding."
    echo ""
    echo -e "${BLUE}Best Practices Before Onboarding:${NC}"
    echo "1. Refresh Azure login: az logout && az login"
    echo "2. Wait 2-10 minutes after role changes"
    echo "3. Verify subscription context: az account show"
    echo ""
    exit 0
else
    echo -e "${YELLOW}⚠ Some issues require attention before onboarding${NC}"
    echo ""
    echo "Please address the warnings/errors above."
    echo "See TROUBLESHOOTING.md for detailed guidance."
    echo ""
    exit 1
fi
