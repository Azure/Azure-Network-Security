locals {
  cidr_range_map = csvdecode(file(var.csv_file_path))
  cidr_list      = [for element in local.cidr_range_map : trimspace(element.cidr)]
}

resource "azurerm_ip_group" "this" {
  name                = var.ip_group_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  cidrs               = local.cidr_list
}