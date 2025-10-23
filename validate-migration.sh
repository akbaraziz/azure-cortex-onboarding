#!/bin/bash
# Terraform Migration Validation Script
# Project: azure-cortex-ui
# Purpose: Validate provider updates and configuration changes

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Check if we're in the right directory
if [ ! -f "provider.tf" ]; then
    print_error "provider.tf not found. Please run this script from the project root."
    exit 1
fi

print_header "Azure Cortex UI - Terraform Migration Validation"

# Step 1: Check prerequisites
print_header "Step 1: Checking Prerequisites"

# Check Terraform
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)
    print_success "Terraform installed: v${TERRAFORM_VERSION}"
else
    print_error "Terraform not found. Please install Terraform >= 1.0"
    exit 1
fi

# Check Azure CLI
if command -v az &> /dev/null; then
    AZ_VERSION=$(az version --output json | grep -o '"azure-cli": "[^"]*' | cut -d'"' -f4)
    print_success "Azure CLI installed: v${AZ_VERSION}"
else
    print_warning "Azure CLI not found. Required for deployment, but not for validation."
fi

# Check Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | cut -d' ' -f3)
    print_success "Git installed: v${GIT_VERSION}"
else
    print_warning "Git not found. Recommended for version control."
fi

# Step 2: Create backups
print_header "Step 2: Creating Backups"

BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup Terraform files
cp *.tf "$BACKUP_DIR/" 2>/dev/null || true
print_success "Backed up .tf files to $BACKUP_DIR"

# Backup state if exists
if [ -f "terraform.tfstate" ]; then
    cp terraform.tfstate "$BACKUP_DIR/terraform.tfstate.backup"
    print_success "Backed up terraform.tfstate"
else
    print_info "No terraform.tfstate found (this is OK for new deployments)"
fi

# Backup lock file if exists
if [ -f ".terraform.lock.hcl" ]; then
    cp .terraform.lock.hcl "$BACKUP_DIR/.terraform.lock.hcl.backup"
    print_success "Backed up .terraform.lock.hcl"
else
    print_info "No .terraform.lock.hcl found (will be created during init)"
fi

print_success "All backups saved to: $BACKUP_DIR"

# Step 3: Verify updated provider versions
print_header "Step 3: Verifying Provider Version Updates"

if grep -q 'version = "~> 4.0"' provider.tf; then
    print_success "azurerm provider updated to ~> 4.0"
else
    print_error "azurerm provider NOT updated. Expected: ~> 4.0"
    exit 1
fi

if grep -A 2 'azuread = {' provider.tf | grep -q 'version = "~> 3.0"'; then
    print_success "azuread provider updated to ~> 3.0"
else
    print_error "azuread provider NOT updated. Expected: ~> 3.0"
    exit 1
fi

# Step 4: Check for deprecated retention_policy
print_header "Step 4: Checking for Deprecated Configurations"

# Check for retention_policy blocks (not in comments)
if grep -v "^[[:space:]]*#" azure-audit-logs.tf | grep -q "retention_policy"; then
    print_error "Found deprecated 'retention_policy' in azure-audit-logs.tf"
    print_info "Please remove all retention_policy blocks from enabled_log configurations"
    exit 1
else
    print_success "No deprecated retention_policy blocks found"
fi

# Step 5: Terraform initialization
print_header "Step 5: Initializing Terraform with New Providers"

print_info "Removing old provider plugins..."
rm -rf .terraform/

print_info "Running terraform init -upgrade..."
if terraform init -upgrade; then
    print_success "Terraform initialization successful"
else
    print_error "Terraform initialization failed"
    print_info "Check error messages above for details"
    exit 1
fi

# Step 6: Validate configuration
print_header "Step 6: Validating Terraform Configuration"

if terraform validate; then
    print_success "Terraform configuration is valid"
else
    print_error "Terraform validation failed"
    print_info "Fix errors shown above before proceeding"
    exit 1
fi

# Step 7: Check provider versions
print_header "Step 7: Verifying Installed Provider Versions"

print_info "Installed provider versions:"
if [ -f ".terraform.lock.hcl" ]; then
    grep -A 2 "provider \"registry.terraform.io" .terraform.lock.hcl | grep version || true
    print_success "Provider lock file created successfully"
else
    print_warning "Lock file not found"
fi

# Step 8: Format check
print_header "Step 8: Checking Terraform Formatting"

if terraform fmt -check -recursive; then
    print_success "All Terraform files are properly formatted"
else
    print_warning "Some files need formatting. Run: terraform fmt -recursive"
fi

# Step 9: Security check
print_header "Step 9: Security Configuration Review"

# Check for hardcoded secrets
if grep -r -i "password\|secret\|key" *.tf | grep -v "var\." | grep -v "#" | grep "=" ; then
    print_warning "Found potential hardcoded secrets. Review above lines."
else
    print_success "No hardcoded secrets detected"
fi

# Check TLS version
if grep -q 'min_tls_version.*"TLS1_2"' azure-audit-logs.tf; then
    print_success "TLS 1.2 enforced on storage accounts"
else
    print_warning "Verify TLS 1.2 is enforced on storage accounts"
fi

# Check HTTPS enforcement
if grep -q 'enable_https_traffic_only.*true' azure-audit-logs.tf; then
    print_success "HTTPS-only traffic enforced"
else
    print_warning "Verify HTTPS-only traffic is enforced"
fi

# Final summary
print_header "Validation Summary"

echo ""
echo "✅ All critical validations passed!"
echo ""
echo "📋 Next Steps:"
echo "  1. Review the migration plan:"
echo "     ${BLUE}terraform plan${NC}"
echo ""
echo "  2. If plan looks good, apply changes:"
echo "     ${BLUE}terraform apply${NC}"
echo ""
echo "  3. Run post-deployment tests (see MIGRATION_GUIDE.md)"
echo ""
echo "📚 Documentation:"
echo "  - Migration Guide: ./MIGRATION_GUIDE.md"
echo "  - Audit Report: ./AZURE_API_AUDIT_REPORT.md"
echo ""
echo "💾 Backups saved to: ${GREEN}$BACKUP_DIR${NC}"
echo ""

print_success "Migration validation completed successfully!"

exit 0
