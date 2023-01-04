terraform {

  required_version = ">=0.12"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.46.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "random" {
  length = 6
  special = false
  upper = false
}

//Resource Group AzureFWLab1

resource "azurerm_resource_group" "rg" {
  name      = "AzureFWLab11"
  location  = "eastus2"
}

//MySQL PaaS Service

resource "azurerm_mysql_server" "mysql" {
  name = "${random_string.random.result}-mysql"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  version = "8.0"
  administrator_login = "mysqladmin"
  administrator_login_password = "H@Sh1CoR3!"
  ssl_enforcement_enabled = "true"
  sku_name = "GP_Gen5_2"
}

//MySQL Private Endpoint

resource "azurerm_private_endpoint" "mysqlpe" {
  name = "${random_string.random.result}-endpoint"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id = azurerm_subnet.MySQL.id

  private_service_connection {
    name = "${random_string.random.result}-privateserviceconnection"
    private_connection_resource_id = azurerm_mysql_server.mysql.id
    subresource_names = [ "mysqlServer" ]
    is_manual_connection = false
  }
}

//Public IPs (Firewall)

resource "azurerm_public_ip" "transitip" {
  name                   = "FWTransitIP"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  allocation_method      = "Static"
  sku                    = "Standard"
}

//Firewall Policy Premium

resource "azurerm_firewall_policy" "FwPolicy" {
  name = "FwPolicy"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku = "Premium"
  private_ip_ranges = ["10.10.10.0/26","10.10.10.64/27"]
}

//Firewall Policy Rule Collections and Rules

resource "azurerm_firewall_policy_rule_collection_group" "FwLabRcg" {
  name = "FwLabRcg"
  firewall_policy_id = azurerm_firewall_policy.FwPolicy.id
  priority = 600
  application_rule_collection {
    name = "app_rule_collection1"
    priority = 500
    action = "Allow"
    rule {
      name = "app_rule_collection1_rule1"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses = ["10.10.10.64/27"]
      destination_fqdns = ["*.microsoft.com"]
    }
    rule {
        name = "app_rule_collection1_rule2"
        protocols {
            type = "Https"
            port = 443
        }
        source_addresses = ["10.10.10.64/27"]
        destination_fqdns = ["${azurerm_mysql_server.mysql.name}.mysql.database.azure.com"]
    }
  }
  network_rule_collection {
    name = "network_rule_collection1"
    priority = 400
    action = "Deny"
    rule {
      name = "network_rule_collection1_rule1"
      protocols = ["TCP","UDP"]
      source_addresses = ["10.10.10.64/27"]
      destination_addresses = ["8.8.8.8"]
      destination_ports = ["80","443"]
    }
  }
  network_rule_collection {
    name = "network_rule_collection2"
    priority = 395
    action = "Allow"
    rule {
      name = "network_rule_collection2_rule1"
      protocols = ["TCP"]
      source_addresses = ["10.10.10.64/27"]
      destination_addresses = ["10.10.10.100/32"]
      destination_ports = ["443","3306"]
    }
  }
  nat_rule_collection {
    name = "nat_rule_collection1"
    priority = 300
    action = "Dnat"
    rule {
        name = "nat_rule_collection1_rule1"
        protocols = ["TCP","UDP"]
        source_addresses = ["*"]
        destination_address = azurerm_public_ip.transitip.ip_address
        destination_ports = ["3389"]
        translated_address = "10.10.10.68"
        translated_port = "3389"
    }
  }
}

//Route Tables (UDRs)

resource "azurerm_route_table" "Spoke1RT" {
  name                          = "Spoke1RT"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = "false"

  route {
    name = "DefaultRoute"
    address_prefix = "0.0.0.0/0"
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = "10.10.10.4"
  }
  route {
    name = "MySqlPE"
    address_prefix = "10.10.10.100/32"
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = "10.10.10.4"
  }
}

//Hub Vnet

resource "azurerm_virtual_network" "hubvnet" {
  name = "HubVnet"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space = ["10.10.10.0/24"]
}

resource "azurerm_subnet" "AzureFirewallSubnet" {
  name = "AzureFirewallSubnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hubvnet.name
  address_prefixes = ["10.10.10.0/26"]
}

resource "azurerm_subnet" "AppSubnet" {
  name = "AppSubnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hubvnet.name
  address_prefixes = ["10.10.10.64/27"]
}

resource "azurerm_subnet" "MySQL" {
  name = "mysqlsubnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hubvnet.name
  address_prefixes = ["10.10.10.96/27"]
}

//Route Table + Subnet Association

resource "azurerm_subnet_route_table_association" "AppSubnetRT" {
  subnet_id = azurerm_subnet.AppSubnet.id
  route_table_id = azurerm_route_table.Spoke1RT.id
}

//Azure Firewall Premium

resource "azurerm_firewall" "azfw" {
  name                   = "azfw"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  firewall_policy_id     = azurerm_firewall_policy.FwPolicy.id
  sku_tier               = "Premium"
  sku_name               = "AZFW_VNet"

  ip_configuration {
    name                 = "transitconfig"
    subnet_id            = azurerm_subnet.AzureFirewallSubnet.id
    public_ip_address_id = azurerm_public_ip.transitip.id
  }
}

//AppVm1 Network Interface

resource "azurerm_network_interface" "AppVm1Nic1" {
  name                  = "AppVm1Nic1"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "AppVmNicConfig1"
    subnet_id                     = azurerm_subnet.AppSubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

//AppVm1

resource "azurerm_virtual_machine" "AppVm1" {
  name = "AppVm1"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.AppVm1Nic1.id]
  vm_size = "Standard_DS1_V2"
  
  storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-22h2-pro"
    version   = "latest"
  }

  storage_os_disk {
    name = "myosdisk1"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name = "appvm1"
    admin_username = "fwbasicadmin"
    admin_password = "Password1234!"
  }

  os_profile_windows_config {
    
  }
}

//Azure Private DNS Zone (mysql.database.azure.com) and A record

resource "azurerm_private_dns_zone" "mysqlprivdnszone" {
  name = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_a_record" "mysqldnsrecord" {
  name = azurerm_mysql_server.mysql.name
  zone_name = azurerm_private_dns_zone.mysqlprivdnszone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl = 300
  records = ["10.10.10.100"]
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysqldnszonelink" {
  name = "HubVnetLink"
  resource_group_name = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.mysqlprivdnszone.name
  virtual_network_id    = azurerm_virtual_network.hubvnet.id
}

//Log Analytics Workspace used by the Firewall's Diagnostic Settings

resource "azurerm_log_analytics_workspace" "DiagSettingsLaw" {
    name = "DiagSettingsLaw"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku = "PerGB2018"
    retention_in_days = 30
}

// Firewall's Diagnostic Settings (Resource Specific Logs)

resource "azurerm_monitor_diagnostic_setting" "azfw-diag" {
  name = "RsFwLogDedicatedPeVnet"
  target_resource_id = azurerm_firewall.azfw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.DiagSettingsLaw.id
  log_analytics_destination_type = "Dedicated"

  log {
    category = "AZFWApplicationRule"
    enabled = true
    retention_policy {
      enabled = true
    }
  }

  log {
    category = "AZFWNetworkRule"
    enabled = true
    retention_policy {
        enabled = true
    }
  }

  metric {
    category = "AllMetrics"
    enabled = false

    retention_policy {
      enabled = false
    }
  }
}