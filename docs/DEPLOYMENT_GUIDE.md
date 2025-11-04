# Azure Cortex Cloud Onboarding - Web UI Deployment Guide

## 📋 Overview

This web application provides a user-friendly interface for onboarding Azure subscriptions to Palo Alto Networks Cortex Cloud. It automates the entire process including:

- ✅ Azure AD Application registration
- ✅ Service Principal creation with appropriate permissions
- ✅ Custom role definitions for enhanced monitoring
- ✅ Event Hub setup for audit logs
- ✅ Integration with Cortex Cloud API
- ✅ Real-time deployment progress tracking

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        Browser                                │
│  ┌────────────────────────────────────────────────────┐      │
│  │          React Frontend (Single Page App)          │      │
│  │  • Configuration Form                              │      │
│  │  • Real-time Progress Display                      │      │
│  │  • Deployment Results                              │      │
│  └────────────┬───────────────────────────┬───────────┘      │
└───────────────┼───────────────────────────┼──────────────────┘
                │ HTTP                      │ WebSocket
                ↓                           ↓
┌──────────────────────────────────────────────────────────────┐
│                    Express Backend Server                     │
│  ┌────────────────────────────────────────────────────┐      │
│  │  • REST API Endpoints                              │      │
│  │  • WebSocket Server (Real-time Updates)           │      │
│  │  • Deployment Orchestrator                         │      │
│  │  • File Management                                 │      │
│  └────────────┬───────────────────────────────────────┘      │
└───────────────┼──────────────────────────────────────────────┘
                │ Shell Commands
                ↓
┌──────────────────────────────────────────────────────────────┐
│              Terraform & Azure CLI                            │
│  ┌────────────────────────────────────────────────────┐      │
│  │  • Terraform Execution                             │      │
│  │  • Azure Resource Provisioning                     │      │
│  │  • State Management                                │      │
│  └────────────┬───────────────────────────────────────┘      │
└───────────────┼──────────────────────────────────────────────┘
                │ Azure API
                ↓
┌──────────────────────────────────────────────────────────────┐
│                    Azure Subscription                         │
│  • App Registration                                           │
│  • Service Principal                                          │
│  • Custom Roles                                               │
│  • Event Hub (optional)                                       │
│  • Log Analytics (optional)                                   │
└──────────────────────────────────────────────────────────────┘
```

## 📦 What's Included

```
azure-cortex-ui/
├── server.js                  # Express backend server
├── package.json               # Node.js dependencies
├── setup.sh                   # Automated setup script
├── README.md                  # Comprehensive documentation
├── QUICKSTART.md             # Quick start guide
├── .gitignore                # Git ignore rules
├── public/
│   └── index.html            # React frontend (single-page app)
├── provider.tf               # Terraform provider configuration
├── variables.tf              # Terraform input variables
├── azure-roles.tf            # Azure role definitions
├── azure-audit-logs.tf       # Audit log configuration
└── outputs.tf                # Terraform outputs
```

## 🚀 Quick Start

### 1. Prerequisites

Install required tools:

```bash
# Node.js (v16+)
node --version

# npm
npm --version

# Azure CLI
az --version

# Terraform
terraform --version

# Login to Azure
az login
az account set --subscription YOUR_SUBSCRIPTION_ID
```

### 2. Setup

```bash
# Navigate to the directory
cd azure-cortex-ui

# Run setup script
chmod +x setup.sh
./setup.sh

# Or manually install
npm install
```

### 3. Start Server

```bash
npm start
```

Server starts on: `http://localhost:3001`

### 4. Access Web UI

Open browser: **http://localhost:3001**

### 5. Complete Form & Deploy

Follow the web interface to:
1. ✅ Verify prerequisites
2. ✅ Enter configuration
3. ✅ Start deployment
4. ✅ Receive credentials

## 🎯 Features

### Prerequisites Validation
- Automatic checking of Azure CLI installation
- Terraform installation verification
- Azure login status validation
- Visual indicators for each requirement

