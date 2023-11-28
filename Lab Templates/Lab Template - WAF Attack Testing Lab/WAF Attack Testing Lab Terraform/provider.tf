terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.58.0"
    }
    null = {
      source = "hashicorp/null"
      version = "3.2.1"
    }
  }
}

provider "azurerm" {
  # Configuration options
    features {
  }
}
provider "null" {
  # Configuration options
}