# Context7 MCP Server Configuration

Context7 is an MCP (Model Context Protocol) server that provides automatic library documentation lookup for development.

## What is Context7?

Context7 automatically fetches and provides:
- Library documentation
- API references
- Installation guides
- Code examples

When you mention a library or framework, Context7 can automatically provide relevant documentation.

## Already Configured

Context7 is already enabled in this project with the following permissions in `.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "mcp__context7__resolve-library-id",
      "mcp__context7__get-library-docs"
    ]
  }
}
```

## Usage in This Project

### For Azure CLI
When discussing Azure CLI commands, Context7 can provide:
- Azure CLI documentation
- Command reference
- Best practices

**Example:**
```
"How do I use az role assignment create?"
```

Context7 will automatically fetch Azure CLI documentation.

### For Terraform
When working with Terraform resources, Context7 can provide:
- Provider documentation
- Resource schemas
- Configuration examples

**Example:**
```
"Show me the azurerm_eventhub resource documentation"
```

### For Node.js Packages
When working with the Express.js backend, Context7 can provide:
- NPM package documentation
- API references
- Usage examples

**Example:**
```
"How do I use the ws WebSocket library?"
```

## Relevant Libraries for This Project

Context7 is particularly useful for:

### Azure-Related
- `azure-cli` - Azure command-line interface
- `@azure/identity` - Azure authentication
- `@azure/arm-resources` - Azure Resource Manager

### Terraform
- `azurerm` provider documentation
- `azuread` provider documentation
- Terraform best practices

### Node.js Backend
- `express` - Web framework
- `ws` - WebSocket library
- `uuid` - UUID generation
- `body-parser` - Request parsing

### Development Tools
- `terraform` - Infrastructure as Code
- `eslint` - Code linting
- `nodemon` - Auto-reload server

## How It Works

1. **Automatic Detection**: When you ask about a library, Context7 detects it
2. **Documentation Fetch**: Context7 retrieves the latest documentation
3. **Context Injection**: Documentation is provided in the response

## Manual Usage

You can explicitly request documentation:

```
"Get Context7 documentation for express.js"
"Fetch Azure CLI documentation for az provider register"
"Show me Terraform azurerm_role_assignment docs"
```

## Benefits for This Project

### 1. Azure CLI Commands
- Quickly reference command syntax
- Understand parameter options
- See usage examples

### 2. Terraform Resources
- Resource schema validation
- Required vs optional arguments
- Attribute references

### 3. Node.js Dependencies
- API method signatures
- Configuration options
- Error handling patterns

### 4. Best Practices
- Up-to-date recommendations
- Common patterns
- Security considerations

## Troubleshooting

### Context7 Not Working?

If Context7 doesn't respond:

1. **Check Permissions**: Ensure `.claude/settings.local.json` includes Context7 permissions
2. **Restart Claude Code**: Restart to reload MCP servers
3. **Network Issues**: Context7 requires internet access to fetch documentation

### Manual Override

If automatic detection fails, explicitly request:

```
"Use Context7 to get documentation for [library-name]"
```

## Privacy & Security

- Context7 only fetches **public** documentation
- No code from your project is sent to Context7
- Only library names are queried
- All documentation is from official sources

## Relevant Documentation Sources

Context7 pulls from:
- **npm**: Node.js package documentation
- **PyPI**: Python package docs
- **Official Sites**: Azure, Terraform, etc.
- **GitHub**: README and wikis
- **Read the Docs**: Popular documentation hosting

## Examples for This Project

### Example 1: Azure Resource Provider Registration

**Query:**
```
"How do I register an Azure resource provider using Azure CLI?"
```

**Context7 provides:**
- `az provider register` command syntax
- Available parameters
- Usage examples
- Common resource providers

### Example 2: Terraform Event Hub Configuration

**Query:**
```
"Show me the azurerm_eventhub resource configuration options"
```

**Context7 provides:**
- Resource schema
- Required arguments: `name`, `namespace_name`, `partition_count`
- Optional arguments: `message_retention`, `status`
- Attribute reference

### Example 3: Express.js WebSocket Setup

**Query:**
```
"How do I set up WebSocket with Express.js using the ws library?"
```

**Context7 provides:**
- Installation: `npm install ws`
- Basic setup code
- Connection handling
- Broadcasting to clients

## Tips for Effective Use

1. **Be Specific**: Mention exact package/library names
2. **Include Version**: If using specific versions (e.g., "Express 4.x")
3. **Context Matters**: Mention what you're trying to accomplish
4. **Ask Follow-ups**: Context7 can provide deeper details

## Integration with CLAUDE.md

This project's `CLAUDE.md` file includes Context7 in the development workflow:

- **Auto-triggers**: Library setup questions
- **Manual usage**: Specify library name in query
- **Documentation**: Always up-to-date references

## Next Steps

1. **Try it out**: Ask about any library used in this project
2. **Verify accuracy**: Context7 provides official docs, but always validate
3. **Provide feedback**: If documentation is outdated, check official sources

---

**Context7 Status:** ✅ **ENABLED**
**Configured in:** `.claude/settings.local.json`
**MCP Version:** Latest
**Last Updated:** November 2025
