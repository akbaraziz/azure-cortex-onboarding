# Cortex Cloud Onboarding Requirements

**Source:** Official Cortex Cloud Platform API Documentation v1.2
**Date:** October 23, 2025
**Project:** azure-cortex-ui

---

## Overview

This document outlines the requirements and naming conventions when onboarding Azure subscriptions to Cortex Cloud Platform using the Cloud Onboarding APIs.

---

## Required Fields for Onboarding Completion

### 1. **Create Instance Template** (Initial Step)

**Endpoint:** `POST /public_api/v1/cloud_onboarding/create_instance_template`

#### Required Request Fields

```json
{
  "request_data": {
    "scope": "ORGANIZATION",                    // REQUIRED
    "scan_mode": "MANAGED",                     // REQUIRED
    "cloud_provider": "AZURE",                  // REQUIRED
    "instance_name": "My Azure Instance",       // REQUIRED
    "account_details": {                        // REQUIRED for Azure only
      "organization_id": "tenant-id-here"       // Azure Tenant ID (REQUIRED)
    }
  }
}
```

#### Field Specifications

| Field | Type | Required | Description | Constraints |
|-------|------|----------|-------------|-------------|
| `scope` | string (enum) | **YES** | Define the scope for this integration instance | Must be: `ORGANIZATION`, `ACCOUNT_GROUP`, or `ACCOUNT` |
| `scan_mode` | string (enum) | **YES** | Define the scan mode | Must be: `MANAGED` (recommended) or `OUTPOST` |
| `cloud_provider` | string (enum) | **YES** | The cloud service provider | Must be: `AWS`, `AZURE`, or `GCP` |
| `instance_name` | string | **YES** | Display name for the integration instance | No explicit length limit documented |
| `account_details` | object | **YES** (Azure only) | Azure-specific account details | Required for Azure, not used for AWS/GCP |
| `account_details.organization_id` | string | **YES** | Azure tenant ID | Must be valid Azure tenant GUID |

#### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `custom_resources_tags` | array | Custom tags for resources (key-value pairs) |
| `collection_configuration` | object | Configure audit log collection |
| `scope_modifications` | object | Include/exclude specific subscriptions or regions |
| `additional_capabilities` | object | Enable XSIAM analytics, DSPM, registry scanning, etc. |

---

## Scope Options Explained

### For Azure Onboarding

| Scope Value | Azure Resource | Use When |
|-------------|----------------|----------|
| `ORGANIZATION` | Azure Tenant | Onboarding an entire Azure tenant (recommended for most cases) |
| `ACCOUNT_GROUP` | Azure Management Group | Onboarding a specific management group within a tenant |
| `ACCOUNT` | Azure Subscription | Onboarding a single Azure subscription |

---

## Instance Naming Requirements

### `instance_name` Field

- **Type:** String
- **Required:** YES
- **Purpose:** Human-readable display name for the integration instance
- **Example:** `"Azure Production"`, `"My Azure Instance"`, `"Production Tenant"`

### Naming Conventions (Best Practices)

While Cortex Cloud doesn't enforce specific naming patterns, consider these best practices:

1. **Be Descriptive:**
   - Include environment: `Azure Production`, `Azure Development`
   - Include purpose: `Azure Security Scanning`, `Azure Compliance`
   - Include organization unit: `Azure Finance Dept`, `Azure Engineering`

2. **Avoid Special Characters:**
   - While not explicitly forbidden, stick to alphanumeric and spaces
   - Avoid: `@`, `#`, `$`, `%`, `&`, `*`

3. **Length Considerations:**
   - Keep under 100 characters for display purposes
   - Recommended: 10-50 characters

4. **Uniqueness:**
   - While not enforced by API, use unique names for easier management
   - Duplicate names can cause confusion in the UI

### Examples of Good Instance Names

```
✅ "Azure Production - East US"
✅ "Azure Dev Environment"
✅ "Contoso Azure Tenant"
✅ "Azure Security Scanning - Main"
✅ "Production Subscriptions"
```

### Examples to Avoid

```
❌ "Instance123" (not descriptive)
❌ "Test" (too generic)
❌ "Azure@#$%Prod" (special characters)
❌ "a" (too short)
❌ "Very Long Unnecessarily Descriptive Name That Goes On And On..." (too long)
```

---

## Account Name Requirements

**Important:** Account names are **NOT** set during instance creation. They are discovered automatically after template execution.

### How Account Discovery Works

