# Cortex Cloud - Azure Onboarding APIs

**Documentation for:** azure-cortex-ui project
**API Base:** Prisma Cloud / Cortex Cloud REST API
**Source:** https://pan.dev/prisma-cloud/api/cspm/cloud-accounts-azure/

---

## Overview

This document details the **Cortex Cloud Platform APIs for Azure Cloud Onboarding**, specifically for automating Azure subscription onboarding to Cortex Cloud (formerly Prisma Cloud).

---

## Authentication

### 1. Obtain Access Key

Generate an API access key from Cortex Cloud console:
- Navigate to **Settings → Access Keys**
- Create new access key (Access Key ID + Secret Key)
- Note the key expires based on your configuration

### 2. Login to Get JWT Token

**Endpoint:** `POST /login`

**Request:**
```http
POST https://api.prismacloud.io/login
Content-Type: application/json

{
  "username": "YOUR_ACCESS_KEY_ID",
  "password": "YOUR_SECRET_KEY"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "message": "login_successful"
}
```

### 3. Use JWT in All Requests

**Required Header:**
```
x-redlock-auth: YOUR_JWT_TOKEN
```

---

## Azure Cloud Account Onboarding APIs

### List All Cloud Accounts

**Endpoint:** `GET /cloud`

**Request:**
```http
GET https://api.prismacloud.io/cloud
x-redlock-auth: YOUR_JWT_TOKEN
```

**Response:**
```json
[
  {
    "accountId": "subscription-id",
    "accountType": "account",
    "cloudType": "azure",
    "enabled": true,
    "name": "Azure-Production",
    "lastModifiedBy": "user@example.com",
    "lastModifiedTs": 1698765432000
  }
]
```

---

### Get Supported Azure Features

**Endpoint:** `GET /cloud/azure/supportedFeatures`

**Request:**
```http
GET https://api.prismacloud.io/cloud/azure/supportedFeatures
x-redlock-auth: YOUR_JWT_TOKEN
```

**Response:**
```json
{
  "supportedFeatures": [
    "Cloud Visibility Compliance and Governance",
    "Agentless Scanning",
    "Serverless Function Scanning",
    "Agent-Based Workload Protection",
    "Remediation"
  ],
  "licenseType": "ENTERPRISE"
}
```

---

### Add Azure Cloud Account

**Endpoint:** `POST /cloud/azure`

**Request Body Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `accountId` | string | Yes | Azure Subscription ID |
| `accountType` | string | Yes | `"account"` for subscription, `"tenant"` for tenant |
| `enabled` | boolean | Yes | Enable monitoring (typically `true`) |
| `groupIds` | array | No | Account group IDs to associate |
| `name` | string | Yes | Display name for the account |
| `clientId` | string | Yes | Azure Application (Client) ID |
| `key` | string | Yes | Azure Application Client Secret |
| `tenantId` | string | Yes | Azure Tenant ID |
| `servicePrincipalId` | string | Yes | Service Principal Object ID |
| `monitorFlowLogs` | boolean | No | Enable network flow log monitoring |
| `features` | array | No | Array of feature configurations |

**Full Request Example:**
```http
POST https://api.prismacloud.io/cloud/azure
Content-Type: application/json
x-redlock-auth: YOUR_JWT_TOKEN

{
  "accountId": "12345678-1234-1234-1234-123456789abc",
  "accountType": "account",
  "enabled": true,
  "groupIds": [],
  "name": "Azure-Production",
  "clientId": "app-client-id",
  "key": "app-client-secret",
  "tenantId": "tenant-id",
  "servicePrincipalId": "service-principal-object-id",
  "monitorFlowLogs": true,
  "features": [
    {
      "name": "Cloud Visibility Compliance and Governance",
      "state": "enabled"
    },
    {
      "name": "Agentless Scanning",
      "state": "enabled"
    },
    {
      "name": "Serverless Function Scanning",
      "state": "enabled"
    },
    {
      "name": "Remediation",
      "state": "enabled"
    }
  ]
}
```

