output "ip_group_id" {
  value = azurerm_ip_group.this.id
}

output "cidr_list" {
  value = local.cidr_list
}

output "ip_group_name" {
  value = var.ip_group_name
}