output "policy_id" {
  value = module.create_waf_custom_rule.policy_id
}

output "rule_cidr_list" {
    value = module.create_waf_custom_rule.rule_cidr_list
}