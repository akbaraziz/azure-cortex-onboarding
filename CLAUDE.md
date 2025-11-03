# CLAUDE.md - Azure Cortex Cloud Onboarding Project

AI Assistant guidelines for working on the Azure Cortex Cloud onboarding automation tool.

---

## 🎯 Project Overview

**Project Name:** Azure Cortex Cloud Onboarding Web UI
**Purpose:** Automate Azure subscription onboarding to Palo Alto Networks Cortex Cloud (formerly Prisma Cloud)
**Tech Stack:** Node.js + Express.js + Terraform + Azure CLI
**Version:** 1.0.3

### What This Tool Does

- Provides a modern web-based UI for configuring Azure → Cortex Cloud onboarding
- Orchestrates Terraform deployment via Express.js backend
- Real-time progress updates via WebSocket
- Creates Service Principals, RBAC roles, Event Hubs, and diagnostic settings
- Configures Cortex Cloud features (CSPM, agentless scanning, etc.)

---

## 🚨 Critical Guidelines (Non-Negotiable)

### 1. **Never Remove Security Features Without Approval**
   - All Terraform security configurations are production-tested
   - RLS policies, RBAC roles, and diagnostic settings are required
   - Always ask before removing security-related code

### 2. **Follow Azure Best Practices**
   - Use service principals with least-privilege access
   - Implement retry logic for Azure AD replication (2-10 minute delays)
   - Always validate resource provider registration before deployment
   - Handle authentication token expiration gracefully

### 3. **Maintain Terraform State Integrity**
   - Never modify `*.tfstate` files directly
   - Always use `terraform plan` before `terraform apply`
   - Preserve provider version constraints
   - Keep sensitive outputs marked as `sensitive = true`

### 4. **Error Handling is Critical**
   - All Azure API calls must have retry logic
   - Handle `InvalidAuthenticationToken`, `AuthorizationFailed`, and `PrincipalNotFound` errors
   - Wait for Azure AD propagation (30s-10min depending on operation)
   - Provide clear user-facing error messages

---

## 🔧 Development Tools & MCP Servers

### Context7 MCP Server (Documentation Lookup)

**Status:** ✅ **ENABLED** - Configured in `.claude/settings.local.json`

**Purpose:** Automatic library documentation and API reference lookup

**Usage:**
Context7 automatically provides documentation when you mention libraries or ask about APIs. No special syntax required.

**Relevant for This Project:**
- **Azure CLI**: Command syntax, parameters, examples
- **Terraform**: azurerm/azuread provider documentation
- **Node.js**: express, ws, uuid package documentation
- **Best Practices**: Up-to-date recommendations

**Manual Queries:**
```bash
"Show me azurerm_eventhub resource documentation"
"How do I use az provider register?"
"Get Express.js WebSocket setup guide"
```

**Full Documentation:** See `.claude/CONTEXT7_SETUP.md`

---

## 📋 Project Architecture

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

### Key Components

1. **Frontend** (`public/index.html`): Single-page React app
2. **Backend** (`server.js`): Express.js + WebSocket server
3. **Terraform Modules**:
   - `main.tf` - Core Azure AD/Service Principal resources
   - `azure-roles.tf` - Custom RBAC roles
   - `azure-audit-logs.tf` - Event Hub + diagnostic settings
   - `variables.tf` - Input variables
   - `outputs.tf` - Deployment outputs

4. **Validation Scripts**:
   - `check-prerequisites.sh` - System prerequisites
   - `scripts/validate-permissions.sh` - Azure permissions

---

## 🔐 Security-First Development

### Critical Security Rules

1. **Secrets Management**:
   - Never log secrets or tokens
   - Mark Terraform outputs as `sensitive = true`
   - Use environment variables for credentials
   - Rotate Service Principal passwords (configured: 365 days)

2. **Authentication & Authorization**:
   - **Required Azure Roles**:
     - Global Administrator (Azure AD)
     - Owner (Subscription or Management Group)
   - Validate permissions before deployment
   - Handle token expiration (default: 1 hour)

3. **Resource Provider Registration**:
   - **MUST** be Registered: `Microsoft.Insights`, `Microsoft.Aadiam`
   - Check status in prerequisites validation
   - Auto-register if missing (requires Owner role)

4. **Event Hub Configuration**:
   - **Default partition count**: 4 (Standard tier limit: 32)
   - Use `event_hub_partition_count` variable
   - Premium/Dedicated tiers support higher partition counts

---

## 🛠️ Development Commands

### Prerequisites Validation

```bash
# Run before any deployment
./check-prerequisites.sh

# Validate Azure permissions
./scripts/validate-permissions.sh
```

### Local Development

```bash
# Install dependencies
npm install

# Start dev server (auto-restart)
npm run dev

# Production build
npm run build

# Version bump
npm run version:bump
```

### Terraform Operations

```bash
# Initialize
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -out=tfplan

# Apply deployment
terraform apply tfplan

# Check outputs
terraform output -json
```

### Azure CLI Common Tasks

