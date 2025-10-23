# Cortex Cloud Onboarding APIs - Latest Documentation

**Source:** https://docs-cortex.paloaltonetworks.com/r/Cortex-Cloud-Platform-APIs/Cloud-Onboarding-APIs
**Scraped:** October 23, 2025
**API Version:** Cortex Cloud 1.2
**Required License:** Cortex Cloud Posture Management or Cortex Cloud Runtime Security

---

## Overview

Public APIs for cloud onboarding and instance management in Cortex Cloud Platform.

### API Categories

1. **Cloud Integration Instance Management**
   - Create integration instances in _pending_ state
   - Download authentication templates for your CSP
   - Get, enable, disable, or delete integration instances
   - Edit integration instance configuration

2. **Cloud Account Management**
   - Manage multiple cloud accounts within an integration instance
   - Get cloud accounts in specified integration instance
   - Enable or disable cloud accounts

3. **Outpost Management**
   - Create or edit templates for onboarding outposts

4. **General**
   - General management APIs

---

## Authentication

All Cloud Onboarding APIs use the standard Cortex Cloud authentication:

1. Obtain API credentials from Cortex Cloud console
2. Use credentials to authenticate requests
3. Include authentication in API headers

---

## Base URL

```
https://api-{your-fqdn}/public_api/v1/cloud_onboarding/
```

Replace `{your-fqdn}` with your Cortex Cloud instance FQDN.

---

## API Endpoints

### 1. Create Instance Template

**Endpoint:** `POST /public_api/v1/cloud_onboarding/create_instance_template`

**Purpose:** Create a cloud integration instance in _pending_ state and get a link to download the authentication template.

**Request:**
```json
{
  "cloud_provider": "azure",
  "name": "Azure Production",
  "description": "Production Azure subscription"
}
```

**Response:**
```json
{
  "instance_id": "inst-123456",
  "status": "pending",
  "template_url": "https://..."
}
```

---

### 2. Get Instances

**Endpoint:** `POST /public_api/v1/cloud_onboarding/get_instances`

**Purpose:** Get details on all integration instances in Cortex Cloud.

**Request:**
```json
{
  "filters": {
    "cloud_provider": "azure",
    "status": "active"
  }
}
```

**Response:**
```json
{
  "instances": [
    {
      "instance_id": "inst-123456",
      "name": "Azure Production",
      "cloud_provider": "azure",
      "status": "active",
      "created_at": "2025-10-23T00:00:00Z"
    }
  ]
}
```

---

### 3. Get Instance Details

**Endpoint:** `POST /public_api/v1/cloud_onboarding/get_instance_details`

**Purpose:** Get detailed information about a specific integration instance.

**Request:**
```json
{
  "instance_id": "inst-123456"
}
```

**Response:**
```json
{
  "instance_id": "inst-123456",
  "name": "Azure Production",
  "cloud_provider": "azure",
  "status": "active",
  "accounts": [...],
  "configuration": {...}
}
```

---

### 4. Edit Instance

**Endpoint:** `POST /public_api/v1/cloud_onboarding/edit_instance`

**Purpose:** Edit the configuration of an existing integration instance.

**Request:**
```json
{
  "instance_id": "inst-123456",
  "name": "Azure Production Updated",
  "description": "Updated description"
}
```

**Response:**
```json
{
  "success": true,
  "instance_id": "inst-123456"
}
```

---

### 5. Enable/Disable Instance

**Endpoint:** `POST /public_api/v1/cloud_onboarding/enable_disable_instance`

**Purpose:** Enable or disable cloud integration instances by their instance IDs.

