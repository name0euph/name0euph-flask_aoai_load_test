# This Terraform configuration file defines the backend configuration for the staging environment.

terraform {
  required_providers {
    # Azure Resource Manager Provider
    # This provider is used to interact with Azure resources.
    # More information: https://registry.terraform.io/providers/hashicorp/azurerm/latest
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75.0"
    }

    # Azure AD Provider
    # This provider is used to interact with Azure Active Directory.
    # More information: https://registry.terraform.io/providers/hashicorp/azuread/latest/docs
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.43.0"
    }
  }
  required_version = ">= 1.1.0"

  backend "azurerm" {
  resource_group_name  = "rg-jfest-tfstate"
  storage_account_name = "tfjfestaoaiapp"
  container_name       = "tfstate-dev"
  key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  # Configuration options for the Azure Resource Manager provider
  features {}

  subscription_id = "1bb33ac0-0e0f-463e-a2e5-96c344166297"
  tenant_id       = "3df53f60-ec4e-493e-b55f-94665fe2b99c"
  client_id       = "eebf63a6-a5a0-4b88-8f32-f8b05d715bc3"
  client_secret   = "-5Y8Q~yUM4nasHh8Ed8846SeTIM4_3xEqkrUcdoR"
}

provider "azuread" {
  # Configuration options for the Azure AD provider
}