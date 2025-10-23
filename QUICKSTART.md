# Quick Start Guide

Get up and running with the Azure Cortex Cloud Onboarding UI in 5 minutes.

## Prerequisites Checklist

Before you begin, ensure you have:

- [ ] Node.js 16+ installed
- [ ] npm installed
- [ ] Azure CLI installed
- [ ] Terraform installed
- [ ] Active Azure subscription
- [ ] Cortex Cloud API credentials
- [ ] Owner permissions on Azure subscription

## Step-by-Step Setup

### 1. Verify Azure Login

```bash
# Login to Azure
az login

# Verify your subscription
az account show

# Set the correct subscription (if needed)
az account set --subscription YOUR_SUBSCRIPTION_ID
```

### 2. Run Setup Script

```bash
cd azure-cortex-ui
chmod +x setup.sh
./setup.sh
```

This will:
- ✅ Check all prerequisites
- ✅ Install npm dependencies
- ✅ Create necessary directories
- ✅ Copy Terraform files

### 3. Start the Server

```bash
npm start
```

You should see:
```
Server running on port 3001
WebSocket server ready
```

### 4. Open the Web UI

Open your browser to: **http://localhost:3001**

### 5. Fill in the Form

#### Required Information

**Azure Details:**
- Subscription ID (from Azure Portal → Subscriptions)
- Tenant ID (from Azure Portal → Azure AD → Overview)

**Cortex Cloud:**
- API URL (select your region from dropdown)
- Access Key
- Secret Key

**Optional Settings:**
- Keep defaults for most settings
- Adjust as needed for your environment

### 6. Start Deployment

1. Click **"Start Onboarding Process"**
2. Watch real-time progress in the terminal output
3. Wait for completion (typically 5-10 minutes)

### 7. Save Your Credentials

When deployment completes, you'll see:
- Application (Client) ID
- Application Secret
- Service Principal Object ID
- Tenant ID

**⚠️ IMPORTANT:** Copy and save these credentials immediately!

## What Gets Created

The onboarding process creates:

1. **Azure AD Application** - For Cortex Cloud authentication
2. **Service Principal** - With appropriate permissions
3. **Custom Reader Role** (optional) - Enhanced monitoring permissions
4. **Event Hub** (optional) - For audit log collection
5. **Log Analytics Workspace** (optional) - For log retention

## Next Steps

After successful deployment:

1. **Verify in Azure Portal**
   - Go to Azure AD → App registrations
   - Find your application (default: CortexCloudApp)
   - Verify it has correct permissions

2. **Configure Cortex Cloud**
   - Login to Cortex Cloud
   - Go to Settings → Cloud Accounts
   - Add new Azure account using your credentials

3. **Test Integration**
   - Wait 5-10 minutes for initial sync
   - Check Cortex Cloud dashboard
   - Verify assets are appearing

## Common Issues

### Prerequisites Not Met

**Error: Azure CLI not found**
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Error: Terraform not found**
```bash
# Install Terraform
brew install terraform  # macOS
# or follow: https://www.terraform.io/downloads
```

**Error: Not logged into Azure**
```bash
az login
```

### Deployment Fails

**Check permissions:**
```bash
# Verify you have Owner role
az role assignment list --assignee YOUR_EMAIL --subscription YOUR_SUBSCRIPTION
```

**Check Terraform files:**
```bash
# Ensure all required files are present
ls -la
# Should show: variables.tf, azure-roles.tf, azure-audit-logs.tf, outputs.tf
```

**Review logs:**
- Check the terminal output in the web UI
- Look for specific error messages
- Note which step failed

### Can't Access Web UI

**Check if server is running:**
```bash
curl http://localhost:3001/api/health
```

**Check port availability:**
```bash
lsof -i :3001
```

**Try different port:**
```bash
PORT=3002 npm start
```

## Getting Help

If you encounter issues:

1. Check the terminal output for error messages
2. Review the deployment logs in the web UI
3. Verify all prerequisites are met
4. Check Azure Portal activity logs
5. Review Terraform state files in deployments/[uuid]/

## Tips for Success

1. **Use a dedicated subscription** for testing
2. **Start with default settings** - customize later
3. **Save credentials immediately** after deployment
4. **Review created resources** in Azure Portal
5. **Test with read-only operations first** in Cortex

## Security Notes

⚠️ **Never commit credentials** to version control
⚠️ **Rotate secrets regularly** 
⚠️ **Use RBAC** to limit who can run onboarding
⚠️ **Review service principal permissions** after creation
⚠️ **Enable MFA** on admin accounts

## Architecture Overview

```
Browser (React UI)
       ↓
Express Server (Node.js)
       ↓
Terraform + Azure CLI
       ↓
Azure Subscription
       ↓
Cortex Cloud API
```

## Deployment Time

Typical deployment takes:
- Terraform init: 30-60 seconds
- Terraform plan: 30-60 seconds  
- Terraform apply: 3-5 minutes
- **Total: 5-10 minutes**

## What to Expect

During deployment, you'll see:
1. ✅ Creating configuration files...
2. ✅ Setting Azure subscription...
3. ✅ Initializing Terraform...
4. ✅ Validating Terraform configuration...
5. ✅ Planning Terraform deployment...
6. ✅ Applying Terraform configuration...
7. ✅ Retrieving deployment outputs...
8. ✅ **Complete!**

## Resources Created

Depending on your configuration:

| Resource Type | Purpose | Cost Impact |
|---------------|---------|-------------|
| App Registration | Authentication | Free |
| Service Principal | API Access | Free |
| Custom Role | Permissions | Free |
| Event Hub | Log Streaming | ~$0.015/hr |
| Log Analytics | Log Storage | ~$2.76/GB |
| Storage Account | Audit Logs | ~$0.02/GB |

## Cleanup

To remove resources:

```bash
cd deployments/[your-deployment-id]
terraform destroy
```

Or manually in Azure Portal:
1. Delete the App Registration
2. Delete Event Hub (if created)
3. Delete Log Analytics Workspace (if created)
4. Delete Storage Account (if created)

---

**Ready to get started?** Run `./setup.sh` and follow the prompts!