```bash
# Check login status
az account show

# Set subscription
az account set --subscription <subscription-id>

# Verify resource providers
az provider show --namespace Microsoft.Insights --query "registrationState"
az provider show --namespace Microsoft.Aadiam --query "registrationState"

# Get current user ID
az ad signed-in-user show --query id -o tsv

# List role assignments
az role assignment list --assignee <user-id>
```

---

## 📚 Common Errors & Solutions

### Error 1: InvalidAuthenticationToken

**Cause:** Expired/invalid Azure token
**Solution:**
```bash
az account clear
az login
# Wait 2-10 minutes for propagation
```

### Error 2: AuthorizationFailed

**Cause:** Missing Owner role at management group level
**Solution:**
```bash
az role assignment create \
  --assignee <user-id> \
  --role Owner \
  --scope /providers/Microsoft.Management/managementGroups/<mg-id>
```

### Error 3: PrincipalNotFound

**Cause:** Cortex Enterprise App not created or ID mismatch
**Solution:**
1. Cortex Console → Settings → Data Sources
2. Right-click Azure instance → Configuration
3. Click "Approve in Azure"
4. Download new ARM template

### Error 4: PartitionCount

**Cause:** Event Hub partition count too high for Standard tier
**Solution:** Already fixed in `variables.tf` - default is 4

### Error 5: Resource Provider Not Registered

**Cause:** `Microsoft.Insights` or `Microsoft.Aadiam` not registered
**Solution:**
```bash
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.Aadiam
# Wait 5-15 minutes for registration
```

**See:** `CORTEX_TROUBLESHOOTING_GUIDE.md` for comprehensive error solutions

---

## 🔧 Mandatory Coding Patterns

### 1. Terraform Variable Naming

```hcl
# ✅ CORRECT
variable "event_hub_partition_count" {
  description = "Number of partitions for Event Hub..."
  type        = number
  default     = 4

  validation {
    condition     = var.event_hub_partition_count >= 1 && var.event_hub_partition_count <= 32
    error_message = "..."
  }
}

# ❌ WRONG
variable "partitions" {
  type = number
  default = 20  # Too high for Standard tier!
}
```

### 2. Azure CLI Error Handling

```javascript
// ✅ CORRECT
async function executeAzureCommand(command, args) {
  const maxRetries = 3;
  const retryDelay = 2000; // 2 seconds

  for (let i = 0; i < maxRetries; i++) {
    try {
      return await executeCommand(command, args);
    } catch (error) {
      if (error.message.includes('InvalidAuthenticationToken')) {
        console.log('Token expired, refreshing...');
        await executeCommand('az', ['login']);
        continue;
      }
      if (i === maxRetries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, retryDelay));
    }
  }
}

// ❌ WRONG
async function executeAzureCommand(command, args) {
  return await executeCommand(command, args); // No retry, no error handling
}
```

### 3. WebSocket Progress Updates

```javascript
// ✅ CORRECT
sendToDeployment(deploymentId, {
  type: 'step',
  step: 'Waiting for Service Principal propagation (30s)...'
});
await new Promise(resolve => setTimeout(resolve, 30000));

// ❌ WRONG
// Missing wait time - causes PrincipalNotFound errors
await executeCommand('az', ['role', 'assignment', 'create', ...]);
```

### 4. Terraform Resource Naming

```hcl
# ✅ CORRECT
resource "azurerm_eventhub_namespace" "audit_logs" {
  name = "eh-cortex-audit-${var.environment}"
  sku  = var.event_hub_sku
  # ...
}

# ❌ WRONG
resource "azurerm_eventhub_namespace" "audit_logs" {
  name = "CortexEventHub"  # Not globally unique, will fail
  sku  = "Standard"        # Hardcoded, not configurable
}
```

---

## 📖 File Structure Reference

```
azure-cortex-onboarding/
├── .claude/
│   └── settings.local.json      # Claude Code permissions
├── public/
│   └── index.html               # React frontend SPA
├── scripts/
│   └── validate-permissions.sh  # Permission validation
├── deployments/                 # Per-deployment work directories
│   └── [uuid]/                 # Isolated deployment
├── server.js                    # Express + WebSocket backend
├── package.json                 # Node.js dependencies
├── main.tf                      # Core Terraform resources
├── azure-roles.tf               # Custom RBAC roles
├── azure-audit-logs.tf          # Event Hub + diagnostics
├── variables.tf                 # Terraform variables
├── outputs.tf                   # Terraform outputs
├── provider.tf                  # Azure provider config
├── check-prerequisites.sh       # Prerequisites validator
├── terraform.tfvars.example     # Example configuration
├── README.md                    # Main documentation
├── CORTEX_TROUBLESHOOTING_GUIDE.md  # Error solutions
└── DEPLOYMENT_GUIDE.md          # Step-by-step deployment
```

---

## 🎯 Quick Reference: Common Tasks

### Task 1: Add New Terraform Variable

1. Add to `variables.tf`:
   ```hcl
   variable "my_new_setting" {
     description = "Clear description"
     type        = string
     default     = "safe-default"

     validation {
       condition     = # validation logic
       error_message = "Helpful error message"
     }
   }
   ```