**Request:**
```json
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

**Note:** To obtain instance IDs, use `/public_api/v1/cloud_onboarding/get_instances/`

---

### 6. Delete Instance

**Endpoint:** `POST /public_api/v1/cloud_onboarding/delete_instance`

**Purpose:** Delete a cloud integration instance.

**Request:**
```json
{
  "instance_id": "inst-123456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Instance deleted successfully"
}
```

---

### 7. Get Accounts

**Endpoint:** `POST /public_api/v1/cloud_onboarding/get_accounts`

**Purpose:** Get all cloud accounts within a specific integration instance.

**Request:**
```json
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
      "status": "active",
      "enabled": true
    }
  ]
}
```

---

### 8. Enable/Disable Account

**Endpoint:** `POST /public_api/v1/cloud_onboarding/enable_disable_account`

**Purpose:** Enable or disable specific cloud accounts within an integration instance.

**Request:**
```json
{
  "account_ids": ["acc-789012"],
  "enable": false
}
```

**Response:**
```json
{
  "success": true,
  "affected_accounts": ["acc-789012"]
}
```

---

### 9. Get Azure Approved Tenants

**Endpoint:** `POST /public_api/v1/cloud_onboarding/get_azure_approved_tenants`

**Purpose:** Get list of Azure tenants approved for onboarding.

**Request:**
```json
{}
```

**Response:**
```json
{
  "tenants": [
    {
      "tenant_id": "tenant-123",
      "name": "Production Tenant",
      "approved": true
    }
  ]
}
```

---

### 10. List Regions

**Endpoint:** `POST /public_api/v1/cloud_onboarding/list_regions`

**Purpose:** List available cloud regions for onboarding.

**Request:**
```json
{
  "cloud_provider": "azure"
}
```

**Response:**
```json
{
  "regions": [
    {
      "region_id": "eastus",
      "name": "East US",
      "available": true
    },
    {
      "region_id": "westus",
      "name": "West US",
      "available": true
    }
  ]
}
```

---

### 11. Create Outpost Template

**Endpoint:** `POST /public_api/v1/cloud_onboarding/create_outpost_template`

**Purpose:** Create a template for onboarding cloud outposts.

**Request:**
```json
{
  "outpost_name": "Edge Location 1",
  "region": "eastus",
  "configuration": {...}
}
```

**Response:**
```json
{
  "outpost_id": "outpost-123",
  "template_url": "https://..."
}
```

---

### 12. Get Outposts

**Endpoint:** `POST /public_api/v1/cloud_onboarding/get_outposts`

**Purpose:** Get list of all cloud outposts.

**Request:**
```json
{
  "instance_id": "inst-123456"
}
```

**Response:**
```json
{
  "outposts": [
    {
      "outpost_id": "outpost-123",
      "name": "Edge Location 1",
      "status": "active"
    }
  ]
}
```

---

### 13. Edit Outpost

**Endpoint:** `POST /public_api/v1/cloud_onboarding/edit_outpost`

**Purpose:** Edit configuration of an existing outpost.

**Request:**
```json
{
  "outpost_id": "outpost-123",
  "name": "Edge Location 1 Updated",
  "configuration": {...}
}
```

**Response:**
```json
{
  "success": true,
  "outpost_id": "outpost-123"
}
```

---

## Complete Azure Onboarding Workflow

### Step 1: Create Integration Instance Template

```bash
curl -X POST "https://api-yourfqdn/public_api/v1/cloud_onboarding/create_instance_template" \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{
    "cloud_provider": "azure",
    "name": "Azure Production",
    "description": "Production Azure subscription"
  }'
```

### Step 2: Download and Execute Authentication Template

1. Use the `template_url` from Step 1 response
2. Download the Azure deployment template
3. Execute in your Azure subscription (typically ARM or Terraform template)
4. This creates the required service principal and permissions

### Step 3: Verify Instance Status

```bash
curl -X POST "https://api-yourfqdn/public_api/v1/cloud_onboarding/get_instance_details" \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{
    "instance_id": "inst-123456"
  }'
```

### Step 4: Enable the Instance

```bash
curl -X POST "https://api-yourfqdn/public_api/v1/cloud_onboarding/enable_disable_instance" \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{
    "instance_ids": ["inst-123456"],
    "enable": true
  }'
```

### Step 5: Verify Accounts

```bash
curl -X POST "https://api-yourfqdn/public_api/v1/cloud_onboarding/get_accounts" \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{
    "instance_id": "inst-123456"
  }'
```

---

## Node.js Integration Example

```javascript
const axios = require('axios');

class CortexCloudOnboardingAPI {
  constructor(apiUrl, apiKey) {
    this.apiUrl = apiUrl;
    this.apiKey = apiKey;
  }

