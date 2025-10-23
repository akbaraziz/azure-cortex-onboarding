#!/bin/bash

#####################################################################
# Azure Cortex Cloud Onboarding - Prerequisites Validation Script
#####################################################################
# This script validates that all prerequisites are met before
# starting the onboarding process.
#####################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

echo ""
echo "═══════════════════════════════════════════════════════════"
echo " Azure Cortex Cloud Onboarding - Prerequisites Check"
echo "═══════════════════════════════════════════════════════════"
echo ""

#####################################################################
# Check 1: Azure CLI Installation
#####################################################################
echo -n "Checking Azure CLI installation... "
if command -v az &> /dev/null; then
    AZ_VERSION=$(az version --query '\"azure-cli\"' -o tsv 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✓ PASSED${NC}"
    echo "   Installed version: $AZ_VERSION"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "   Azure CLI is not installed"
    echo "   Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    FAILED=$((FAILED + 1))
fi
echo ""

#####################################################################
# Check 2: Azure CLI Login Status
#####################################################################
echo -n "Checking Azure CLI login status... "
if az account show &> /dev/null; then
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    TENANT_ID=$(az account show --query tenantId -o tsv)
    echo -e "${GREEN}✓ PASSED${NC}"
    echo "   Logged in as: $(az account show --query user.name -o tsv)"
    echo "   Subscription: $SUBSCRIPTION_NAME"
    echo "   Subscription ID: $SUBSCRIPTION_ID"
    echo "   Tenant ID: $TENANT_ID"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "   Not logged in to Azure"
    echo "   Run: az login"
    FAILED=$((FAILED + 1))
    echo ""
    echo "Cannot continue without Azure login. Exiting."
    exit 1
fi
echo ""

#####################################################################
# Check 3: Microsoft.Insights Provider Registration
#####################################################################
echo -n "Checking Microsoft.Insights provider... "
INSIGHTS_STATUS=$(az provider show --namespace Microsoft.Insights --query "registrationState" -o tsv 2>/dev/null || echo "Unknown")
if [ "$INSIGHTS_STATUS" == "Registered" ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    echo "   Status: Registered"
    PASSED=$((PASSED + 1))
elif [ "$INSIGHTS_STATUS" == "Registering" ]; then
    echo -e "${YELLOW}⚠ WARNING${NC}"
    echo "   Status: Registering (wait 5-15 minutes)"
    echo "   Run this script again after registration completes"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "   Status: $INSIGHTS_STATUS"
    echo "   To register: az provider register --namespace Microsoft.Insights --subscription $SUBSCRIPTION_ID"
    FAILED=$((FAILED + 1))
fi
echo ""

#####################################################################
# Check 4: Microsoft.Aadiam Provider Registration
#####################################################################
echo -n "Checking Microsoft.Aadiam provider... "
AADIAM_STATUS=$(az provider show --namespace Microsoft.Aadiam --query "registrationState" -o tsv 2>/dev/null || echo "Unknown")
if [ "$AADIAM_STATUS" == "Registered" ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    echo "   Status: Registered"
    PASSED=$((PASSED + 1))
elif [ "$AADIAM_STATUS" == "Registering" ]; then
    echo -e "${YELLOW}⚠ WARNING${NC}"
    echo "   Status: Registering (wait 5-15 minutes)"
    echo "   Run this script again after registration completes"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "   Status: $AADIAM_STATUS"
    echo "   To register: az provider register --namespace Microsoft.Aadiam --subscription $SUBSCRIPTION_ID"
    FAILED=$((FAILED + 1))
fi
echo ""

#####################################################################
# Check 5: Node.js Installation
#####################################################################
echo -n "Checking Node.js installation... "
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
    if [ "$NODE_MAJOR" -ge 18 ]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        echo "   Installed version: $NODE_VERSION"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}⚠ WARNING${NC}"
        echo "   Installed version: $NODE_VERSION (recommended: v18+)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠ WARNING${NC}"
    echo "   Node.js not found (required for running the UI server)"
    echo "   Install from: https://nodejs.org/"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

#####################################################################
# Check 6: npm Installation
#####################################################################
echo -n "Checking npm installation... "
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✓ PASSED${NC}"
    echo "   Installed version: $NPM_VERSION"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠ WARNING${NC}"
    echo "   npm not found (required for running the UI server)"
    echo "   Install with Node.js from: https://nodejs.org/"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

#####################################################################
# Check 7: Terraform Installation (Optional)
#####################################################################
echo -n "Checking Terraform installation... "
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform --version | head -n1 | cut -d' ' -f2)
    echo -e "${GREEN}✓ PASSED${NC}"
    echo "   Installed version: $TF_VERSION"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠ WARNING${NC}"
    echo "   Terraform not found"
    echo "   Note: The UI server will run Terraform via shell commands"
    echo "   Install from: https://www.terraform.io/downloads"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

#####################################################################
# Check 8: User Permissions (Attempt to verify)
#####################################################################
echo -n "Checking Azure AD user roles... "
USER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")
if [ -n "$USER_ID" ]; then
    # Check if user has any admin roles
    ADMIN_ROLES=$(az rest --method GET --url "https://graph.microsoft.com/v1.0/me/memberOf" \
        --query "value[?contains(@odata.type, 'directoryRole')].displayName" -o tsv 2>/dev/null || echo "")

    if echo "$ADMIN_ROLES" | grep -q "Global Administrator"; then
        echo -e "${GREEN}✓ PASSED${NC}"
        echo "   Has Global Administrator role"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}⚠ WARNING${NC}"
        echo "   Could not verify Global Administrator role"
        echo "   This role is required for some operations"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠ WARNING${NC}"
    echo "   Could not retrieve user information"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

#####################################################################
# Summary
#####################################################################
echo "═══════════════════════════════════════════════════════════"
echo " Prerequisites Check Summary"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}Passed:${NC}   $PASSED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "${RED}Failed:${NC}   $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All critical prerequisites are met!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Start the UI server: npm run dev"
    echo "2. Open browser: http://localhost:5173"
    echo "3. Fill in the onboarding form"
    echo "4. Select desired Cortex Cloud features"
    echo "5. Click 'Start Onboarding'"
    echo ""

    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}Note: Some warnings were found. Review them above.${NC}"
        echo ""
    fi
    exit 0
else
    echo -e "${RED}✗ Prerequisites check failed!${NC}"
    echo ""
    echo "Please address the failed checks above before proceeding."
    echo "See PREREQUISITES.md for detailed setup instructions."
    echo ""
    exit 1
fi
