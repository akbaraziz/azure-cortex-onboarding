# Context7 - Useful Libraries for This Project

Quick reference for libraries and tools that Context7 can provide documentation for.

---

## Azure Resources

### Azure CLI
```
az
az account
az ad
az provider
az role
az resource
```

**Example Queries:**
- "Show me az provider register documentation"
- "How do I use az role assignment create?"
- "What are the parameters for az account set?"

---

## Terraform Providers

### azurerm Provider
```
azurerm_resource_group
azurerm_eventhub_namespace
azurerm_eventhub
azurerm_eventhub_consumer_group
azurerm_eventhub_authorization_rule
azurerm_storage_account
azurerm_log_analytics_workspace
azurerm_role_assignment
azurerm_role_definition
azurerm_monitor_diagnostic_setting
azurerm_monitor_aad_diagnostic_setting
```

**Example Queries:**
- "Show me azurerm_eventhub resource documentation"
- "What are the arguments for azurerm_role_assignment?"
- "How do I configure azurerm_monitor_diagnostic_setting?"

### azuread Provider
```
azuread_application
azuread_service_principal
azuread_application_password
azuread_directory_role
azuread_directory_role_assignment
```

**Example Queries:**
- "Show me azuread_application documentation"
- "How do I create an azuread_service_principal?"
- "What are the options for azuread_application_password?"

---

## Node.js Backend Dependencies

### Core Dependencies
```javascript
// Web Framework
express

// WebSocket
ws

// UUID Generation
uuid

// Body Parsing
body-parser

// CORS
cors

// Child Process (built-in)
child_process
```

**Example Queries:**
- "Show me Express.js routing documentation"
- "How do I set up WebSocket with ws library?"
- "What are the uuid v4 generation options?"

### Dev Dependencies
```javascript
nodemon
@mendable/firecrawl-js
```

**Example Queries:**
- "How do I configure nodemon for auto-reload?"
- "Show me firecrawl-js API documentation"

---

## Development Tools

### Version Control
```
git
```

**Example Queries:**
- "Show me git commit best practices"
- "How do I create a pull request with git?"

### Package Management
```
npm
package.json
```

**Example Queries:**
- "What are npm scripts?"
- "How do I version bump with npm?"

---

## Azure Services Documentation

### Management Services
- Azure Active Directory (Azure AD / Entra ID)
- Azure Resource Manager (ARM)
- Azure Management Groups
- Azure Subscriptions

### Security & Monitoring
- Azure Monitor
- Azure Diagnostic Settings
- Azure Event Hubs
- Azure Storage Accounts
- Log Analytics Workspace

### Identity & Access
- Service Principals
- Managed Identities
- RBAC (Role-Based Access Control)
- Custom Role Definitions

---

## Terraform Documentation

### General
```
terraform
terraform init
terraform plan
terraform apply
terraform validate
terraform fmt
terraform output
```

**Example Queries:**
- "Show me terraform state management best practices"
- "How do I use terraform output?"
- "What are terraform variable validation rules?"

### Terraform Concepts
- Provider configuration
- Resource blocks
- Data sources
- Variables
- Outputs
- State management
- Workspaces

---

## Palo Alto Networks Cortex Cloud

### APIs
- Cortex Cloud Onboarding API
- Cloud Account API
- Policy API
- Compliance API

**Example Queries:**
- "Show me Cortex Cloud Azure onboarding API"
- "What are the Cortex Cloud account features?"

---

## How to Query Context7

### Automatic (Recommended)
Just mention the library in your question:
```
"How do I configure azurerm_eventhub?"
```

### Explicit
Request specific documentation:
```
"Get Context7 documentation for express.js"
"Fetch azurerm provider documentation"
"Show me the ws WebSocket library API"
```

---

## Most Useful Queries for This Project

### 1. Event Hub Configuration
```
"Show me azurerm_eventhub resource documentation with partition_count examples"
```

### 2. Service Principal Creation
```
"How do I create an azuread_service_principal with role assignments?"
```

### 3. Azure CLI Resource Provider
```
"Show me az provider register command with examples"
```

### 4. Terraform Role Assignments
```
"What are the arguments for azurerm_role_assignment?"
```

### 5. Express WebSocket Setup
```
"How do I set up WebSocket broadcasting with Express and ws?"
```

### 6. Diagnostic Settings
```
"Show me azurerm_monitor_diagnostic_setting configuration for Event Hub"
```

### 7. Azure AD Permissions
```
"What permissions does azuread_application need for Directory.Read.All?"
```

### 8. Terraform Variables
```
"Show me terraform variable validation examples"
```

---

## Tips for Effective Context7 Use

1. **Be Specific**: Mention exact resource names (e.g., "azurerm_eventhub" not just "event hub")
2. **Include Context**: Mention what you're trying to accomplish
3. **Version Matters**: Specify versions if known (e.g., "Express 4.x", "Terraform 1.5+")
4. **Follow Up**: Ask clarifying questions for deeper details

---

## Common Documentation Patterns

### Resource Arguments
```
"What are the required arguments for azurerm_eventhub?"
```

### Configuration Examples
```
"Show me an example azurerm_role_assignment configuration"
```

### Best Practices
```
"What are the best practices for azurerm_storage_account security?"
```

### Error Resolution
```
"How do I fix 'InvalidAuthenticationToken' in Azure CLI?"
```

---

## Troubleshooting

If Context7 doesn't provide documentation:

1. **Check Spelling**: Ensure library name is correct
2. **Be Explicit**: Use "Get Context7 documentation for [name]"
3. **Try Variants**: "express", "express.js", "expressjs"
4. **Official Names**: Use official package names (e.g., "ws" not "websocket")

---

**Quick Start:**
```
Try: "Show me azurerm_eventhub documentation"
```

Context7 will automatically fetch and display the latest documentation!
