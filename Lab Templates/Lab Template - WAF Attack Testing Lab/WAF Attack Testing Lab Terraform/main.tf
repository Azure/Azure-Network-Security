resource "azurerm_windows_virtual_machine" "res-0" {
  admin_password        = var.vm_password
  admin_username        = var.vm_admin
  location              = var.location
  name                  = "VM-Win11"
  network_interface_ids = [azurerm_network_interface.res-28.id]
  resource_group_name   = var.resourceGroupName
  size                  = "Standard_D2s_v3"
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    offer     = "Windows-11"
    publisher = "MicrosoftWindowsDesktop"
    sku       = "win11-21h2-pro"
    version   = "latest"
  }
  depends_on = [
    azurerm_network_interface.res-28,
  ]
}
resource "azurerm_resource_group" "res-3" {
  location = var.location
  name     = var.resourceGroupName
}
resource "azurerm_cdn_frontdoor_profile" "res-4" {
  name                     = "${var.hostname}-${var.unique_name}"
  resource_group_name      = var.resourceGroupName
  response_timeout_seconds = 30
  sku_name                 = "Premium_AzureFrontDoor"
  depends_on = [
    azurerm_resource_group.res-3,
  ]
}
resource "azurerm_cdn_frontdoor_endpoint" "res-5" {
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.res-4.id
  name                     = "${var.hostname}-${var.unique_name}"
  depends_on = [
    azurerm_cdn_frontdoor_profile.res-4,
  ]
}
resource "azurerm_cdn_frontdoor_route" "res-6" {
#  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.res-7.id]
  cdn_frontdoor_endpoint_id       = azurerm_cdn_frontdoor_endpoint.res-5.id
  cdn_frontdoor_origin_group_id   = azurerm_cdn_frontdoor_origin_group.res-8.id
  cdn_frontdoor_origin_ids        = [azurerm_cdn_frontdoor_origin.res-9.id]
  forwarding_protocol             = "HttpOnly"
  https_redirect_enabled          = false
  name                            = "AppGW"
  patterns_to_match               = ["/*"]
  supported_protocols             = ["Http", "Https"]
  depends_on = [
    azurerm_cdn_frontdoor_endpoint.res-5,
    azurerm_cdn_frontdoor_origin_group.res-8,
  ]
}
resource "azurerm_cdn_frontdoor_origin_group" "res-8" {
  cdn_frontdoor_profile_id                                  = azurerm_cdn_frontdoor_profile.res-4.id
  name                                                      = "OWASP"
  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 0
  session_affinity_enabled                                  = false
  health_probe {
    interval_in_seconds = 30
    protocol            = "Http"
    request_type        = "GET"
  }
  load_balancing {
    additional_latency_in_milliseconds = 0
    successful_samples_required        = 2
  }
  depends_on = [
    azurerm_cdn_frontdoor_profile.res-4,
  ]
}
resource "azurerm_cdn_frontdoor_origin" "res-9" {
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.res-8.id
  certificate_name_check_enabled = true
  host_name                      = azurerm_public_ip.res-37.ip_address
  name                           = "5bf80d53-4a64-4f03-a84f-f937b20a75f5"
  enabled                        = true
  origin_host_header             = azurerm_public_ip.res-37.ip_address
  weight                         = 50
  depends_on = [
    azurerm_cdn_frontdoor_origin_group.res-8,
  ]
}
resource "azurerm_cdn_frontdoor_security_policy" "res-10" {
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.res-4.id
  name                     = "socnsfdpolicyPremium-securityPolicy"
  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.res-571.id
      association {
        patterns_to_match = ["/*"]
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.res-5.id
        }
      }
    }
  }
  depends_on = [
    azurerm_cdn_frontdoor_profile.res-4,
  ]
}
resource "null_resource" "kali" {

  provisioner "local-exec" {
    command = <<EOT
    az vm image accept-terms --urn kali-linux:kali:kali:latest
    EOT
  }
}
resource "azurerm_linux_virtual_machine" "res-11" {
  admin_password                  = var.vm_password
  admin_username                  = var.vm_admin
  disable_password_authentication = false
  location                        = var.location
  name                            = "VM-Kali"
  network_interface_ids           = [azurerm_network_interface.res-29.id]
  resource_group_name             = var.resourceGroupName
  size                            = "Standard_D2s_v3"
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  plan {
    name      = "kali"
    product   = "kali"
    publisher = "kali-linux"
  }
  source_image_reference {
    offer     = "kali"
    publisher = "kali-linux"
    sku       = "kali"
    version   = "latest"
  }
  depends_on = [
    azurerm_network_interface.res-29,
    # azurerm_marketplace_agreement.kali,
  ]
}
resource "azurerm_windows_virtual_machine" "res-14" {
  admin_password        = var.vm_password
  admin_username        = var.vm_admin
  license_type          = "Windows_Server"
  location              = var.location
  name                  = "VM-Win2019"
  network_interface_ids = [azurerm_network_interface.res-30.id]
  resource_group_name   = var.resourceGroupName
  size                  = "Standard_D2s_v3"
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  depends_on = [
    azurerm_network_interface.res-30,
    null_resource.kali
  ]
}
resource "azurerm_web_application_firewall_policy" "res-17" {
  location            = var.location
  name                = "SOC-NS-AGPolicy"
  resource_group_name = var.resourceGroupName
  custom_rules {
    action    = "Block"
    name      = "SentinelBlockIP"
    priority  = 10
    rule_type = "MatchRule"
    match_conditions {
      match_values = ["104.210.223.108"]
      operator     = "IPMatch"
      match_variables {
        variable_name = "RemoteAddr"
      }
    }
  }
  custom_rules {
    action    = "Block"
    name      = "BlockGeoLocationChina"
    priority  = 20
    rule_type = "MatchRule"
    match_conditions {
      match_values = ["CN"]
      operator     = "GeoMatch"
      match_variables {
        variable_name = "RemoteAddr"
      }
    }
  }
  custom_rules {
    action    = "Block"
    name      = "BlockInternetExplorer11"
    priority  = 30
    rule_type = "MatchRule"
    match_conditions {
      match_values = ["rv:11.0"]
      operator     = "Contains"
      match_variables {
        selector      = "User-Agent"
        variable_name = "RequestHeaders"
      }
    }
  }
  managed_rules {
    managed_rule_set {
      version = "3.1"
      rule_group_override {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
      }
    }
  }
  policy_settings {
    enabled = false
  }
  depends_on = [
    azurerm_resource_group.res-3,
  ]
}
resource "azurerm_application_gateway" "res-18" {
  firewall_policy_id  = azurerm_web_application_firewall_policy.res-17.id
  location            = var.location
  name                = "SOC-NS-AG-WAFv2"
  resource_group_name = var.resourceGroupName
  backend_address_pool {
    fqdns = ["owaspdirect-${var.unique_name}.azurewebsites.net"]
    name  = "PAAS-APP"
  }
  backend_http_settings {
    affinity_cookie_name  = "ApplicationGatewayAffinity"
    cookie_based_affinity = "Disabled"
    host_name             = "owaspdirect-${var.unique_name}.azurewebsites.net"
    name                  = "Default"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 20
  }
  frontend_ip_configuration {
    name                 = "appGwPublicFrontendIp"
    public_ip_address_id = azurerm_public_ip.res-37.id
  }
  frontend_ip_configuration {
    name                          = "appGwPrivateFrontendIp"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.25.120"
    subnet_id                     = azurerm_subnet.res-42.id
  }
  frontend_port {
    name = "port_443"
    port = 443
  }
  frontend_port {
    name = "port_80"
    port = 80
  }
  frontend_port {
    name = "port_8080"
    port = 8080
  }
  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.res-42.id
  }
  http_listener {
    frontend_ip_configuration_name = "appGwPublicFrontendIp"
    frontend_port_name             = "port_80"
    name                           = "Public-HTTP"
    protocol                       = "Http"
  }
  request_routing_rule {
    backend_address_pool_name  = "PAAS-APP"
    backend_http_settings_name = "Default"
    http_listener_name         = "Public-HTTP"
    name                       = "PublicIPRule"
    priority                   = 10010
    rule_type                  = "Basic"
  }
  sku {
    capacity = 2
    name     = "WAF_v2"
    tier     = "WAF_v2"
  }
  depends_on = [
    azurerm_web_application_firewall_policy.res-17,
    azurerm_public_ip.res-37,
    azurerm_subnet.res-42,
  ]
}
resource "azurerm_firewall" "res-19" {
  firewall_policy_id  = azurerm_firewall_policy.res-21.id
  location            = var.location
  name                = "SOC-NS-FW"
  resource_group_name = var.resourceGroupName
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  ip_configuration {
    name                 = "SOCNSFWPIP"
    public_ip_address_id = azurerm_public_ip.res-38.id
    subnet_id            = azurerm_subnet.res-43.id
  }
  depends_on = [
    azurerm_firewall_policy.res-21,
    azurerm_public_ip.res-38,
    azurerm_subnet.res-43,
  ]
}
resource "azurerm_network_ddos_protection_plan" "res-20" {
  location            = var.location
  name                = "SOCNSDDOSPLAN"
  resource_group_name = var.resourceGroupName
  depends_on = [
    azurerm_resource_group.res-3,
  ]
}
resource "azurerm_firewall_policy" "res-21" {
  sku                      = "Standard"
  location                 = var.location
  name                     = "SOC-NS-FWPolicy"
  resource_group_name      = var.resourceGroupName
  threat_intelligence_mode = "Deny"
  depends_on = [
    azurerm_resource_group.res-3,
  ]
}
resource "azurerm_firewall_policy_rule_collection_group" "res-25" {
  firewall_policy_id = azurerm_firewall_policy.res-21.id
  name               = "DefaultApplicationRuleCollectionGroup"
  priority           = 300
  application_rule_collection {
    action   = "Allow"
    name     = "Internet-Access"
    priority = 100
    rule {
      destination_fqdns = ["www.google.com", "www.bing.com", "google.com", "bing.com"]
      name              = "SearchEngineAccess"
      source_addresses  = ["*"]
      protocols {
        port = 80
        type = "Http"
      }
      protocols {
        port = 443
        type = "Https"
      }
    }
    rule {
      destination_fqdns = ["*"]
      name              = "Kali-InternetAccess"
      source_addresses  = ["10.0.27.68"]
      protocols {
        port = 80
        type = "Http"
      }
      protocols {
        port = 443
        type = "Https"
      }
    }
    rule {
      destination_fqdns = ["*"]
      name              = "Win11-Inet-Access"
      source_addresses  = ["10.0.27.4"]
      protocols {
        port = 80
        type = "Http"
      }
      protocols {
        port = 443
        type = "Https"
      }
    }
  }
  depends_on = [
    azurerm_firewall_policy.res-21,
  ]
}
resource "azurerm_firewall_policy_rule_collection_group" "res-26" {
  firewall_policy_id = azurerm_firewall_policy.res-21.id
  name               = "DefaultDnatRuleCollectionGroup"
  priority           = 100
  nat_rule_collection {
    action   = "Dnat"
    name     = "APPGW-WEBAPP"
    priority = 100
    rule {
      destination_address = azurerm_public_ip.res-38.ip_address
      destination_ports   = ["443"]
      name                = "DNATRule"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      translated_address  = "10.0.25.70"
      translated_port     = 443
    }
  }
  nat_rule_collection {
    action   = "Dnat"
    name     = "VM-Win11"
    priority = 101
    rule {
      destination_address = azurerm_public_ip.res-38.ip_address
      destination_ports   = ["33891"]
      name                = "DNATRule"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      translated_address  = "10.0.27.4"
      translated_port     = 3389
    }
  }
  nat_rule_collection {
    action   = "Dnat"
    name     = "Kali-SSH"
    priority = 102
    rule {
      destination_address = azurerm_public_ip.res-38.ip_address
      destination_ports   = ["22"]
      name                = "SSH-DNATRule"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      translated_address  = "10.0.27.68"
      translated_port     = 22
    }
  }
  nat_rule_collection {
    action   = "Dnat"
    name     = "Kali-RDP"
    priority = 103
    rule {
      destination_address = azurerm_public_ip.res-38.ip_address
      destination_ports   = ["33892"]
      name                = "DNATRule"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      translated_address  = "10.0.27.68"
      translated_port     = 3389
    }
  }
  nat_rule_collection {
    action   = "Dnat"
    name     = "VM-Win2019"
    priority = 104
    rule {
      destination_address = azurerm_public_ip.res-38.ip_address
      destination_ports   = ["33890"]
      name                = "DNATRule"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      translated_address  = "10.0.28.4"
      translated_port     = 3389
    }
  }
  depends_on = [
    azurerm_firewall_policy.res-21,
  ]
}
resource "azurerm_firewall_policy_rule_collection_group" "res-27" {
  firewall_policy_id = azurerm_firewall_policy.res-21.id
  name               = "DefaultNetworkRuleCollectionGroup"
  priority           = 200
  network_rule_collection {
    action   = "Allow"
    name     = "IntraVNETandHTTPOutAccess"
    priority = 100
    rule {
      destination_addresses = ["10.0.27.68", "10.0.28.4", "10.0.27.4"]
      destination_ports     = ["445"]
      name                  = "SMB"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.27.68", "10.0.28.4", "10.0.27.4"]
    }
    rule {
      destination_addresses = ["10.0.27.68", "10.0.28.4", "10.0.27.4"]
      destination_ports     = ["3389"]
      name                  = "RDP"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.27.68", "10.0.28.4", "10.0.27.4"]
    }
    rule {
      destination_addresses = ["10.0.27.4"]
      destination_ports     = ["22"]
      name                  = "SSH"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.27.68", "10.0.28.4"]
    }
    rule {
      destination_addresses = ["*"]
      destination_ports     = ["80"]
      name                  = "Kali-HTTP"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.27.68"]
    }
  }
  depends_on = [
    azurerm_firewall_policy.res-21,
  ]
}
resource "azurerm_network_interface" "res-28" {
  location            = var.location
  name                = "Nic1"
  resource_group_name = var.resourceGroupName
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Static"
    private_ip_address_version    = "IPv4"
    private_ip_address            = "10.0.27.4"
    subnet_id                     = azurerm_subnet.res-47.id
  }
  depends_on = [
    # One of azurerm_subnet.res-47,azurerm_subnet_network_security_group_association.res-48,azurerm_subnet_route_table_association.res-49 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_network_interface" "res-29" {
  location            = var.location
  name                = "Nic2"
  resource_group_name = var.resourceGroupName
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Static"
    private_ip_address_version    = "IPv4"
    private_ip_address            = "10.0.27.68"
    subnet_id                     = azurerm_subnet.res-50.id
  }
  depends_on = [
    # One of azurerm_subnet.res-50,azurerm_subnet_network_security_group_association.res-51,azurerm_subnet_route_table_association.res-52 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_network_interface" "res-30" {
  location            = var.location
  name                = "Nic3"
  resource_group_name = var.resourceGroupName
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Static"
    private_ip_address_version    = "IPv4"
    private_ip_address            = "10.0.28.4"
    subnet_id                     = azurerm_subnet.res-55.id
  }
  depends_on = [
    # One of azurerm_subnet.res-55,azurerm_subnet_network_security_group_association.res-56,azurerm_subnet_route_table_association.res-57 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_network_security_group" "res-31" {
  location            = var.location
  name                = "SOC-NS-NSG-SPOKE1"
  resource_group_name = var.resourceGroupName
  depends_on = [
    azurerm_resource_group.res-3,
  ]
}
resource "azurerm_network_security_rule" "res-32" {
  access                      = "Allow"
  destination_address_prefix  = "VirtualNetwork"
  destination_port_range      = "*"
  direction                   = "Inbound"
  name                        = "Allow-Spoke2-VNET"
  network_security_group_name = azurerm_network_security_group.res-31.name
  priority                    = 100
  protocol                    = "*"
  resource_group_name         = var.resourceGroupName
  source_address_prefix       = "10.0.28.0/24"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-31,
  ]
}
resource "azurerm_network_security_rule" "res-33" {
  access                      = "Allow"
  destination_address_prefix  = "10.0.28.0/24"
  destination_port_range      = "*"
  direction                   = "Outbound"
  name                        = "Allow-Spoke2-VNET-outbound"
  network_security_group_name = azurerm_network_security_group.res-31.name
  priority                    = 100
  protocol                    = "*"
  resource_group_name         = var.resourceGroupName
  source_address_prefix       = "VirtualNetwork"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-31,
  ]
}
resource "azurerm_network_security_group" "res-34" {
  location            = var.location
  name                = "SOC-NS-NSG-SPOKE2"
  resource_group_name = var.resourceGroupName
  depends_on = [
    azurerm_resource_group.res-3,
  ]
}
resource "azurerm_network_security_rule" "res-35" {
  access                      = "Allow"
  destination_address_prefix  = "VirtualNetwork"
  destination_port_range      = "*"
  direction                   = "Inbound"
  name                        = "Allow-Spoke1-VNET-Inbound"
  network_security_group_name = azurerm_network_security_group.res-34.name
  priority                    = 100
  protocol                    = "*"
  resource_group_name         = var.resourceGroupName
  source_address_prefix       = "10.0.27.0/24"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-34,
  ]
}
resource "azurerm_network_security_rule" "res-36" {
  access                      = "Allow"
  destination_address_prefix  = "10.0.27.0/24"
  destination_port_range      = "*"
  direction                   = "Outbound"
  name                        = "Allow-Spoke1-VNET-Outbound"
  network_security_group_name = azurerm_network_security_group.res-34.name
  priority                    = 100
  protocol                    = "*"
  resource_group_name         = var.resourceGroupName
  source_address_prefix       = "VirtualNetwork"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-34,
  ]
}
resource "azurerm_public_ip" "res-37" {
  allocation_method   = "Static"
  location            = var.location
  name                = "SOCNSAGPIP"
  resource_group_name = var.resourceGroupName
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  depends_on = [
    azurerm_resource_group.res-3,
  ]
}
resource "azurerm_public_ip" "res-38" {
  allocation_method   = "Static"
  location            = var.location
  name                = "SOCNSFWPIP"
  resource_group_name = var.resourceGroupName
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  depends_on = [
    azurerm_resource_group.res-3,
  ]
}
resource "azurerm_route_table" "res-39" {
  location            = var.location
  name                = "SOC-NS-DEFAULT-ROUTE"
  resource_group_name = var.resourceGroupName
  depends_on = [
    azurerm_resource_group.res-3,
  ]
}
resource "azurerm_route" "res-40" {
  address_prefix         = "0.0.0.0/0"
  name                   = "DefaultRoute"
  next_hop_in_ip_address = "10.0.25.4"
  next_hop_type          = "VirtualAppliance"
  resource_group_name    = var.resourceGroupName
  route_table_name       = azurerm_route_table.res-39.name
  depends_on = [
    azurerm_route_table.res-39,
  ]
}
resource "azurerm_virtual_network" "res-41" {
  address_space       = ["10.0.25.0/24"]
  location            = var.location
  name                = "VN-HUB"
  resource_group_name = var.resourceGroupName
  tags = {
    displayName = "VN-HUB"
  }
  ddos_protection_plan {
    enable = false
    id     = azurerm_network_ddos_protection_plan.res-20.id
  }
  depends_on = [
    azurerm_network_ddos_protection_plan.res-20,
  ]
 }
