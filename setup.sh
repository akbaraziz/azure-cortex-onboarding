#!/bin/bash

################################################################################
# Azure Cortex Cloud Onboarding UI - Setup Script
# This script sets up the web UI for Azure Cortex Cloud onboarding
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo ""
print_info "================================================"
print_info "  Azure Cortex Cloud Onboarding UI Setup"
print_info "================================================"
echo ""

# Check Node.js
print_info "Checking for Node.js..."
if command_exists node; then
    NODE_VERSION=$(node --version)
    print_success "Node.js is installed: $NODE_VERSION"
else
    print_error "Node.js is not installed!"
    echo "Please install Node.js 16 or later from https://nodejs.org/"
    exit 1
fi

# Check npm
print_info "Checking for npm..."
if command_exists npm; then
    NPM_VERSION=$(npm --version)
    print_success "npm is installed: $NPM_VERSION"
else
    print_error "npm is not installed!"
    exit 1
fi

# Check Azure CLI
print_info "Checking for Azure CLI..."
if command_exists az; then
    AZ_VERSION=$(az --version | head -n 1)
    print_success "Azure CLI is installed: $AZ_VERSION"
else
    print_warning "Azure CLI is not installed!"
    echo "Install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
fi

# Check Terraform
print_info "Checking for Terraform..."
if command_exists terraform; then
    TF_VERSION=$(terraform --version | head -n 1)
    print_success "Terraform is installed: $TF_VERSION"
else
    print_warning "Terraform is not installed!"
    echo "Install it from: https://www.terraform.io/downloads"
fi

# Install npm dependencies
print_info "Installing npm dependencies..."
npm install

print_success "Dependencies installed successfully!"

# Create deployments directory
print_info "Creating deployments directory..."
mkdir -p deployments
print_success "Deployments directory created!"

# Copy Terraform files if they exist in parent directory
print_info "Checking for Terraform files..."
TERRAFORM_FILES=(
    "../variables.tf"
    "../azure-roles.tf"
    "../azure-audit-logs.tf"
    "../outputs.tf"
)

TERRAFORM_DIR="../terraform-files"
mkdir -p "$TERRAFORM_DIR"

FOUND_FILES=0
for file in "${TERRAFORM_FILES[@]}"; do
    if [ -f "$file" ]; then
        cp "$file" "$TERRAFORM_DIR/"
        print_success "Copied $(basename "$file")"
        ((FOUND_FILES++))
    fi
done

if [ $FOUND_FILES -eq 0 ]; then
    print_warning "No Terraform files found in parent directory."
    print_info "Please ensure the following files are available:"
    echo "  - variables.tf"
    echo "  - azure-roles.tf"
    echo "  - azure-audit-logs.tf"
    echo "  - outputs.tf"
else
    print_success "Found and copied $FOUND_FILES Terraform files"
fi

echo ""
print_success "================================================"
print_success "  Setup Complete!"
print_success "================================================"
echo ""
print_info "Next steps:"
echo ""
echo "  1. Ensure you're logged into Azure:"
echo "     $ az login"
echo ""
echo "  2. Start the server:"
echo "     $ npm start"
echo ""
echo "  3. Open your browser to:"
echo "     http://localhost:3001"
echo ""
print_warning "Important: Make sure all Terraform files are in place before starting!"
echo ""
