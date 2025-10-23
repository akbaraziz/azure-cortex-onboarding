# Cortex Cloud / Prisma Cloud API Documentation

**Source:** https://pan.dev/prisma-cloud/api/cspm/
**Documentation Date:** October 2025
**Project:** azure-cortex-ui

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [API Base URLs](#api-base-urls)
4. [Common Headers](#common-headers)
5. [Rate Limits](#rate-limits)
6. [Azure Cloud Account Onboarding](#azure-cloud-account-onboarding)
7. [Error Handling](#error-handling)
8. [Code Examples](#code-examples)

---

## Overview

**Cortex Cloud** (also known as **Prisma Cloud**) provides a comprehensive Cloud Security Posture Management (CSPM) platform with RESTful APIs for:

- Cloud account onboarding (AWS, Azure, GCP, OCI, Alibaba)
- Alert management and policy enforcement
- Compliance posture monitoring
- Asset inventory and discovery
- Data security and IAM management
- Vulnerability scanning

### Key Capabilities

- **Cloud Accounts Management**: Onboard and manage cloud subscriptions/accounts
- **Alert Rules**: Configure automated alert notifications
- **Policy Management**: Define and enforce security policies
- **Compliance Standards**: Track compliance with industry frameworks
- **Resource Explorer**: Query and analyze cloud resources
- **IAM Security**: Analyze IAM permissions and access
- **Data Security**: Scan and classify sensitive data

---

## Authentication

### Prerequisites

1. **Access Key**: You must have a Prisma Cloud API access key
   - Access Key ID (username)
   - Secret Key (password)
2. **API URL**: Know your region's API endpoint
3. **Permissions**: Access keys inherit permissions from the creating user's permission group

### Authentication Flow

```
1. POST /login → Obtain JWT Token
2. Include JWT in all subsequent API requests via x-redlock-auth header
3. Refresh JWT before 10-minute expiration using GET /auth_token/extend
```

### Step 1: Login and Obtain JWT

**Endpoint:** `POST /login`

**Request Body:**
```json
{
  "username": "YOUR_ACCESS_KEY_ID",
  "password": "YOUR_SECRET_KEY"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "message": "login_successful",
  "customerNames": [...],
  "roles": [...]
}
```

**cURL Example:**
```bash
curl -X POST https://api.prismacloud.io/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "ACCESS_KEY_ID",
    "password": "SECRET_KEY"
  }'
```

### Step 2: Use JWT in API Requests

**Required Header:**
```
x-redlock-auth: YOUR_JWT_TOKEN
```

**Example Request:**
```bash
curl -X GET https://api.prismacloud.io/cloud/name \
  -H "x-redlock-auth: YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

### Step 3: Refresh JWT Token

**Endpoint:** `GET /auth_token/extend`

**Request:**
```bash
curl -X GET https://api.prismacloud.io/auth_token/extend \
  -H "x-redlock-auth: YOUR_CURRENT_JWT_TOKEN"
```

**Response:**
```json
{
  "token": "NEW_JWT_TOKEN",
  "expiresOn": 1698765432000
}
```

### Important Notes

- JWT tokens are valid for **10 minutes**
- Expired tokens return **HTTP 401 (Unauthorized)**
- Access keys maintain the same permissions as the user who created them
- Store secrets securely (never hardcode in source code)

---

## API Base URLs

The Prisma Cloud API URL varies by region. Use the URL matching your tenant deployment:

| Region | API Base URL | Admin Console URL |
|--------|--------------|-------------------|
| **US (Americas)** | `https://api.prismacloud.io` | `https://app.prismacloud.io` |
| **Europe** | `https://api.eu.prismacloud.io` | `https://app.eu.prismacloud.io` |
| **Asia Pacific (ANZ)** | `https://api.anz.prismacloud.io` | `https://app.anz.prismacloud.io` |
| **Singapore** | `https://api.sg.prismacloud.io` | `https://app.sg.prismacloud.io` |
| **United Kingdom** | `https://api.uk.prismacloud.io` | `https://app.uk.prismacloud.io` |
| **Canada** | `https://api.ca.prismacloud.io` | `https://app.ca.prismacloud.io` |
| **Japan** | `https://api.jp.prismacloud.io` | `https://app.jp.prismacloud.io` |
| **India** | `https://api.ind.prismacloud.io` | `https://app.ind.prismacloud.io` |

**How to determine your region:**
- Check your order fulfillment email
- Look at the URL when you log into the Prisma Cloud Admin Console
- If your console URL is `https://app.sg.prismacloud.io`, your API URL is `https://api.sg.prismacloud.io`

---

## Common Headers

### Required Headers

```http
x-redlock-auth: YOUR_JWT_TOKEN
Content-Type: application/json
```

### Optional Headers

```http
Accept: application/json
User-Agent: YourApplicationName/1.0
```

---

## Rate Limits

Prisma Cloud implements API rate limiting to ensure system stability:

- **Rate Limit:** Varies by endpoint and subscription tier
- **Throttling:** Requests exceeding limits return HTTP 429 (Too Many Requests)
- **Retry Strategy:** Use exponential backoff with jitter
- **Best Practices:**
  - Cache responses when possible
  - Batch operations where supported
  - Implement retry logic with exponential backoff

**Example Rate Limit Response:**
```json
{
  "statusCode": 429,
  "message": "Rate limit exceeded. Please retry after 60 seconds."
}
```

---

## Azure Cloud Account Onboarding

### Overview

Onboard Azure subscriptions to Prisma Cloud for continuous security monitoring, compliance tracking, and threat detection.

### Prerequisites

- Azure subscription with Owner or User Access Administrator role
- Azure AD permissions to create service principals
- Prisma Cloud API access key

### Onboarding Process

#### Step 1: Create Azure Service Principal

Create an Azure Active Directory application and service principal:

```bash
az ad sp create-for-rbac --name "CortexCloudApp" \
  --role "Reader" \
  --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

**Output:**
```json
{
  "appId": "12345678-1234-1234-1234-123456789abc",
  "displayName": "CortexCloudApp",
  "password": "your-client-secret",
  "tenant": "your-tenant-id"
}
```

#### Step 2: Assign Custom Role (Optional but Recommended)

For enhanced monitoring, create a custom reader role with additional permissions:

```json
{
  "Name": "Prisma Cloud Reader",
  "Description": "Custom role for Prisma Cloud monitoring",
  "Actions": [
    "*/read",
    "Microsoft.Network/networkWatchers/queryFlowLogStatus/action",
    "Microsoft.Compute/virtualMachines/extensions/read"
  ],
  "AssignableScopes": [
    "/subscriptions/YOUR_SUBSCRIPTION_ID"
  ]
}
```

#### Step 3: Add Azure Account via API

**Endpoint:** `POST /cloud/azure`

**Request Body:**
```json
{
  "accountId": "YOUR_SUBSCRIPTION_ID",
  "accountType": "account",
  "enabled": true,
  "groupIds": [],
  "name": "Azure-Production",
  "clientId": "YOUR_APP_ID",
  "key": "YOUR_CLIENT_SECRET",
  "monitorFlowLogs": true,
  "tenantId": "YOUR_TENANT_ID",
  "servicePrincipalId": "YOUR_SERVICE_PRINCIPAL_OBJECT_ID",
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

**cURL Example:**
```bash
curl -X POST https://api.prismacloud.io/cloud/azure \
  -H "x-redlock-auth: YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "accountId": "YOUR_SUBSCRIPTION_ID",
    "accountType": "account",
    "enabled": true,
    "groupIds": [],
    "name": "Azure-Production",
    "clientId": "YOUR_APP_ID",
    "key": "YOUR_CLIENT_SECRET",
    "monitorFlowLogs": true,
    "tenantId": "YOUR_TENANT_ID",
    "servicePrincipalId": "YOUR_SERVICE_PRINCIPAL_OBJECT_ID"
  }'
```

**Response:**
```json
{
  "accountId": "YOUR_SUBSCRIPTION_ID",
  "cloudType": "azure",
  "enabled": true,
  "name": "Azure-Production",
  "status": "onboarded"
}
```

### Features Configuration

| Feature | Description | Required Permissions |
|---------|-------------|---------------------|
| **Cloud Visibility Compliance and Governance** | Basic cloud resource monitoring | Reader |
| **Agentless Scanning** | Snapshot-based vulnerability scanning | Disk access permissions |
| **Serverless Function Scanning** | Scan Azure Functions for vulnerabilities | Function read access |
| **Remediation** | Auto-remediate security issues | Contributor (on specific resources) |
| **Monitor Flow Logs** | Network traffic analysis | Network Watcher access |

---

## Error Handling

### Common HTTP Status Codes

| Status Code | Meaning | Description |
|-------------|---------|-------------|
| **200** | OK | Request successful |
| **201** | Created | Resource created successfully |
| **400** | Bad Request | Invalid request parameters |
| **401** | Unauthorized | Invalid or expired JWT token |
| **403** | Forbidden | Insufficient permissions |
| **404** | Not Found | Resource not found |
| **429** | Too Many Requests | Rate limit exceeded |
| **500** | Internal Server Error | Server-side error |
| **503** | Service Unavailable | Service temporarily unavailable |

### Error Response Format

```json
{
  "statusCode": 400,
  "message": "Invalid subscription ID format",
  "details": "The subscription ID must be a valid UUID"
}
```

### Retry Strategy

**Exponential Backoff Example:**

```javascript
async function callApiWithRetry(apiFunction, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await apiFunction();
    } catch (error) {
      if (error.statusCode === 429 || error.statusCode >= 500) {
        const delay = Math.pow(2, i) * 1000 + Math.random() * 1000;
        console.log(`Retry ${i + 1}/${maxRetries} after ${delay}ms`);
        await new Promise(resolve => setTimeout(resolve, delay));
      } else {
        throw error; // Don't retry client errors (4xx except 429)
      }
    }
  }
  throw new Error('Max retries exceeded');
}
```

---

## Code Examples

### Node.js Example: Complete Authentication Flow

```javascript
const axios = require('axios');

const PRISMA_API_URL = 'https://api.prismacloud.io';
const ACCESS_KEY_ID = process.env.PRISMA_ACCESS_KEY_ID;
const SECRET_KEY = process.env.PRISMA_SECRET_KEY;

class PrismaCloudClient {
  constructor(apiUrl, accessKeyId, secretKey) {
    this.apiUrl = apiUrl;
    this.accessKeyId = accessKeyId;
    this.secretKey = secretKey;
    this.token = null;
    this.tokenExpiry = null;
  }

  async login() {
    const response = await axios.post(`${this.apiUrl}/login`, {
      username: this.accessKeyId,
      password: this.secretKey
    });

    this.token = response.data.token;
    this.tokenExpiry = Date.now() + (9 * 60 * 1000); // 9 minutes
    console.log('✅ Successfully authenticated with Prisma Cloud');
    return this.token;
  }

  async refreshToken() {
    const response = await axios.get(`${this.apiUrl}/auth_token/extend`, {
      headers: { 'x-redlock-auth': this.token }
    });

    this.token = response.data.token;
    this.tokenExpiry = Date.now() + (9 * 60 * 1000);
    console.log('🔄 Token refreshed successfully');
    return this.token;
  }

  async ensureValidToken() {
    if (!this.token || Date.now() >= this.tokenExpiry) {
      if (this.token) {
        await this.refreshToken();
      } else {
        await this.login();
      }
    }
  }

  async request(method, endpoint, data = null) {
    await this.ensureValidToken();

    const config = {
      method,
      url: `${this.apiUrl}${endpoint}`,
      headers: {
        'x-redlock-auth': this.token,
        'Content-Type': 'application/json'
      }
    };

    if (data) {
      config.data = data;
    }

    try {
      const response = await axios(config);
      return response.data;
    } catch (error) {
      console.error('API Error:', error.response?.data || error.message);
      throw error;
    }
  }

  // Azure account onboarding
  async onboardAzureAccount(azureConfig) {
    return this.request('POST', '/cloud/azure', azureConfig);
  }

  // List all cloud accounts
  async listCloudAccounts() {
    return this.request('GET', '/cloud');
  }

  // Get account status
  async getAccountStatus(accountId) {
    return this.request('GET', `/cloud/${accountId}/status`);
  }
}

// Usage
async function main() {
  const client = new PrismaCloudClient(
    PRISMA_API_URL,
    ACCESS_KEY_ID,
    SECRET_KEY
  );

  // Login
  await client.login();

  // Onboard Azure subscription
  const azureConfig = {
    accountId: 'YOUR_SUBSCRIPTION_ID',
    accountType: 'account',
    enabled: true,
    name: 'Azure-Production',
    clientId: 'YOUR_APP_ID',
    key: 'YOUR_CLIENT_SECRET',
    tenantId: 'YOUR_TENANT_ID',
    servicePrincipalId: 'YOUR_SP_OBJECT_ID',
    monitorFlowLogs: true
  };

  const result = await client.onboardAzureAccount(azureConfig);
  console.log('✅ Azure account onboarded:', result);

  // List all accounts
  const accounts = await client.listCloudAccounts();
  console.log(`📊 Total cloud accounts: ${accounts.length}`);
}

main().catch(console.error);
```

### Python Example: Azure Onboarding

```python
import requests
import time
from datetime import datetime, timedelta

class PrismaCloudClient:
    def __init__(self, api_url, access_key_id, secret_key):
        self.api_url = api_url
        self.access_key_id = access_key_id
        self.secret_key = secret_key
        self.token = None
        self.token_expiry = None

    def login(self):
        """Authenticate and obtain JWT token"""
        response = requests.post(
            f"{self.api_url}/login",
            json={
                "username": self.access_key_id,
                "password": self.secret_key
            }
        )
        response.raise_for_status()

        self.token = response.json()["token"]
        self.token_expiry = datetime.now() + timedelta(minutes=9)
        print("✅ Successfully authenticated with Prisma Cloud")
        return self.token

    def refresh_token(self):
        """Refresh the JWT token"""
        response = requests.get(
            f"{self.api_url}/auth_token/extend",
            headers={"x-redlock-auth": self.token}
        )
        response.raise_for_status()

        self.token = response.json()["token"]
        self.token_expiry = datetime.now() + timedelta(minutes=9)
        print("🔄 Token refreshed successfully")
        return self.token

    def ensure_valid_token(self):
        """Ensure token is valid, refresh if needed"""
        if not self.token or datetime.now() >= self.token_expiry:
            if self.token:
                self.refresh_token()
            else:
                self.login()

    def request(self, method, endpoint, json_data=None):
        """Make authenticated API request"""
        self.ensure_valid_token()

        headers = {
            "x-redlock-auth": self.token,
            "Content-Type": "application/json"
        }

        response = requests.request(
            method,
            f"{self.api_url}{endpoint}",
            headers=headers,
            json=json_data
        )
        response.raise_for_status()
        return response.json()

    def onboard_azure_account(self, azure_config):
        """Onboard Azure subscription to Prisma Cloud"""
        return self.request("POST", "/cloud/azure", azure_config)

# Usage
if __name__ == "__main__":
    client = PrismaCloudClient(
        api_url="https://api.prismacloud.io",
        access_key_id="YOUR_ACCESS_KEY_ID",
        secret_key="YOUR_SECRET_KEY"
    )

    client.login()

    # Onboard Azure
    azure_config = {
        "accountId": "YOUR_SUBSCRIPTION_ID",
        "accountType": "account",
        "enabled": True,
        "name": "Azure-Production",
        "clientId": "YOUR_APP_ID",
        "key": "YOUR_CLIENT_SECRET",
        "tenantId": "YOUR_TENANT_ID",
        "servicePrincipalId": "YOUR_SP_OBJECT_ID",
        "monitorFlowLogs": True
    }

    result = client.onboard_azure_account(azure_config)
    print(f"✅ Azure account onboarded: {result}")
```

---

## API Reference Links

- **Main Documentation:** https://pan.dev/prisma-cloud/api/
- **Cloud Security API:** https://pan.dev/prisma-cloud/api/cspm/
- **Login/Auth:** https://pan.dev/prisma-cloud/api/cspm/login/
- **API URLs:** https://pan.dev/prisma-cloud/api/cspm/api-urls/
- **Azure Onboarding:** https://pan.dev/prisma-cloud/api/cspm/cloud-accounts-azure/
- **Rate Limits:** https://pan.dev/prisma-cloud/api/cspm/rate-limits/
- **Error Responses:** https://pan.dev/prisma-cloud/api/cspm/api-errors/

---

## Summary

The Cortex Cloud / Prisma Cloud API provides comprehensive access to cloud security capabilities:

1. **Authentication:** JWT-based with 10-minute token expiration
2. **Regional API Endpoints:** Multiple regions for global deployment
3. **Azure Onboarding:** Service principal-based authentication
4. **Rate Limiting:** Exponential backoff recommended
5. **Error Handling:** Standard HTTP status codes with detailed messages

For the **azure-cortex-ui** project, this API enables automated Azure subscription onboarding with Terraform and provides real-time status updates during deployment.

---

**Generated:** October 2025
**For:** azure-cortex-ui project
**By:** Claude Code Assistant