resource "azurerm_subnet" "res-42" {
  address_prefixes     = ["10.0.25.64/26"]
  name                 = "AGWAFSubnet"
  resource_group_name  = var.resourceGroupName
  service_endpoints    = ["Microsoft.AzureActiveDirectory", "Microsoft.KeyVault", "Microsoft.ServiceBus", "Microsoft.Sql", "Microsoft.Storage", "Microsoft.Web"]
  virtual_network_name = "VN-HUB"
  depends_on = [
    azurerm_virtual_network.res-41,
  ]
}
resource "azurerm_subnet" "res-43" {
  address_prefixes     = ["10.0.25.0/26"]
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resourceGroupName
  service_endpoints    = ["Microsoft.AzureActiveDirectory", "Microsoft.KeyVault", "Microsoft.ServiceBus", "Microsoft.Sql", "Microsoft.Storage", "Microsoft.Web"]
  virtual_network_name = "VN-HUB"
  depends_on = [
    azurerm_virtual_network.res-41,
  ]
}
resource "azurerm_virtual_network_peering" "res-44" {
  allow_forwarded_traffic   = true
  name                      = "VN-HUB-Peering-To-VN-SPOKE1"
  remote_virtual_network_id = azurerm_virtual_network.res-46.id
  resource_group_name       = var.resourceGroupName
  virtual_network_name      = "VN-HUB"
  depends_on = [
    azurerm_virtual_network.res-41,
    azurerm_virtual_network.res-46,
  ]
}
resource "azurerm_virtual_network_peering" "res-45" {
  allow_forwarded_traffic   = true
  name                      = "VN-HUB-Peering-To-VN-SPOKE2"
  remote_virtual_network_id = azurerm_virtual_network.res-54.id
  resource_group_name       = var.resourceGroupName
  virtual_network_name      = "VN-HUB"
  depends_on = [
    azurerm_virtual_network.res-41,
    azurerm_virtual_network.res-54,
  ]
}
resource "azurerm_virtual_network" "res-46" {
  address_space       = ["10.0.27.0/24"]
  location            = var.location
  name                = "VN-SPOKE1"
  resource_group_name = var.resourceGroupName
  tags = {
    displayName = "VN-SPOKE1"
  }
  depends_on = [
    azurerm_resource_group.res-3,
  ]
}
resource "azurerm_subnet" "res-47" {
  address_prefixes     = ["10.0.27.0/26"]
  name                 = "SPOKE1-SUBNET1"
  resource_group_name  = var.resourceGroupName
  service_endpoints    = ["Microsoft.AzureActiveDirectory", "Microsoft.KeyVault", "Microsoft.ServiceBus", "Microsoft.Sql", "Microsoft.Storage", "Microsoft.Web"]
  virtual_network_name = "VN-SPOKE1"
  depends_on = [
    azurerm_virtual_network.res-46,
  ]
}
resource "azurerm_subnet_network_security_group_association" "res-48" {
  network_security_group_id = azurerm_network_security_group.res-31.id
  subnet_id                 = azurerm_subnet.res-47.id
  depends_on = [
    azurerm_network_security_group.res-31,
    # One of azurerm_subnet.res-47,azurerm_subnet_route_table_association.res-49 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_subnet_route_table_association" "res-49" {
  route_table_id = azurerm_route_table.res-39.id
  subnet_id      = azurerm_subnet.res-47.id
  depends_on = [
    azurerm_route_table.res-39,
    # One of azurerm_subnet.res-47,azurerm_subnet_network_security_group_association.res-48 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_subnet" "res-50" {
  address_prefixes     = ["10.0.27.64/26"]
  name                 = "SPOKE1-SUBNET2"
  resource_group_name  = var.resourceGroupName
  service_endpoints    = ["Microsoft.AzureActiveDirectory", "Microsoft.KeyVault", "Microsoft.ServiceBus", "Microsoft.Sql", "Microsoft.Storage", "Microsoft.Web"]
  virtual_network_name = "VN-SPOKE1"
  depends_on = [
    azurerm_virtual_network.res-46,
  ]
}
resource "azurerm_subnet_network_security_group_association" "res-51" {
  network_security_group_id = azurerm_network_security_group.res-31.id
  subnet_id                 = azurerm_subnet.res-50.id
  depends_on = [
    azurerm_network_security_group.res-31,
    # One of azurerm_subnet.res-50,azurerm_subnet_route_table_association.res-52 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_subnet_route_table_association" "res-52" {
  route_table_id = azurerm_route_table.res-39.id
  subnet_id      = azurerm_subnet.res-50.id
  depends_on = [
    azurerm_route_table.res-39,
    # One of azurerm_subnet.res-50,azurerm_subnet_network_security_group_association.res-51 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_virtual_network_peering" "res-53" {
  allow_forwarded_traffic   = true
  name                      = "VN-SPOKE1-Peering-To-VN-HUB"
  remote_virtual_network_id = azurerm_virtual_network.res-41.id
  resource_group_name       = var.resourceGroupName
  virtual_network_name      = "VN-SPOKE1"
  depends_on = [
    azurerm_virtual_network.res-41,
    azurerm_virtual_network.res-46,
  ]
}
resource "azurerm_virtual_network" "res-54" {
  address_space       = ["10.0.28.0/24"]
  location            = var.location
  name                = "VN-SPOKE2"
  resource_group_name = var.resourceGroupName
  tags = {
    displayName = "VN-SPOKE2"
  }
  depends_on = [
    azurerm_resource_group.res-3,
  ]
}
resource "azurerm_subnet" "res-55" {
  address_prefixes     = ["10.0.28.0/26"]
  name                 = "SPOKE2-SUBNET1"
  resource_group_name  = var.resourceGroupName
  service_endpoints    = ["Microsoft.AzureActiveDirectory", "Microsoft.KeyVault", "Microsoft.ServiceBus", "Microsoft.Sql", "Microsoft.Storage", "Microsoft.Web"]
  virtual_network_name = "VN-SPOKE2"
  depends_on = [
    azurerm_virtual_network.res-54,
  ]
}
resource "azurerm_subnet_network_security_group_association" "res-56" {
  network_security_group_id = azurerm_network_security_group.res-34.id
  subnet_id                 = azurerm_subnet.res-55.id
  depends_on = [
    azurerm_network_security_group.res-34,
    # One of azurerm_subnet.res-55,azurerm_subnet_route_table_association.res-57 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_subnet_route_table_association" "res-57" {
  route_table_id = azurerm_route_table.res-39.id
  subnet_id      = azurerm_subnet.res-55.id
  depends_on = [
    azurerm_route_table.res-39,
    # One of azurerm_subnet.res-55,azurerm_subnet_network_security_group_association.res-56 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_subnet" "res-58" {
  address_prefixes     = ["10.0.28.64/26"]
  name                 = "SPOKE2-SUBNET2"
  resource_group_name  = var.resourceGroupName
  service_endpoints    = ["Microsoft.AzureActiveDirectory", "Microsoft.KeyVault", "Microsoft.ServiceBus", "Microsoft.Sql", "Microsoft.Storage", "Microsoft.Web"]
  virtual_network_name = "VN-SPOKE2"
  depends_on = [
    azurerm_virtual_network.res-54,
  ]
}
resource "azurerm_subnet_network_security_group_association" "res-59" {
  network_security_group_id = azurerm_network_security_group.res-34.id
  subnet_id                 = azurerm_subnet.res-58.id
  depends_on = [
    azurerm_network_security_group.res-34,
    # One of azurerm_subnet.res-58,azurerm_subnet_route_table_association.res-60 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_subnet_route_table_association" "res-60" {
  route_table_id = azurerm_route_table.res-39.id
  subnet_id      = azurerm_subnet.res-58.id
  depends_on = [
    azurerm_route_table.res-39,
    # One of azurerm_subnet.res-58,azurerm_subnet_network_security_group_association.res-59 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_virtual_network_peering" "res-61" {
  allow_forwarded_traffic   = true
  name                      = "VN-SPOKE2-Peering-To-VN-HUB"
  remote_virtual_network_id = azurerm_virtual_network.res-41.id
  resource_group_name       = var.resourceGroupName
  virtual_network_name      = "VN-SPOKE2"
  depends_on = [
    azurerm_virtual_network.res-41,
    azurerm_virtual_network.res-54,
  ]
}
resource "azurerm_log_analytics_workspace" "res-62" {
  location            = var.location
  name                = "netseclabwaf"
  resource_group_name = var.resourceGroupName
  depends_on = [
    azurerm_resource_group.res-3,
  ]
}
resource "azurerm_service_plan" "res-540" {
  location            = var.location
  name                = "OWASP-ASP"
  os_type             = "Linux"
  resource_group_name = var.resourceGroupName
  sku_name            = "S1"
  depends_on = [
    azurerm_resource_group.res-3,
  ]
}
resource "azurerm_linux_web_app" "res-541" {
  app_settings = {
    DOCKER_REGISTRY_SERVER_URL          = "https://index.docker.io"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
  }
  location            = var.location
  name                = "owaspdirect-${var.unique_name}"
  resource_group_name = var.resourceGroupName
  service_plan_id     = azurerm_service_plan.res-540.id
  site_config {
    ftps_state = "FtpsOnly"
    application_stack {
      docker_image = "mohitkusecurity/juice-shop-updated"
      docker_image_tag = "latest"
    }
  }
  depends_on = [
    azurerm_service_plan.res-540,
  ]
}
resource "azurerm_cdn_frontdoor_firewall_policy" "res-571" {
  custom_block_response_body        = "QmxvY2tlZCBieSBmcm9udCBkb29yIFdBRg=="
  custom_block_response_status_code = 403
  mode                              = "Prevention"
  name                              = "socnsfdpolicyPremium"
  redirect_url                      = "https://www.microsoft.com/en-us/edge"
  resource_group_name               = var.resourceGroupName
  sku_name                          = "Premium_AzureFrontDoor"
  custom_rule {
    action               = "Block"
    name                 = "BlockGeoLocationChina"
    priority             = 10
    rate_limit_threshold = 100
    type                 = "MatchRule"
    match_condition {
      match_values   = ["CN"]
      match_variable = "RemoteAddr"
      operator       = "GeoMatch"
    }
  }
  custom_rule {
    action               = "Redirect"
    name                 = "RedirectInternetExplorerUserAgent"
    priority             = 20
    rate_limit_threshold = 100
    type                 = "MatchRule"
    match_condition {
      match_values   = ["rv:11.0"]
      match_variable = "RequestHeader"
      operator       = "Contains"
      selector       = "User-Agent"
    }
  }
  custom_rule {
    action               = "Block"
    name                 = "RateLimitRequest"
    priority             = 30
    rate_limit_threshold = 1
    type                 = "RateLimitRule"
    match_condition {
      match_values   = ["search"]
      match_variable = "RequestUri"
      operator       = "Contains"
    }
  }
  managed_rule {
    action  = "Block"
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    override {
      rule_group_name = "MS-ThreatIntel-SQLI"
      rule {
        action  = "AnomalyScoring"
        enabled = true
        rule_id = "99031003"
      }
    }
  }
  managed_rule {
    action  = "Allow"
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    override {
      rule_group_name = "GoodBots"
      rule {
        action  = "Log"
        enabled = true
        rule_id = "Bot200200"
      }
    }
  }
  depends_on = [
    azurerm_resource_group.res-3,
  ]
}