**Success Response (200):**
```json
{
  "accountId": "12345678-1234-1234-1234-123456789abc",
  "cloudType": "azure",
  "enabled": true,
  "name": "Azure-Production",
  "status": "onboarded"
}
```

**Error Response (400):**
```json
{
  "statusCode": 400,
  "message": "Invalid Azure credentials",
  "details": "Unable to verify service principal access"
}
```

---

### Update Azure Cloud Account

**Endpoint:** `PUT /cloud/azure/{cloudAccountId}`

**Request:**
```http
PUT https://api.prismacloud.io/cloud/azure/12345678-1234-1234-1234-123456789abc
Content-Type: application/json
x-redlock-auth: YOUR_JWT_TOKEN

{
  "accountId": "12345678-1234-1234-1234-123456789abc",
  "enabled": true,
  "name": "Azure-Production-Updated",
  "clientId": "app-client-id",
  "key": "new-app-client-secret",
  "tenantId": "tenant-id",
  "servicePrincipalId": "service-principal-object-id",
  "monitorFlowLogs": true
}
```

---

### Delete Azure Cloud Account

**Endpoint:** `DELETE /cloud/azure/{cloudAccountId}`

**Request:**
```http
DELETE https://api.prismacloud.io/cloud/azure/12345678-1234-1234-1234-123456789abc
x-redlock-auth: YOUR_JWT_TOKEN
```

**Response (204):** No content on success

---

### Get Azure Account Status

**Endpoint:** `GET /cloud/{cloudType}/{cloudAccountId}/status`

**Request:**
```http
GET https://api.prismacloud.io/cloud/azure/12345678-1234-1234-1234-123456789abc/status
x-redlock-auth: YOUR_JWT_TOKEN
```

**Response:**
```json
{
  "accountId": "12345678-1234-1234-1234-123456789abc",
  "cloudType": "azure",
  "status": "enabled",
  "checks": {
    "networkReachable": true,
    "credentialsValid": true,
    "permissionsSufficient": true
  },
  "lastScanned": 1698765432000
}
```

---

### Validate Azure Credentials (Pre-Onboarding)

**Endpoint:** `POST /cloud/azure/validate`

Use this endpoint to validate Azure credentials **before** onboarding.

**Request:**
```http
POST https://api.prismacloud.io/cloud/azure/validate
Content-Type: application/json
x-redlock-auth: YOUR_JWT_TOKEN

{
  "accountId": "12345678-1234-1234-1234-123456789abc",
  "clientId": "app-client-id",
  "key": "app-client-secret",
  "tenantId": "tenant-id",
  "servicePrincipalId": "service-principal-object-id"
}
```

**Success Response (200):**
```json
{
  "valid": true,
  "message": "Azure credentials validated successfully",
  "permissions": {
    "reader": true,
    "customRole": false
  }
}
```

**Error Response (400):**
```json
{
  "valid": false,
  "message": "Invalid credentials or insufficient permissions",
  "errors": [
    "Service principal does not have Reader role",
    "Unable to access subscription resources"
  ]
}
```

---

## Feature Configuration

### Available Features

| Feature Name | Description | Required Permissions |
|--------------|-------------|----------------------|
| **Cloud Visibility Compliance and Governance** | Basic resource discovery and compliance monitoring | Reader |
| **Agentless Scanning** | VM and container vulnerability scanning via snapshots | Reader + Disk access |
| **Serverless Function Scanning** | Scan Azure Functions for vulnerabilities | Reader |
| **Agent-Based Workload Protection** | Install and manage Defender agents | Contributor (targeted resources) |
| **Remediation** | Auto-remediate security findings | Contributor (specific resources) |

### Feature State Options

```json
{
  "name": "Feature Name",
  "state": "enabled" | "disabled"
}
```

---

## Azure Prerequisites

### 1. Create Service Principal

