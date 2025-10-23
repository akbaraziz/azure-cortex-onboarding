# Azure Cortex Cloud Onboarding Web UI

A modern web-based user interface for automating Azure subscription onboarding to Palo Alto Networks Cortex Cloud (formerly Prisma Cloud).

## Features

- 🎨 **Modern React UI** - Clean, intuitive interface for configuration
- ⚡ **Real-time Progress** - Live updates via WebSocket during deployment
- 🔍 **Prerequisites Check** - Automatic validation of required tools
- 📊 **Live Terminal Output** - See Terraform execution in real-time
- ✅ **Deployment Results** - Clear display of credentials and outputs
- 🔐 **Secure** - Handles sensitive credentials properly

## Architecture

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│   React UI      │◄───────►│  Express API    │◄───────►│   Terraform     │
│  (Frontend)     │  HTTP   │   (Backend)     │  Shell  │    Azure CLI    │
│                 │         │                 │         │                 │
│  - Form Input   │         │  - REST API     │         │  - Deploy Infra │
│  - Progress UI  │         │  - WebSocket    │         │  - Create SP    │
│  - Results      │◄───WS───│  - Orchestrator │         │  - Outputs      │
└─────────────────┘         └─────────────────┘         └─────────────────┘
```

## Prerequisites

> **📋 Important:** Run the prerequisites check script before starting:
> ```bash
> ./check-prerequisites.sh
> ```
> This will validate all requirements are met before onboarding.

### System Requirements
- Node.js 18+ and npm
- Azure CLI 2.50+ installed and configured
- Terraform 1.5+ installed
- Active Azure subscription with **Owner** permissions
- Cortex Cloud account with API credentials

### Azure Requirements
- **Owner** role at Management Group or Subscription level
- **Global Administrator** role in Azure AD (Entra ID)
- **Resource Providers Registered:**
  - `Microsoft.Insights` (required for diagnostic settings)
  - `Microsoft.Aadiam` (required for Azure AD diagnostics)

### Cortex Cloud Requirements
- Active Cortex Cloud account
- API Access Key and Secret Key (from Settings → Access Keys)
- Know your Cortex Cloud API URL for your region:
  - US: `https://api.prismacloud.io`
  - EU: `https://api.eu.prismacloud.io`
  - APAC: `https://api.anz.prismacloud.io`
  - Gov: `https://api.gov.prismacloud.io`

**📖 For detailed setup instructions, see [PREREQUISITES.md](./PREREQUISITES.md)**

## Installation

### 1. Clone/Copy the Files

Make sure you have the following structure:
```
azure-cortex-ui/
├── server.js
├── package.json
├── public/
│   └── index.html
└── deployments/ (will be created automatically)
```

### 2. Copy Terraform Files

Copy all Terraform files from your original setup to the parent directory:
```bash
cp /path/to/terraform/files/*.tf /home/claude/
```

Required Terraform files:
- `variables.tf`
- `azure-roles.tf`
- `azure-audit-logs.tf`
- `outputs.tf`

### 3. Install Dependencies

```bash
cd azure-cortex-ui
npm install
```

### 4. Login to Azure

Before starting the application, ensure you're logged into Azure:
```bash
az login
az account set --subscription YOUR_SUBSCRIPTION_ID
```

## Running the Application

### Start the Backend Server

```bash
npm start
```

Or for development with auto-restart:
```bash
npm run dev
```

The server will start on `http://localhost:3001`

### Access the Web UI

Open your browser and navigate to:
```
http://localhost:3001
```

## Usage Guide

### Step 1: Prerequisites Check

The application will automatically check for:
- ✅ Azure CLI installation
- ✅ Terraform installation  
- ✅ Azure login status

All must be green before proceeding.

### Step 2: Fill in Configuration

#### Azure Configuration
- **Subscription ID**: Found in Azure Portal → Subscriptions
- **Tenant ID**: Found in Azure Portal → Azure Active Directory → Overview
- **Application Name**: Name for the service principal (default: CortexCloudApp)

#### Cortex Cloud Configuration
- **API URL**: Select your region:
  - Americas: `https://api.prismacloud.io`
  - Europe: `https://api.eu.prismacloud.io`
  - Asia Pacific: `https://api.anz.prismacloud.io`
  - Singapore: `https://api.sg.prismacloud.io`
  - UK: `https://api.uk.prismacloud.io`
- **Access Key**: Your Cortex Cloud access key
- **Secret Key**: Your Cortex Cloud secret key
- **Account Name**: Display name in Cortex (e.g., Azure-Prod)

#### Feature Configuration
- ☑️ **Create Custom Reader Role**: Enhanced permissions for monitoring
- ☑️ **Enable Flow Logs**: Network traffic monitoring
- ☑️ **Enable Audit Logs**: Event Hub-based log collection
- ☑️ **Enable Azure AD**: Azure Active Directory integration

#### Additional Settings
- **Environment**: prod, dev, staging, or test
- **Azure Region**: Primary region for resources
- **Log Retention**: Days to retain logs (30-730)

### Step 3: Deploy

Click **"Start Onboarding Process"** to begin deployment.

You'll see:
1. Real-time progress updates
2. Live terminal output from Terraform
3. Each deployment step as it executes

### Step 4: Results

Upon completion, you'll receive:
- ✅ Application (Client) ID
- ✅ Application Secret
- ✅ Service Principal Object ID
- ✅ Tenant ID

**IMPORTANT**: Save these credentials securely! You'll need them for Cortex Cloud configuration.

## API Endpoints

