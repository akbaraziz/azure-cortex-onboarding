# Cortex Cloud Platform API Update Summary

**Date:** October 24, 2025
**Version:** 1.0.3
**Documentation Source:** https://pan.dev/prisma-cloud/api/cspm/api-urls/

## Overview

This document summarizes the updates made to the Azure Cortex Cloud Onboarding application based on the latest official Palo Alto Networks Cortex Cloud Platform API documentation.

---

## 1. API Regional Endpoints Update

### Previous Configuration (5 regions)
The application previously supported only 5 regional API endpoints:
- Americas - `https://api.prismacloud.io`
- Europe - `https://api.eu.prismacloud.io`
- Asia Pacific - `https://api.anz.prismacloud.io`
- Singapore - `https://api.sg.prismacloud.io`
- UK - `https://api.uk.prismacloud.io`

### Updated Configuration (16 regions)
The application now supports all 16 official regional API endpoints:

| Region | API URL | Status |
|--------|---------|--------|
| Americas (US) | `https://api.prismacloud.io` | ✅ Already supported |
| Americas (US 2) | `https://api2.prismacloud.io` | 🆕 **New** |
| Americas (US 3) | `https://api3.prismacloud.io` | 🆕 **New** |
| Americas (US 4) | `https://api4.prismacloud.io` | 🆕 **New** |
| Australia/New Zealand | `https://api.anz.prismacloud.io` | ✅ Already supported |
| Canada | `https://api.ca.prismacloud.io` | 🆕 **New** |
| China | `https://api.prismacloud.cn` | 🆕 **New** |
| Europe | `https://api.eu.prismacloud.io` | ✅ Already supported |
| Europe 2 | `https://api2.eu.prismacloud.io` | 🆕 **New** |
| France | `https://api.fr.prismacloud.io` | 🆕 **New** |
| US Government | `https://api.gov.prismacloud.io` | 🆕 **New** |
| India | `https://api.ind.prismacloud.io` | 🆕 **New** |
| Indonesia | `https://api.id.prismacloud.io` | 🆕 **New** |
| Japan | `https://api.jp.prismacloud.io` | 🆕 **New** |
| Singapore | `https://api.sg.prismacloud.io` | ✅ Already supported |
| UK | `https://api.uk.prismacloud.io` | ✅ Already supported |

**New Regions Added:** 11 additional regional endpoints

---

## 2. Azure Onboarding Process - Current vs. Official API

### Current Application Features
The application currently supports the following Azure onboarding features:

#### Cortex Cloud Feature Configuration
- ✅ **Cloud Visibility Compliance and Governance** - Basic resource discovery and compliance monitoring
- ✅ **Agentless Scanning** - VM and container vulnerability scanning via snapshots
- ✅ **Serverless Function Scanning** - Scan Azure Functions for vulnerabilities
- ✅ **Agent-Based Workload Protection** - Install and manage Defender agents
- ✅ **Remediation** - Auto-remediate security findings

#### Azure Infrastructure Options
- ✅ **Monitor Flow Logs** - Network flow logs monitoring

### Official Prisma Cloud API Features
According to the latest documentation, the official API supports these features:

**Supported Features Endpoint:** `POST /cas/v1/features/cloud/azure`

**Official Features:**
1. **Cloud Visibility Compliance and Governance** ✅ (default, included automatically)
2. **Agentless Scanning** ✅
3. **Serverless Function Scanning** ✅
4. **Remediation** ✅
5. **Auto Protect** ⚠️ (not explicitly listed in current app)

### Alignment Assessment

| Feature | Current App | Official API | Status |
|---------|-------------|--------------|--------|
| Cloud Visibility | ✅ | ✅ | ✅ Aligned |
| Agentless Scanning | ✅ | ✅ | ✅ Aligned |
| Serverless Scanning | ✅ | ✅ | ✅ Aligned |
| Remediation | ✅ | ✅ | ✅ Aligned |
| Agent-Based Protection | ✅ | Not in API docs | ⚠️ May be legacy/deprecated |
| Auto Protect | ❌ | ✅ | ⚠️ Missing from app |
| Monitor Flow Logs | ✅ | Not in API docs | ⚠️ May be legacy/Azure-specific |

---

## 3. Azure Onboarding API Workflow

Based on official documentation, the recommended Azure onboarding process consists of 4 steps:

### Step 1: Fetch Supported Features
**Endpoint:** `POST /cas/v1/features/cloud/azure`

**Request Example:**
```json
{
  "accountType": "account",
  "deploymentType": "azure"
}
```

**Response:** Returns list of supported features for the specified account type.

### Step 2: Generate Terraform Template
**Endpoint:** `POST /cas/v1/azure_template`

**Purpose:** Generate Terraform template with required Azure resources, roles, and permissions.

**Parameters:**
- Account type (account/tenant)
- Tenant ID
- Selected features
- Deployment type
- Subscription ID (for accounts)

### Step 3: Execute Terraform in Azure
**Process:**
1. Run generated Terraform template in Azure Portal
2. Create Azure AD application registration
3. Assign required roles and permissions
4. Grant admin consent to Graph API permissions
5. Capture output credentials

**Required Outputs:**
- `b_application_id` → Client ID
- `c_application_key` → Client Secret
- `e_service_principal_object_id` → Service Principal Object ID
- Tenant ID

### Step 4: Onboard Account to Prisma Cloud
**Endpoint:** `POST /cas/v1/azure_account`

**Request Parameters:**
- `clientId` (from application_id)
- `key` (from application_key)
- `servicePrincipalId` (from service_principal_object_id)
- Selected features with enabled/disabled states
- Account details (subscription ID, tenant ID, account type)

---

## 4. Account Types Supported

### Official Account Types
1. **Azure Subscription** - Individual subscription onboarding
2. **Azure Tenant** - Multi-subscription management with hierarchy (uses `rootSyncEnabled` parameter)
3. **Microsoft Entra ID** - Directory-only monitoring without resource scanning

### Current Application Support
The current application appears to focus on **Azure Subscription** onboarding. Consider adding support for:
- ⚠️ Azure Tenant onboarding (multi-subscription)
- ⚠️ Microsoft Entra ID-only integration

---

## 5. Recommendations

### High Priority
1. ✅ **Update API Regional Endpoints** - COMPLETED
   - Added 11 new regional endpoints
   - Organized alphabetically for better UX

2. ⚠️ **Verify "Auto Protect" Feature**
   - Investigate if this feature should be added to the UI
   - Consult Prisma Cloud documentation for Auto Protect capabilities

3. ⚠️ **Review Legacy Features**
   - Verify if "Agent-Based Workload Protection" is still supported by API
   - Confirm "Monitor Flow Logs" alignment with current API

### Medium Priority
4. **Add Account Type Selection**
   - Support for Azure Tenant onboarding
   - Support for Microsoft Entra ID-only integration
   - Add `rootSyncEnabled` parameter for tenant accounts

5. **Implement Pre-Onboarding Validation**
   - Add call to `/cas/v1/features/cloud/azure` before template generation
   - Dynamically show/hide features based on account type

6. **Enhance Error Handling**
   - Add specific error messages for each onboarding step
   - Provide troubleshooting guidance for common failures

### Low Priority
7. **Documentation Updates**
   - Update QUICKSTART.md with new regional endpoints
   - Update DEPLOYMENT_GUIDE.md with latest API workflow
   - Add API reference documentation

8. **Testing**
   - Test onboarding with each new regional endpoint
   - Validate feature combinations
   - Test with different account types

---

## 6. Files Modified

### Modified Files
1. **public/index.html**
   - Line 535-550: Updated Cortex Cloud API URL dropdown with 16 regions
   - Changed from 5 to 16 regional endpoints
   - Added alphabetical ordering and clearer region names

2. **package.json**
   - Updated version from 1.0.2 to 1.0.3

3. **VERSION_HISTORY.txt**
   - Added entry for version 1.0.3 with change description

---

## 7. Testing Recommendations

Before deploying to production:

1. **Functional Testing**
   - [ ] Test onboarding with each new regional endpoint
   - [ ] Verify all existing features still work correctly
   - [ ] Test with different Azure subscription types

2. **Regression Testing**
   - [ ] Ensure existing onboarding workflows are not broken
   - [ ] Verify Terraform template generation still works
   - [ ] Test credential retrieval and display

3. **Integration Testing**
   - [ ] Test actual Azure onboarding with new endpoints
   - [ ] Verify created resources in Azure Portal
   - [ ] Confirm connectivity to Cortex Cloud

---

## 8. Migration Notes

