#Replace the comments below with the environment specific details
#rename this file to providers.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
  #Note - if account isn't newly created, ensure that existing az login account has Storage Blob Data Owner role assigned
  /*
  backend "azurerm" {
    resource_group_name  = "<resource_group_for_tf_state_storage_account"
    storage_account_name = "<tf_state_storage_account_name"
    container_name       = "<blob_container_for_tf_state>"
    key                  = "<blob_file_name_for_tf_state>"
    use_azuread_auth     = true
    subscription_id      = "<subscription id for storage account"
    tenant_id            = "<tenant id for storage account"
  }
*/
}


provider "azurerm" {
  features {}
}
