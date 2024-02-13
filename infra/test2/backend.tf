# This Terraform configuration file defines the backend configuration for the staging environment.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    # Azure Resource Manager Provider
    # This provider is used to interact with Azure resources.
    # More information: https://registry.terraform.io/providers/hashicorp/azurerm/latest
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.89.0"
    }

    # Azure AD Provider
    # This provider is used to interact with Azure Active Directory.
    # More information: https://registry.terraform.io/providers/hashicorp/azuread/latest/docs
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-jfest-tfstate"
    storage_account_name = "tfjfestaoaiapp"
    container_name       = "tfstate-loadtest02"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  # Configuration options for the Azure Resource Manager provider
  features {}
}

provider "azuread" {
  # Configuration options for the Azure AD provider
}