1. **Instance Created:** Instance is in `pending` state with your provided `instance_name`
2. **Template Executed:** You download and run the authentication template in Azure
3. **Accounts Discovered:** Cortex Cloud automatically discovers Azure subscriptions
4. **Account Metadata:** Each discovered subscription includes:
   - `account_id` - Cortex internal ID (e.g., `acc-789012`)
   - `subscription_id` - Azure subscription GUID (e.g., `12345678-1234-1234-1234-123456789abc`)
   - `status` - Current status (`active`, `inactive`, `error`)
   - `enabled` - Whether the account is enabled for scanning (`true`/`false`)

### Account Naming Notes

- Cortex uses Azure subscription names from Azure itself
- You cannot customize account names during onboarding
- Account display names come from Azure subscription properties
- You can filter/manage accounts after discovery using `enable_disable_account` API

---

## Complete Onboarding Workflow

### Step 1: Create Integration Instance Template

```bash
POST /public_api/v1/cloud_onboarding/create_instance_template

{
  "request_data": {
    "scope": "ORGANIZATION",
    "scan_mode": "MANAGED",
    "cloud_provider": "AZURE",
    "instance_name": "Azure Production",
    "account_details": {
      "organization_id": "12345678-1234-1234-1234-123456789abc"
    }
  }
}
```

**Response:**
```json
{
  "instance_id": "inst-123456",
  "status": "pending",
  "template_url": "https://api.cortex.paloaltonetworks.com/download/template/xyz"
}
```

**Result:** Instance created in `pending` state

---

### Step 2: Download and Execute Authentication Template

1. Use the `template_url` from Step 1 response
2. Download the Azure deployment template (ARM or Terraform)
3. Execute in your Azure tenant
4. Template creates:
   - Service principal with required permissions
   - Reader role assignments
   - Required permissions for security scanning

**Note:** If template execution fails, manual execution via UI is required (no API support for retry)

---

### Step 3: Verify Instance Status

```bash
POST /public_api/v1/cloud_onboarding/get_instance_details

{
  "instance_id": "inst-123456"
}
```

**Response (After Successful Authentication):**
```json
{
  "instance_id": "inst-123456",
  "name": "Azure Production",
  "cloud_provider": "AZURE",
  "status": "authenticated",  // Changed from "pending"
  "accounts": [
    {
      "account_id": "acc-789012",
      "subscription_id": "12345678-1234-1234-1234-123456789abc",
      "subscription_name": "Azure Production Subscription",
      "status": "discovered",
      "enabled": false
    }
  ],
  "configuration": {...}
}
```

---

### Step 4: Enable the Instance

```bash
POST /public_api/v1/cloud_onboarding/enable_disable_instance

{
  "instance_ids": ["inst-123456"],
  "enable": true
}
```

**Response:**
```json
{
  "success": true,
  "affected_instances": ["inst-123456"]
}
```

**Result:** Instance status changes to `active`

---

### Step 5: Verify Accounts and Enable Scanning

```bash
POST /public_api/v1/cloud_onboarding/get_accounts

{
  "instance_id": "inst-123456"
}
```

**Response:**
```json
{
  "accounts": [
    {
      "account_id": "acc-789012",
      "subscription_id": "12345678-1234-1234-1234-123456789abc",
      "subscription_name": "Azure Production Subscription",
      "status": "active",
      "enabled": true
    },
    {
      "account_id": "acc-789013",
      "subscription_id": "87654321-4321-4321-4321-cba987654321",
      "subscription_name": "Azure Development Subscription",
      "status": "active",
      "enabled": true
    }
  ]
}
```

---

## Onboarding Completion Checklist

Use this checklist to confirm onboarding is complete:

- [ ] **Instance Created:** Instance exists with `instance_id`
- [ ] **Template Downloaded:** Authentication template downloaded from `template_url`
- [ ] **Template Executed:** Template successfully deployed in Azure tenant
- [ ] **Instance Authenticated:** Instance status changed from `pending` to `authenticated`
- [ ] **Instance Enabled:** Instance status changed to `active` via enable API
- [ ] **Accounts Discovered:** At least one Azure subscription appears in accounts list
- [ ] **Accounts Enabled:** Desired accounts enabled for scanning
- [ ] **Scanning Started:** Cortex Cloud begins security scanning (automatic after enable)

---

## Instance States

| State | Description | Next Action |
|-------|-------------|-------------|
| `pending` | Instance created, awaiting authentication | Download and execute template |
| `authenticated` | Template executed successfully | Enable the instance |
| `active` | Instance enabled and scanning | Normal operation, manage accounts |
| `disabled` | Instance disabled by user | Re-enable via API or UI |
| `error` | Authentication or configuration error | Check error message, retry template |

---

## Azure-Specific Requirements

### Required Information Before Onboarding

1. **Azure Tenant ID** (GUID format)
   - Found in: Azure Portal → Azure Active Directory → Properties
   - Example: `12345678-1234-1234-1234-123456789abc`