### Interactive Configuration Form
- **Azure Settings**: Subscription ID, Tenant ID, App Name
- **Cortex Cloud**: API URL (region selector), Access Key, Secret Key
- **Features**: Toggle switches for optional components
- **Advanced Settings**: Environment, Region, Log Retention
- **Field Validation**: Real-time input validation
- **Helpful Tooltips**: Guidance for each field

### Real-time Deployment Tracking
- Live progress updates via WebSocket
- Terminal-style output display
- Step-by-step execution visibility
- Scroll-to-bottom for latest output
- Color-coded status indicators

### Results Display
- Clear presentation of deployment outputs
- Copy-friendly credential display
- Secure handling of sensitive data
- Download deployment report option
- Next steps guidance

## 🔧 Configuration Options

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| Subscription ID | Azure subscription identifier | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| Tenant ID | Azure AD tenant identifier | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| Cortex API URL | Region-specific API endpoint | `https://api.prismacloud.io` |
| Cortex Access Key | Cortex Cloud access key | Your access key |
| Cortex Secret Key | Cortex Cloud secret key | Your secret key |

### Optional Fields

| Field | Default | Description |
|-------|---------|-------------|
| App Name | CortexCloudApp | Azure AD Application name |
| Account Name | Azure-Prod | Display name in Cortex |
| Environment | prod | Environment tag (prod/dev/staging) |
| Azure Region | eastus | Primary Azure region |
| Log Retention | 30 days | Log retention period |

### Feature Toggles

| Feature | Default | Purpose |
|---------|---------|---------|
| Custom Reader Role | ✅ Enabled | Enhanced monitoring permissions |
| Flow Logs | ✅ Enabled | Network traffic monitoring |
| Audit Logs | ✅ Enabled | Event Hub-based log collection |
| Azure AD | ✅ Enabled | Azure Active Directory integration |

## 📊 API Reference

### Health Check
```http
GET /api/health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-10-22T00:00:00.000Z"
}
```

### Prerequisites Check
```http
GET /api/check-prerequisites
```

**Response:**
```json
{
  "azureCli": true,
  "terraform": true,
  "azureLogin": true
}
```

### Start Onboarding
```http
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

**Response:**
```json
{
  "deploymentId": "uuid",
  "message": "Deployment started",
  "wsUrl": "/ws/uuid"
}
```

### Get Deployment Status
```http
GET /api/deployment/:id
```

**Response:**
```json
{
  "deploymentId": "uuid",
  "status": "completed",
  "startTime": "2025-10-22T00:00:00.000Z",
  "endTime": "2025-10-22T00:05:00.000Z",
  "output": {
    "application_id": { "value": "..." },
    "application_secret": { "value": "..." },
    "service_principal_object_id": { "value": "..." },
    "tenant_id": { "value": "..." }
  }
}
```

### WebSocket Messages

**Step Update:**
```json
{
  "type": "step",
  "step": "Initializing Terraform..."
}
```

**Output Stream:**
```json
{
  "type": "output",
  "data": "Terraform output..."
}
```

**Completion:**
```json
{
  "type": "complete",
  "outputs": { ... }
}
```

**Error:**
```json
{
  "type": "error",
  "error": "Error message"
}
```

## 🔒 Security Considerations

### Credential Handling
- ✅ Sensitive data marked as sensitive in Terraform
- ✅ No credentials stored in browser localStorage
- ✅ HTTPS recommended for production
- ✅ Secrets not logged to console
- ✅ Deployment directories isolated

### Access Control
- 🔒 Add authentication for production use
- 🔒 Implement role-based access control
- 🔒 Use Azure AD for SSO
- 🔒 Audit all deployment activities
- 🔒 Restrict server network access

### Best Practices
1. Run server behind VPN or firewall
2. Use environment variables for config
3. Enable Azure AD authentication
4. Implement rate limiting
5. Add request logging
6. Regular security updates
7. Rotate credentials regularly

## 🐛 Troubleshooting

### Prerequisites Issues

**Azure CLI Not Found:**
```bash
# Install Azure CLI (Linux)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Azure CLI (macOS)
brew install azure-cli
```

**Terraform Not Found:**
```bash
# Install Terraform (macOS)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Install Terraform (Linux)
# Visit: https://www.terraform.io/downloads
```

**Not Logged Into Azure:**
```bash
az login
az account show
```

### Deployment Failures

**Permission Denied:**
- Verify Owner role on subscription
- Check Azure AD permissions
- Ensure service principal creation rights

**Terraform Errors:**
- Check Terraform version compatibility
- Verify all required files present
- Review terraform.tfvars contents
- Check Azure region availability

**Network Issues:**
- Verify internet connectivity
- Check firewall rules
- Confirm proxy settings
- Test Azure CLI connectivity

### Application Issues

**Server Won't Start:**
```bash
# Check if port is in use
lsof -i :3001