### Breaking Changes
- None. This is a backward-compatible update.

### User Impact
- Users will now see 16 regional options instead of 5
- Existing deployments will continue to work
- Users in newly supported regions can now select their local endpoint

### Rollback Plan
If issues are discovered:
1. Revert `public/index.html` to previous 5-region configuration
2. Revert `package.json` version to 1.0.2
3. Remove entry from `VERSION_HISTORY.txt`

---

## 9. Next Steps

1. **Deploy and Test** (v1.0.3)
   - Deploy updated application to staging environment
   - Test with sample Azure subscriptions
   - Verify all new regional endpoints are accessible

2. **Feature Enhancement** (v1.1.0)
   - Add "Auto Protect" feature if confirmed
   - Implement dynamic feature fetching from API
   - Add support for Azure Tenant and Entra ID account types

3. **Documentation** (v1.1.1)
   - Update all markdown documentation
   - Add API reference guide
   - Create troubleshooting guide for each region

---

## 10. References

- **Official API Documentation:** https://pan.dev/prisma-cloud/api/cspm/
- **API URLs Reference:** https://pan.dev/prisma-cloud/api/cspm/api-urls/
- **Azure Onboarding Guide:** https://pan.dev/prisma-cloud/docs/cspm/azure-account-onboarding/
- **Cloud Accounts API:** https://pan.dev/prisma-cloud/api/cspm/cloud-accounts-azure/

---

## Contact

For questions or issues related to this update, please review:
- QUICKSTART.md for quick start guide
- DEPLOYMENT_GUIDE.md for detailed deployment instructions
- Official Prisma Cloud documentation at https://pan.dev/

---

## 11. Latest Update: Custom API URL Input (v1.0.4)

**Date:** November 4, 2025

### Change Summary
Replaced the predefined regional URL dropdown with a custom text input field to support tenant-specific Cortex Cloud API URLs.

### Rationale
Each Cortex Cloud tenant has a unique FQDN (Fully Qualified Domain Name) assigned during provisioning. The previous dropdown approach with predefined regional URLs was insufficient because:
- ❌ Not all tenants use the standard regional URLs
- ❌ Customers have unique FQDNs like `https://api-customer.xdr.us.paloaltonetworks.com`
- ❌ No API exists to programmatically discover tenant URLs
- ✅ Users must obtain their URL from the Cortex Cloud console

### Changes Made

#### 1. UI Changes (public/index.html)
- **Removed:** Dropdown with 16 predefined Prisma Cloud regional URLs
- **Added:** Text input field for custom API URL entry
- **Added:** Informative help box with step-by-step instructions:
  1. Navigate to Settings → Configurations → Integrations → API Keys
  2. Look to the top right and select "Copy API URL"
- **Updated:** API endpoints to use dynamic URLs instead of hardcoded port 3001
- **Fixed:** Content Security Policy to allow React scripts from unpkg.com

#### 2. Server Changes (server.js)
- **Added:** Helmet CSP configuration to allow external scripts
- **Added:** WebSocket protocol detection (ws/wss)
- **Added:** Dynamic host/port handling

#### 3. Documentation Updates
- **README.md:** Updated Cortex Cloud Configuration section with new instructions
- **QUICKSTART.md:** Replaced "select your region from dropdown" with console instructions
- **CORTEX_UPDATE_SUMMARY.md:** Added this section documenting the change

### How Users Find Their API URL

Users can find their tenant-specific Cortex Cloud API URL by:
1. Logging into their Cortex Cloud console
2. Navigating to **Settings → Configurations → Integrations → API Keys**
3. Looking to the top right and selecting **"Copy API URL"**

The URL follows the pattern: `https://api-{fqdn}` where the FQDN is unique to their tenant.

### Migration Impact
- **Backward Compatible:** Yes
- **User Action Required:** Users must now enter their custom URL instead of selecting from dropdown
- **Existing Deployments:** Unaffected
- **Data Loss:** None

### References
- [Cortex Cloud Platform APIs Documentation](https://docs-cortex.paloaltonetworks.com/r/Cortex-Cloud-Platform-APIs/Cortex-Cloud-APIs)
- [Cortex XDR API Reference](https://docs-cortex.paloaltonetworks.com/r/Cortex-XDR-REST-API)

---

**Last Updated:** November 4, 2025
**Version:** 1.0.4
