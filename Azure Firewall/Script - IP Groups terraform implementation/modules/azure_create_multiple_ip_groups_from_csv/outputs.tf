output "ip_group_ids" {
  value = values(module.create_ip_groups)[*].ip_group_id
}

output "ip_group_name_id_map" {
  value = zipmap(values(module.create_ip_groups)[*].ip_group_name, values(module.create_ip_groups)[*].ip_group_id)
}