# Try different port
PORT=3002 npm start

# Check Node.js version
node --version  # Should be 16+
```

**WebSocket Connection Failed:**
- Check server is running
- Verify no proxy blocking WebSocket
- Check browser console for errors
- Try clearing browser cache

**Form Validation Errors:**
- Ensure all required fields filled
- Check format of Subscription/Tenant IDs
- Verify Cortex Cloud credentials
- Test API URL accessibility

## 📈 Production Deployment

### Environment Setup

```bash
# Set production environment variables
export NODE_ENV=production
export PORT=443
export TERRAFORM_BIN=/usr/local/bin/terraform
export AZURE_CLI_BIN=/usr/local/bin/az

# Use process manager
npm install -g pm2
pm2 start server.js --name azure-cortex-ui
pm2 save
pm2 startup
```

### HTTPS Configuration

```javascript
// Add to server.js
const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('path/to/private.key'),
  cert: fs.readFileSync('path/to/certificate.crt')
};

https.createServer(options, app).listen(443);
```

### Reverse Proxy (Nginx)

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    
    location /ws/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
    }
}
```

### Authentication Integration

Consider adding:
- Azure AD OAuth integration
- SAML 2.0 authentication
- Multi-factor authentication
- Role-based access control
- Audit logging

## 📝 Deployment Checklist

### Pre-Deployment
- [ ] Azure CLI installed
- [ ] Terraform installed
- [ ] Node.js 16+ installed
- [ ] Logged into Azure
- [ ] Owner permissions verified
- [ ] Cortex Cloud credentials ready
- [ ] Subscription ID obtained
- [ ] Tenant ID obtained

### During Deployment
- [ ] Server started successfully
- [ ] Web UI accessible
- [ ] Prerequisites all green
- [ ] Form filled completely
- [ ] Deployment initiated
- [ ] Progress visible
- [ ] No errors in terminal

### Post-Deployment
- [ ] Credentials saved securely
- [ ] App registration verified in Azure
- [ ] Service principal has correct roles
- [ ] Cortex Cloud configured
- [ ] Initial sync completed
- [ ] Assets appearing in Cortex
- [ ] Documentation updated
- [ ] Team notified

## 🆘 Support

### Getting Help

1. **Check Logs**: Review terminal output in web UI
2. **Azure Portal**: Check activity logs
3. **Terraform State**: Examine state files
4. **Server Logs**: Check Node.js console output
5. **Network**: Verify connectivity

### Common Solutions

**Deployment Timeout:**
- Increase timeout values
- Check network latency
- Verify Azure region responsiveness

**State Lock:**
```bash
# If Terraform state is locked
cd deployments/[deployment-id]
terraform force-unlock [lock-id]
```

**Cleanup Failed Deployment:**
```bash
cd deployments/[deployment-id]
terraform destroy
```

## 📚 Additional Resources

- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Cortex Cloud Documentation](https://docs.paloaltonetworks.com/prisma/prisma-cloud)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [Express.js Documentation](https://expressjs.com/)
- [WebSocket Protocol](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API)

## 🤝 Contributing

Contributions welcome! Areas for improvement:
- Authentication implementation
- Multi-subscription support
- Deployment history database
- Advanced monitoring dashboard
- Email notifications
- Slack integration
- Backup and restore
- Multi-region deployment

## 📄 License

MIT License - Free to use and modify

---

**Need help?** Open an issue or consult the documentation above.
