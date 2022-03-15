#create multiple IP groups from individual csv files
module "create_ip_groups" {
  source   = "../azure_create_ip_group_from_csv"
  for_each = { for ip_group in var.ip_group_definitions : ip_group.ip_group_name => ip_group }

  #go back to the root directory for the starting relative file location
  csv_file_path           = "./${each.value.csv_filename}"
  ip_group_name           = each.value.ip_group_name
  resource_group_name     = var.resource_group_name
  resource_group_location = var.resource_group_location
}