```bash
# Create service principal with Reader role
az ad sp create-for-rbac \
  --name "CortexCloudApp" \
  --role "Reader" \
  --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

**Output:**
```json
{
  "appId": "client-id",
  "displayName": "CortexCloudApp",
  "password": "client-secret",
  "tenant": "tenant-id"
}
```

### 2. Get Service Principal Object ID

```bash
# Get the Object ID
az ad sp show --id "client-id" --query "id" -o tsv
```

### 3. Custom Role (Recommended)

Create a custom role with enhanced permissions:

```json
{
  "Name": "Cortex Cloud Reader",
  "Description": "Custom role for Cortex Cloud monitoring",
  "Actions": [
    "*/read",
    "Microsoft.Network/networkWatchers/queryFlowLogStatus/action",
    "Microsoft.Compute/virtualMachines/extensions/read",
    "Microsoft.Storage/storageAccounts/listKeys/action"
  ],
  "NotActions": [],
  "AssignableScopes": [
    "/subscriptions/YOUR_SUBSCRIPTION_ID"
  ]
}
```

```bash
# Create custom role
az role definition create --role-definition cortex-role.json

# Assign custom role to service principal
az role assignment create \
  --assignee "client-id" \
  --role "Cortex Cloud Reader" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

---

## Complete Onboarding Workflow

### Step-by-Step Process

```javascript
const onboardAzureSubscription = async (config) => {
  // 1. Login to Cortex Cloud
  const loginResponse = await axios.post('https://api.prismacloud.io/login', {
    username: process.env.CORTEX_ACCESS_KEY,
    password: process.env.CORTEX_SECRET_KEY
  });
  const token = loginResponse.data.token;

  // 2. Validate Azure credentials (optional but recommended)
  const validateResponse = await axios.post(
    'https://api.prismacloud.io/cloud/azure/validate',
    {
      accountId: config.subscriptionId,
      clientId: config.clientId,
      key: config.clientSecret,
      tenantId: config.tenantId,
      servicePrincipalId: config.servicePrincipalId
    },
    { headers: { 'x-redlock-auth': token } }
  );

  if (!validateResponse.data.valid) {
    throw new Error('Azure credentials validation failed');
  }

  // 3. Get supported features
  const featuresResponse = await axios.get(
    'https://api.prismacloud.io/cloud/azure/supportedFeatures',
    { headers: { 'x-redlock-auth': token } }
  );

  // 4. Onboard Azure account
  const onboardResponse = await axios.post(
    'https://api.prismacloud.io/cloud/azure',
    {
      accountId: config.subscriptionId,
      accountType: 'account',
      enabled: true,
      name: config.accountName,
      clientId: config.clientId,
      key: config.clientSecret,
      tenantId: config.tenantId,
      servicePrincipalId: config.servicePrincipalId,
      monitorFlowLogs: true,
      features: featuresResponse.data.supportedFeatures.map(name => ({
        name,
        state: 'enabled'
      }))
    },
    { headers: { 'x-redlock-auth': token } }
  );

  // 5. Check status
  const statusResponse = await axios.get(
    `https://api.prismacloud.io/cloud/azure/${config.subscriptionId}/status`,
    { headers: { 'x-redlock-auth': token } }
  );

  return {
    success: true,
    account: onboardResponse.data,
    status: statusResponse.data
  };
};
```

---

## Error Handling

### Common Error Codes

| Status Code | Error | Solution |
|-------------|-------|----------|
| 400 | Invalid credentials | Verify service principal credentials |
| 401 | Unauthorized | JWT token expired or invalid |
| 403 | Forbidden | Insufficient API permissions |
| 409 | Conflict | Account already onboarded |
| 500 | Internal Server Error | Retry with exponential backoff |

### Retry Strategy

```javascript
const retryWithBackoff = async (fn, maxRetries = 3) => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (error.response?.status === 401) {
        // Refresh token
        await refreshToken();
        continue;
      }
      if (error.response?.status >= 500 || error.response?.status === 429) {
        // Server error or rate limit - retry with backoff
        const delay = Math.pow(2, i) * 1000 + Math.random() * 1000;
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }
      throw error; // Don't retry client errors
    }
  }
  throw new Error('Max retries exceeded');
};
```

---

## Integration with azure-cortex-ui

### Update server.js

Add Cortex Cloud API integration to your Express backend:

```javascript
const axios = require('axios');

