#dynamically create network rule collections and network rules
#this can potentially be extended for all rule types and values if needed. Using a basic implementation for now

resource "azurerm_firewall_network_rule_collection" "this_network" {
  for_each            = { for network_rule_collection in var.firewall_config.network_rule_collections : network_rule_collection.name => network_rule_collection }
  name                = each.value.name
  azure_firewall_name = var.firewall_config.azure_firewall_name
  resource_group_name = var.firewall_config.resource_group_name
  priority            = each.value.priority
  action              = each.value.action

  dynamic "rule" {
    for_each = each.value.network_rules
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
  lifecycle {
    create_before_destroy = true
  }
}
