variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "csv_file_path" {
  type        = string
  description = "relative file path for the csv input file containing the CIDR ranges to include in the IP Group"
}

variable "waf_policy_name" {
  type = string
}

variable "rule_name" {
  type = string
}