module "create_waf_custom_rule" {
  source = "../../modules/azure_waf_custom_policy_rule_block_ips"

  resource_group_name     = var.resource_group_name
  resource_group_location = var.resource_group_location
  csv_file_path           = var.csv_file_path
  waf_policy_name         = var.waf_policy_name
  rule_name               = var.rule_name
}