// Cortex Cloud API client
class CortexCloudAPI {
  constructor(apiUrl, accessKey, secretKey) {
    this.apiUrl = apiUrl;
    this.accessKey = accessKey;
    this.secretKey = secretKey;
    this.token = null;
  }

  async login() {
    const response = await axios.post(`${this.apiUrl}/login`, {
      username: this.accessKey,
      password: this.secretKey
    });
    this.token = response.data.token;
    return this.token;
  }

  async onboardAzure(azureConfig) {
    if (!this.token) await this.login();

    return axios.post(
      `${this.apiUrl}/cloud/azure`,
      azureConfig,
      { headers: { 'x-redlock-auth': this.token } }
    );
  }

  async getAccountStatus(subscriptionId) {
    if (!this.token) await this.login();

    return axios.get(
      `${this.apiUrl}/cloud/azure/${subscriptionId}/status`,
      { headers: { 'x-redlock-auth': this.token } }
    );
  }
}

// Usage in your onboarding endpoint
app.post('/api/start-onboarding', async (req, res) => {
  const {
    subscriptionId,
    tenantId,
    cortexApiUrl,
    cortexAccessKey,
    cortexSecretKey,
    applicationId,
    applicationSecret,
    servicePrincipalId
  } = req.body;

  try {
    // Initialize Cortex API client
    const cortex = new CortexCloudAPI(
      cortexApiUrl,
      cortexAccessKey,
      cortexSecretKey
    );

    // Onboard to Cortex Cloud
    const onboardResponse = await cortex.onboardAzure({
      accountId: subscriptionId,
      accountType: 'account',
      enabled: true,
      name: req.body.azureAccountName,
      clientId: applicationId,
      key: applicationSecret,
      tenantId: tenantId,
      servicePrincipalId: servicePrincipalId,
      monitorFlowLogs: true
    });

    res.json({
      success: true,
      message: 'Azure subscription onboarded successfully',
      account: onboardResponse.data
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.response?.data || error.message
    });
  }
});
```

---

## Testing

### Test Authentication

```bash
curl -X POST https://api.prismacloud.io/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "YOUR_ACCESS_KEY",
    "password": "YOUR_SECRET_KEY"
  }'
```

### Test Azure Onboarding

```bash
# Get JWT token first
TOKEN=$(curl -s -X POST https://api.prismacloud.io/login \
  -H "Content-Type: application/json" \
  -d '{"username":"KEY","password":"SECRET"}' | jq -r .token)

# Onboard Azure
curl -X POST https://api.prismacloud.io/cloud/azure \
  -H "Content-Type: application/json" \
  -H "x-redlock-auth: $TOKEN" \
  -d '{
    "accountId": "subscription-id",
    "accountType": "account",
    "enabled": true,
    "name": "Azure-Test",
    "clientId": "client-id",
    "key": "client-secret",
    "tenantId": "tenant-id",
    "servicePrincipalId": "sp-object-id"
  }'
```

---

## References

- **Cortex Cloud API Documentation:** https://pan.dev/prisma-cloud/api/cspm/
- **Azure Cloud Accounts API:** https://pan.dev/prisma-cloud/api/cspm/cloud-accounts-azure/
- **Authentication:** https://pan.dev/prisma-cloud/api/cspm/login/
- **API URLs by Region:** https://pan.dev/prisma-cloud/api/cspm/api-urls/

---

**Document Version:** 1.0
**Last Updated:** October 2025
**Project:** azure-cortex-ui
