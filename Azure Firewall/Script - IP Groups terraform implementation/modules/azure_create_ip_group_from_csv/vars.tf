variable "csv_file_path" {
  type        = string
  description = "relative file path for the csv input file containing the CIDR ranges to include in the IP Group"
}

variable "ip_group_name" {
  type        = string
  description = "resource name for the new ip group resource"
}

variable "resource_group_name" {
  type        = string
  description = "resource group name where the new ip group resource will be created"
}

variable "resource_group_location" {
  type        = string
  description = "resource group location where the new ip group resource will be created"
}
