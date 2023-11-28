#create policy if config file set to true
resource "azurerm_firewall_policy" "this_policy" {
  for_each = { for policy in var.firewall_config.firewall_policies : policy.name => policy if var.firewall_config.create_policy == "true" }

  name                = each.value.name
  resource_group_name = var.firewall_config.resource_group_name
  location            = var.firewall_config.resource_group_location
}

/*
#deploy network collections after policy creation
module "deploy_firewall_policy_network_collections" {
  for_each = { for policy in var.firewall_config.firewall_policies : policy.name => policy if var.firewall_config.create_policy == "true" }
  source   = "../azure_firewall_create_policy_rule_with_network_collection_group"

  policy_rule_collection_groups = each.value.rule_collection_groups
  firewall_policy_id            = lookup(zipmap(values(azurerm_firewall_policy.this_policy)[*].name, values(azurerm_firewall_policy.this_policy)[*].id), each.value.name, "")
  ip_group_name_id_map          = var.ip_group_name_id_map
}
*/

#lookup the policyIds - set dependency on policy creation to ensure full set of ID values. 
data "azurerm_firewall_policy" "this_policy" {
  for_each = { for policy in var.firewall_config.firewall_policies : policy.name => policy }

  name                = each.value.name
  resource_group_name = var.firewall_config.resource_group_name

  depends_on = [
    azurerm_firewall_policy.this_policy
  ]
}

#deploy the network collections
module "deploy_firewall_policy_network_collections" {
  for_each = { for policy in var.firewall_config.firewall_policies : policy.name => policy }
  source   = "../azure_firewall_create_policy_rule_with_network_collection_group"

  policy_rule_collection_groups = each.value.rule_collection_groups
  firewall_policy_id            = lookup(zipmap(values(data.azurerm_firewall_policy.this_policy)[*].name, values(data.azurerm_firewall_policy.this_policy)[*].id), each.value.name, "")
  ip_group_name_id_map          = var.ip_group_name_id_map
}