2. Update `server.js` `createTfvars()` function:
   ```javascript
   my_new_setting = "${config.myNewSetting}"
   ```

3. Update `public/index.html` form (if user-configurable)

4. Run: `terraform validate && terraform fmt`

### Task 2: Add New Validation Check

1. Create function in `check-prerequisites.sh`:
   ```bash
   echo -n "Checking new requirement... "
   # validation logic
   if [ condition ]; then
     echo -e "${GREEN}✓ PASSED${NC}"
     PASSED=$((PASSED + 1))
   else
     echo -e "${RED}✗ FAILED${NC}"
     FAILED=$((FAILED + 1))
   fi
   ```

2. Test: `./check-prerequisites.sh`

### Task 3: Update Error Handling in Backend

1. Edit `server.js` `runDeployment()` function
2. Add error detection pattern:
   ```javascript
   if (error.message.includes('SpecificError')) {
     deployment.error = 'User-friendly explanation';
     sendToDeployment(deploymentId, {
       type: 'error',
       error: 'Actionable suggestion',
       documentation: 'CORTEX_TROUBLESHOOTING_GUIDE.md#error-name'
     });
   }
   ```

### Task 4: Test Full Deployment Flow

```bash
# 1. Validate prerequisites
./check-prerequisites.sh
./scripts/validate-permissions.sh

# 2. Start server
npm run dev

# 3. Access UI
open http://localhost:3001

# 4. Monitor logs
# Watch terminal for deployment progress

# 5. Verify outputs
terraform output -json
```

---

## 🧪 Testing Checklist

Before committing changes:

- [ ] Run `terraform validate`
- [ ] Run `terraform fmt -check`
- [ ] Execute `./check-prerequisites.sh` successfully
- [ ] Test with invalid Azure credentials (error handling)
- [ ] Test with missing resource providers
- [ ] Verify WebSocket connection in browser dev tools
- [ ] Check that partition count defaults to 4
- [ ] Validate sensitive outputs are masked
- [ ] Confirm no secrets in logs

---

## 🆘 Troubleshooting Workflows

### Workflow 1: Deployment Hangs

1. Check WebSocket connection (Browser F12 → Network)
2. Check server logs for errors
3. Verify Azure CLI login: `az account show`
4. Check for Azure AD replication delay (wait 2-10min)

### Workflow 2: Permission Errors

1. Run: `./scripts/validate-permissions.sh`
2. Check Owner role assignment
3. Check Global Administrator status
4. Refresh Azure login: `az logout && az login`
5. Wait 5-10 minutes for propagation

### Workflow 3: Terraform Errors

1. Check `deployments/[uuid]/` directory for logs
2. Review Terraform state: `terraform show`
3. Validate configuration: `terraform validate`
4. Check for API version issues in provider
5. See `CORTEX_TROUBLESHOOTING_GUIDE.md`

---

## 📝 Documentation Standards

When updating documentation:

1. **Use clear headings** for scanability
2. **Provide code examples** for all procedures
3. **Include expected outputs** for validation steps
4. **Add troubleshooting notes** for common failures
5. **Reference related docs** with markdown links

---

## 🔑 Key Lessons Learned (Production Issues)

1. **Azure AD Propagation Takes Time**
   - Service Principal creation: wait 30s
   - Role assignment: wait 2-10 minutes
   - Resource provider registration: wait 5-15 minutes

2. **Event Hub Partition Count**
   - Standard tier: max 32 partitions
   - Default changed from 20 → 4 to avoid errors
   - Premium/Dedicated: configurable via variable

3. **Authentication Token Lifespan**
   - Default: 1 hour expiration
   - Implement token refresh in long deployments
   - Cache token expiry time for proactive refresh

4. **Resource Provider Registration**
   - Check BEFORE deployment, not during
   - Both `Microsoft.Insights` and `Microsoft.Aadiam` required
   - Registration is async (5-15min wait)

5. **Policy Compliance Timing**
   - Policy deployment ≠ policy compliance
   - Wait 2-15 minutes for evaluation
   - Manual remediation may be required

---

## ⚡ Final Reminders

- **Always validate prerequisites** before deployment
- **Never skip permission checks** (causes 90% of errors)
- **Wait for Azure AD propagation** after role changes
- **Use retry logic** for all Azure API calls
- **Check resource provider status** early
- **Test error handling** with invalid inputs
- **Document new error patterns** in troubleshooting guide
- **Keep Terraform modules idempotent** for re-runs

---

## 📞 Getting Help

- **Prerequisites Issues**: See `PREREQUISITES.md`
- **Deployment Errors**: See `CORTEX_TROUBLESHOOTING_GUIDE.md`
- **API Documentation**: See `CORTEX_CLOUD_ONBOARDING_APIs_LATEST.md`
- **Terraform Issues**: Check Azure Provider docs
- **Palo Alto Support**: Include deployment ID and full error logs

---

**Document Version:** 1.0
**Last Updated:** November 2025
**Maintainer:** Azure Cortex Onboarding Team
