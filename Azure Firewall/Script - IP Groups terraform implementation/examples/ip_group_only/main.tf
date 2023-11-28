module "create_firewall_objects" {
  source = "../../modules/azure_create_firewall_objects"

  input_filename = "./ip_groups_only.json"
}