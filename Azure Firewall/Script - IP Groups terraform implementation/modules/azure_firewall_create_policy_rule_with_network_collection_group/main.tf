resource "azurerm_firewall_policy_rule_collection_group" "this_network" {
  for_each           = { for policy_rule_collection_group in var.policy_rule_collection_groups : policy_rule_collection_group.name => policy_rule_collection_group }
  name               = each.value.name
  firewall_policy_id = var.firewall_policy_id
  priority           = each.value.priority

  dynamic "network_rule_collection" {
    #assign the name as the unique key for the network_rule_collection so for_each works properly
    for_each = { for network_rule_collection in each.value.network_rule_collections : network_rule_collection.name => network_rule_collection }

    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        #assign the rule name as the unique key for the network_rule so for_each works properly
        for_each = { for network_rule in network_rule_collection.value.network_rules : network_rule.name => network_rule }
        content {
          name                  = rule.value.name
          protocols             = rule.value.protocols
          source_ip_groups      = [for ip_group in rule.value.source_ip_groups : lookup(var.ip_group_name_id_map, ip_group, "")]
          source_addresses      = rule.value.source_addresses
          destination_ip_groups = [for ip_group in rule.value.destination_ip_groups : lookup(var.ip_group_name_id_map, ip_group, "")]
          destination_addresses = rule.value.destination_addresses
          destination_ports     = rule.value.destination_ports
          destination_fqdns     = rule.value.destination_fqdns
        }
      }
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}
