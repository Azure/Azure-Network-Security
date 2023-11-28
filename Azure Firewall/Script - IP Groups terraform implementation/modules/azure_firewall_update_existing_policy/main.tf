module "deploy_firewall_policy_network_collections" {
  for_each = { for policy in var.firewall_config.firewall_policies : policy.name => policy if var.firewall_config.create_policy == "false" }
  source   = "../azure_firewall_create_policy_rule_with_network_collection_group"

  policy_rule_collection_groups = each.value.rule_collection_groups
  firewall_policy_id            = lookup(zipmap(values(azurerm_firewall_policy.this_policy)[*].name, values(azurerm_firewall_policy.this_policy)[*].id), each.value.name, "")
  ip_group_name_id_map          = var.ip_group_name_id_map
}

