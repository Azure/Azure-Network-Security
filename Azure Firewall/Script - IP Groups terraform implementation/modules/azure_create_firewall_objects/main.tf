locals {
  firewall_config = jsondecode(file("${var.input_filename}"))
}

module "create_ip_groups" {
  for_each = { for deployment in local.firewall_config.deployments : deployment.name => deployment }
  source   = "../azure_create_multiple_ip_groups_from_csv"

  ip_group_definitions    = each.value.ip_groups
  resource_group_name     = each.value.resource_group_name
  resource_group_location = each.value.resource_group_location
}


module "deploy_network_rules" {
  for_each = { for deployment in local.firewall_config.deployments : deployment.name => deployment if deployment.mode == "classic" }
  source   = "../azure_firewall_create_rule_collection_groups"

  firewall_config      = each.value
  ip_group_name_id_map = module.create_ip_groups[each.value.name].ip_group_name_id_map

  depends_on = [
    module.create_ip_groups
  ]
}

module "deploy_policies" {
  for_each = { for deployment in local.firewall_config.deployments : deployment.name => deployment if deployment.mode == "policy" }
  source   = "../azure_firewall_create_or_update_policy"

  firewall_config      = each.value
  ip_group_name_id_map = module.create_ip_groups[each.value.name].ip_group_name_id_map

  depends_on = [
    module.create_ip_groups
  ]
}