### Health Check
```
GET /api/health
```
Returns server status.

### Prerequisites Check
```
GET /api/check-prerequisites
```
Returns status of Azure CLI, Terraform, and Azure login.

### Start Onboarding
```
POST /api/start-onboarding
Content-Type: application/json

{
  "subscriptionId": "...",
  "tenantId": "...",
  "appName": "CortexCloudApp",
  "cortexApiUrl": "https://api.prismacloud.io",
  "cortexAccessKey": "...",
  "cortexSecretKey": "...",
  "azureAccountName": "Azure-Prod",
  "createCustomRole": true,
  "enableFlowLogs": true,
  "enableAuditLogs": true,
  "enableAzureAd": true,
  "environment": "prod",
  "azureRegion": "eastus",
  "logRetentionDays": 30
}
```

Returns deployment ID and WebSocket URL.

### Get Deployment Status
```
GET /api/deployment/:id
```
Returns current deployment status and outputs.

### WebSocket Connection
```
ws://localhost:3001/ws/:deploymentId
```
Receives real-time deployment updates.

## WebSocket Messages

### Step Update
```json
{
  "type": "step",
  "step": "Initializing Terraform..."
}
```

### Output Stream
```json
{
  "type": "output",
  "data": "Terraform output text..."
}
```

### Completion
```json
{
  "type": "complete",
  "outputs": {
    "application_id": { "value": "..." },
    "application_secret": { "value": "..." }
  }
}
```

### Error
```json
{
  "type": "error",
  "error": "Error message..."
}
```

## Deployment Process

The backend orchestrates the following steps:

1. **Configuration** - Creates `terraform.tfvars` file
2. **Azure Setup** - Sets active subscription
3. **Terraform Init** - Initializes Terraform providers
4. **Terraform Validate** - Validates configuration
5. **Terraform Plan** - Creates execution plan
6. **Terraform Apply** - Deploys infrastructure
7. **Output Retrieval** - Extracts deployment outputs

## Troubleshooting

> **📖 For comprehensive troubleshooting, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)**

### Common Issues Quick Reference

| Issue | Quick Fix |
|-------|-----------|
| `InvalidAuthenticationToken` | Run `az logout && az login` and wait 5-10 minutes |
| `AuthorizationFailed` | Ensure you have Owner role + Global Admin access |
| `PrincipalNotFound` | Approve Cortex app in Azure Portal + wait for replication |
| `Resource provider not registered` | Register providers: See [PREREQUISITES.md](./PREREQUISITES.md#required-azure-resource-providers) |
| Feature checkboxes not showing | Hard refresh browser (Ctrl+Shift+R) |
| Deployment hangs | Check WebSocket connection in browser console (F12) |

### Quick Checks

1. **Validate Prerequisites:**
   ```bash
   ./check-prerequisites.sh
   ```

2. **Check Azure Login:**
   ```bash
   az account show
   ```

3. **Verify Resource Providers:**
   ```bash
   az provider show --namespace Microsoft.Insights --query "registrationState"
   az provider show --namespace Microsoft.Aadiam --query "registrationState"
   ```

4. **View Server Logs:**
   - Check the terminal where `npm run dev` is running
   - Look for detailed error messages

### Getting Help

- **Prerequisites Issues:** See [PREREQUISITES.md](./PREREQUISITES.md)
- **Deployment Errors:** See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
- **API Documentation:** See [CORTEX_CLOUD_ONBOARDING_API.md](./CORTEX_CLOUD_ONBOARDING_API.md)
- **Palo Alto Support:** Contact with deployment ID and error messages

## Security Best Practices

1. **Credentials**
   - Never commit credentials to version control
   - Use environment variables for sensitive data
   - Rotate secrets regularly

2. **Network**
   - Run server behind VPN or firewall
   - Use HTTPS in production
   - Implement authentication

3. **Access Control**
   - Limit who can run onboarding
   - Audit deployment activities
   - Review service principal permissions

## Production Deployment

For production use, consider:

1. **HTTPS** - Use SSL/TLS certificates
2. **Authentication** - Add user authentication (OAuth, SAML)
3. **Logging** - Implement comprehensive logging
4. **Monitoring** - Add application monitoring
5. **Database** - Store deployment history
6. **Multi-tenancy** - Support multiple subscriptions
7. **Role-based Access** - Implement RBAC

## File Structure

```
azure-cortex-ui/
├── server.js              # Express backend server
├── package.json           # Node.js dependencies
├── public/
│   └── index.html        # React frontend (single-page app)
├── deployments/          # Working directories for deployments
│   └── [uuid]/          # Each deployment gets unique directory
│       ├── terraform.tfvars
│       ├── *.tf files
│       └── tfplan
└── README.md            # This file
```

## Environment Variables

Optional environment variables:

```bash
# Server port (default: 3001)
export PORT=3001

# Terraform binary location (if not in PATH)
export TERRAFORM_BIN=/usr/local/bin/terraform

# Azure CLI binary location (if not in PATH)
export AZURE_CLI_BIN=/usr/local/bin/az
```

## Support

For issues related to:
- **UI/Backend**: Check server logs and browser console
- **Terraform**: Review `.terraform` directory and state files
- **Azure**: Check Azure Portal activity logs
- **Cortex Cloud**: Contact Palo Alto Networks support

## License

MIT License - Feel free to modify and use as needed.

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Acknowledgments

- Built with React, Express, and WebSockets
- Terraform by HashiCorp
- Azure CLI by Microsoft
- Cortex Cloud by Palo Alto Networks