2. **Azure Subscription Access**
   - Requires Owner or Contributor role to execute template
   - Permissions needed to create service principal

3. **Azure AD Permissions**
   - Ability to consent to app registrations
   - May require Global Administrator or Application Administrator role

### Scope Modifications for Azure

When using `ORGANIZATION` scope, you can filter subscriptions:

```json
{
  "scope_modifications": {
    "subscriptions": {
      "enabled": true,
      "type": "INCLUDE",  // or "EXCLUDE"
      "subscription_ids": [
        "12345678-1234-1234-1234-123456789abc",
        "87654321-4321-4321-4321-cba987654321"
      ]
    },
    "regions": {
      "enabled": true,
      "type": "INCLUDE",  // or "EXCLUDE"
      "regions": [
        "eastus",
        "westus2",
        "centralus"
      ]
    }
  }
}
```

---

## Common Errors and Solutions

### Error: "Invalid tenant ID"

**Cause:** `account_details.organization_id` is not a valid Azure tenant GUID

**Solution:**
- Verify tenant ID from Azure Portal
- Ensure GUID format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

### Error: "Template execution failed"

**Cause:** Insufficient permissions in Azure or template deployment error

**Solution:**
- Check Azure account has Owner/Contributor role
- Verify no Azure policy blocking service principal creation
- Review Azure deployment error logs
- Currently requires manual retry via Cortex UI (no API support)

### Error: "No accounts discovered"

**Cause:** Template not executed or executed in wrong tenant

**Solution:**
- Verify template was executed in correct Azure tenant
- Check service principal exists in Azure AD
- Verify service principal has Reader role on subscriptions
- Wait 5-10 minutes for account discovery process

### Error: "Instance already exists"

**Cause:** Duplicate instance name or tenant already onboarded

**Solution:**
- Use different `instance_name`
- Check existing instances with `get_instances` API
- Delete old instance if no longer needed

---

## API Authentication Requirements

All onboarding APIs require:

1. **Headers:**
   - `Authorization: {api_key}` - Your Cortex API key
   - `x-xdr-auth-id: {api_key_id}` - Your API key ID
   - `Content-Type: application/json`

2. **Permissions:**
   - API key must have Cloud Onboarding permissions
   - Requires Cortex Cloud Posture Management license

---

## Best Practices

### 1. Use ORGANIZATION Scope

- Onboard entire Azure tenant for comprehensive coverage
- Use scope modifications to exclude specific subscriptions if needed
- Easier management than onboarding subscriptions individually

### 2. Use MANAGED Scan Mode

- Recommended by Palo Alto Networks
- Scanning performed in Cortex cloud environment
- Lower CSP costs compared to OUTPOST mode
- Simpler setup, fewer permissions required

### 3. Enable Audit Log Collection

```json
{
  "collection_configuration": {
    "audit_logs": {
      "enabled": true
    }
  }
}
```

- Provides better security coverage
- Required for compliance use cases
- May require additional Azure permissions

### 4. Use Descriptive Instance Names

- Include environment, purpose, or organizational unit
- Makes management easier when you have multiple instances
- Example: `Azure Production - Security Team`

### 5. Track Instance IDs

- Store `instance_id` returned from create API
- Required for all subsequent API calls
- Use `get_instances` API to retrieve if lost

---

## Summary

### Required for Onboarding Completion

1. ✅ **instance_name** - Human-readable name for the instance
2. ✅ **cloud_provider** - Must be `AZURE` for Azure onboarding
3. ✅ **scope** - Choose `ORGANIZATION`, `ACCOUNT_GROUP`, or `ACCOUNT`
4. ✅ **scan_mode** - Choose `MANAGED` (recommended) or `OUTPOST`
5. ✅ **account_details.organization_id** - Azure tenant ID (GUID format)

### Created During Onboarding

- ❌ **Account names** - NOT set by user, discovered from Azure subscriptions
- ✅ **instance_id** - Generated by Cortex Cloud
- ✅ **template_url** - Generated by Cortex Cloud

### Post-Onboarding

- Enable instance via `enable_disable_instance` API
- Verify accounts discovered via `get_accounts` API
- Enable/disable specific accounts via `enable_disable_account` API
- Monitor scanning status via `get_instance_details` API

---

## Additional Resources

- **Official Documentation:** https://docs-cortex.paloaltonetworks.com/
- **API Base URL:** `https://api-{your-fqdn}/public_api/v1/cloud_onboarding/`
- **API Version:** Cortex Cloud 1.2
- **Required License:** Cortex Cloud Posture Management or Cortex Cloud Runtime Security

---

**Document Version:** 1.0
**Last Updated:** October 23, 2025
**Source:** Official Cortex Cloud Platform API Documentation
**Project:** azure-cortex-ui
