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

resource "azurerm_resource_group" "rg" {
  name      = "AzureFW-Basic"
  location  = "eastus2"
}

resource "azurerm_public_ip" "transitip" {
  name                   = "FWBasicTransitIP"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  allocation_method      = "Static"
  sku                    = "Standard"
}

resource "azurerm_public_ip" "managementip" {
  name                   = "FWBasicManagementIP"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  allocation_method      = "Static"
  sku                    = "Standard"
}

resource "azurerm_route_table" "Spoke1RT" {
  name                          = "Spoke1RT"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = "false"

  route {
    name                    = "DefaultRoute"
    address_prefix          = "0.0.0.0/0"
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address  = "10.10.10.4"
  }
}

resource "azurerm_virtual_network" "hubvnet" {
  name                   = "HubVnet"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  address_space          = ["10.10.10.0/24"]
}

resource "azurerm_subnet" "AzureFirewallSubnet" {
  name                   = "AzureFirewallSubnet"
  resource_group_name    = azurerm_resource_group.rg.name
  virtual_network_name   = azurerm_virtual_network.hubvnet.name
  address_prefixes       = ["10.10.10.0/26"]
}

resource "azurerm_subnet" "AzureFirewallMgmtSubnet" {
  name                   = "AzureFirewallManagementSubnet"
  resource_group_name    = azurerm_resource_group.rg.name
  virtual_network_name   = azurerm_virtual_network.hubvnet.name
  address_prefixes       = ["10.10.10.64/26"]
}

resource "azurerm_virtual_network" "spokevnet1" {
  name                   = "SpokeVnet1"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  address_space          = ["10.10.11.0/24"]
}

resource "azurerm_subnet" "AppSubnet" {
  name                   = "AppSubnet"
  resource_group_name    = azurerm_resource_group.rg.name
  virtual_network_name   = azurerm_virtual_network.spokevnet1.name
  address_prefixes       = ["10.10.11.0/27"]
}

resource "azurerm_subnet" "InfraSubnet" {
  name                   = "InfraSubnet"
  resource_group_name    = azurerm_resource_group.rg.name
  virtual_network_name   = azurerm_virtual_network.spokevnet1.name
  address_prefixes       = ["10.10.11.32/27"]
}

resource "azurerm_subnet_route_table_association" "AppSubnetRT" {
  subnet_id              = azurerm_subnet.AppSubnet.id
  route_table_id         = azurerm_route_table.Spoke1RT.id
}

resource "azurerm_subnet_route_table_association" "InfraSubnetRT" {
  subnet_id              = azurerm_subnet.InfraSubnet.id
  route_table_id         = azurerm_route_table.Spoke1RT.id
}

resource "azurerm_virtual_network_peering" "HubToSpoke1" {
  name                      = "HubToSpoke1"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.hubvnet.name
  remote_virtual_network_id = azurerm_virtual_network.spokevnet1.id
}

resource "azurerm_virtual_network_peering" "Spoke1ToHub" {
  name                      = "HubToSpoke1"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spokevnet1.name
  remote_virtual_network_id = azurerm_virtual_network.hubvnet.id
}

resource "azurerm_firewall_policy" "FwBasicPolicy" {
  name                   = "FwBasicPolicy"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  sku                    = "Basic"
}

resource "azurerm_firewall_policy_rule_collection_group" "FwBasicLabRcg" {
  name = "FwBasicLabRcg"
  firewall_policy_id = azurerm_firewall_policy.FwBasicPolicy.id
  priority = 600
  application_rule_collection {
    name = "AppRuleCollection1"
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
      source_addresses = ["10.10.11.0/24"]
      destination_fqdns = ["*.microsoft.com"]
    }
  }
  network_rule_collection {
    name = "network_rule_collection1"
    priority = 400
    action = "Deny"
    rule {
        name = "network_rule_collection1_rule1"
        protocols = ["TCP","UDP"]
        source_addresses = ["10.10.11.0/24"]
        destination_addresses = ["8.8.8.8"]
        destination_ports = ["80","443"]
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
        translated_address = "10.10.11.4"
        translated_port = "3389"
    }
  }
}

resource "azurerm_firewall" "FwBasic" {
  name                   = "FwBasic"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  firewall_policy_id     = azurerm_firewall_policy.FwBasicPolicy.id
  sku_tier               = "Basic"
  sku_name               = "AZFW_VNet"

  ip_configuration {
    name                 = "transitconfig"
    subnet_id            = azurerm_subnet.AzureFirewallSubnet.id
    public_ip_address_id = azurerm_public_ip.transitip.id
  }

  management_ip_configuration {
    name                 = "mgmtconfig"
    subnet_id            = azurerm_subnet.AzureFirewallMgmtSubnet.id
    public_ip_address_id = azurerm_public_ip.managementip.id
  }
}

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