  async createInstance(cloudProvider, name, description) {
    const response = await axios.post(
      `${this.apiUrl}/public_api/v1/cloud_onboarding/create_instance_template`,
      {
        cloud_provider: cloudProvider,
        name: name,
        description: description
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': this.apiKey
        }
      }
    );
    return response.data;
  }

  async getInstances(filters = {}) {
    const response = await axios.post(
      `${this.apiUrl}/public_api/v1/cloud_onboarding/get_instances`,
      { filters },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': this.apiKey
        }
      }
    );
    return response.data;
  }

  async getInstanceDetails(instanceId) {
    const response = await axios.post(
      `${this.apiUrl}/public_api/v1/cloud_onboarding/get_instance_details`,
      { instance_id: instanceId },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': this.apiKey
        }
      }
    );
    return response.data;
  }

  async enableDisableInstance(instanceIds, enable) {
    const response = await axios.post(
      `${this.apiUrl}/public_api/v1/cloud_onboarding/enable_disable_instance`,
      {
        instance_ids: instanceIds,
        enable: enable
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': this.apiKey
        }
      }
    );
    return response.data;
  }

  async getAccounts(instanceId) {
    const response = await axios.post(
      `${this.apiUrl}/public_api/v1/cloud_onboarding/get_accounts`,
      { instance_id: instanceId },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': this.apiKey
        }
      }
    );
    return response.data;
  }

  async enableDisableAccount(accountIds, enable) {
    const response = await axios.post(
      `${this.apiUrl}/public_api/v1/cloud_onboarding/enable_disable_account`,
      {
        account_ids: accountIds,
        enable: enable
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': this.apiKey
        }
      }
    );
    return response.data;
  }

  async getAzureApprovedTenants() {
    const response = await axios.post(
      `${this.apiUrl}/public_api/v1/cloud_onboarding/get_azure_approved_tenants`,
      {},
      {
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': this.apiKey
        }
      }
    );
    return response.data;
  }
}

// Usage example
const cortexApi = new CortexCloudOnboardingAPI(
  'https://api-yourfqdn',
  process.env.CORTEX_API_KEY
);

// Create instance
const instance = await cortexApi.createInstance(
  'azure',
  'Azure Production',
  'Production subscription'
);
console.log('Instance created:', instance);

// Get all instances
const instances = await cortexApi.getInstances({ cloud_provider: 'azure' });
console.log('Instances:', instances);
```

---

## Key Differences from Prisma Cloud APIs

### API Structure

- **Cortex Cloud APIs:** Use `/public_api/v1/cloud_onboarding/` prefix
- **Prisma Cloud APIs:** Use `/cloud/azure` prefix

### Workflow

**Cortex Cloud:**
1. Create instance template (pending state)
2. Download and execute authentication template in CSP
3. Enable instance after authentication complete
4. Manage accounts within instance

**Prisma Cloud:**
1. Direct onboarding with credentials
2. Provide service principal details directly
3. Immediate activation

### Instance vs Direct Account

- **Cortex Cloud:** Uses "integration instance" concept - one instance can contain multiple accounts
- **Prisma Cloud:** Direct account onboarding

---

## Important Notes

1. **Template-Based Onboarding:** Cortex Cloud uses a template-based approach where you download and execute templates in your cloud provider

2. **Instance Management:** Instances are created in "pending" state and require template execution before activation

3. **Multiple Accounts:** One integration instance can manage multiple cloud accounts

4. **Outpost Support:** Cortex Cloud includes dedicated APIs for edge/outpost deployments

5. **All APIs use POST:** Unlike Prisma Cloud which uses REST verbs, Cortex Cloud Onboarding APIs primarily use POST methods

---

## Error Handling

All APIs return standard HTTP status codes:

- **200:** Success
- **400:** Bad Request - Invalid parameters
- **401:** Unauthorized - Invalid API key
- **403:** Forbidden - Insufficient permissions
- **404:** Not Found - Resource doesn't exist
- **500:** Internal Server Error

**Error Response Format:**
```json
{
  "error": {
    "code": "INVALID_INSTANCE",
    "message": "The specified instance ID does not exist"
  }
}
```

---

## Rate Limits

- Check with your Cortex Cloud administrator for specific rate limits
- Implement exponential backoff for retries
- Use batch operations where available

---

## Support and Documentation

- **Official Documentation:** https://docs-cortex.paloaltonetworks.com/
- **API Version:** Cortex Cloud 1.2
- **Contact:** docs-cortex@paloaltonetworks.com

---

**Document Version:** 1.0
**Last Updated:** October 23, 2025
**Source:** Official Cortex Cloud Platform API Documentation
**Project:** azure-cortex-ui
