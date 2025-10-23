terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" # Updated from 3.0 to 4.0 (latest: 4.49.0)
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0" # Updated from 2.0 to 3.0 (latest: 3.6.0)
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}
