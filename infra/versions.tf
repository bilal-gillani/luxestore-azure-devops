terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.5.0"
    }
  }

  backend "azurerm" {
    # Backend configuration (storage account, container, key) will be supplied
    # dynamically via -backend-config flags in the pipeline.
  }
}

provider "azurerm" {
  features {}
}
