@description('The Azure region into which the resources should be deployed.')
param location string

@description('Username for the Windows 11 VM.')
@secure()
param win11Username string

@description('Password for the Windows 11 VM.')
@secure()
param win11Password string

var hubVnetName = 'HubVnet'
var hubVnetAddress = '10.10.10.0/24'
var hubSubnet1Name = 'AzureFirewallSubnet'
var hubSubnet1Address = '10.10.10.0/26'
var hubSubnet2Name = 'AzureFirewallManagementSubnet'
var hubSubnet2Address = '10.10.10.64/26'
var spokeVnetName = 'SpokeVnet1'
var spokeVnetAddress = '10.10.11.0/24'
var spokeSubnet1Name = 'AppSubnet'
var spokeSubnet1Address = '10.10.11.0/27'
var spokeSubnet2Name = 'InfraSubnet'
var spokeSubnet2Address = '10.10.11.32/27'
var routeTableName = 'Spoke1RT'
var routeName = 'DefaultRoute'
var fwPip = 'FWBasicTransitIP'
var fwMngmtPip = 'FWBasicManagementIP'
var fwName = 'FWBasic'
var fwPolicyName = 'FWBasicPolicy'
var fwPolicyRuleCollectionGroupName = 'FwBasicLabRcg'
var vmName = 'AppVm1'
var vmSize = 'Standard_DS1_V2'
var vmImage = {
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'windows-11'
  sku: 'win11-22h2-pro'
  version: 'latest'
}
var vmOsDisk = {
  createOption: 'FromImage'
  managedDisk: {
    storageAccountType: 'StandardSSD_LRS'
  }
}
var vmOsProfile = {
  computerName: vmName
  adminUsername: win11Username
  adminPassword: win11Password
}

resource hubVnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: hubVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddress
      ]
    }
  }
  resource hubSubnet1 'subnets' = {
    name: hubSubnet1Name
    properties: {
      addressPrefix: hubSubnet1Address
    }
  }
  resource hubSubnet2 'subnets' = {
    name: hubSubnet2Name
    properties: {
      addressPrefix: hubSubnet2Address
    }
    dependsOn: [
      hubSubnet1
    ]
  }
}

resource spokeVnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: spokeVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVnetAddress
      ]
    }
  }
  resource spokeSubnet1 'subnets' = {
    name: spokeSubnet1Name
    properties: {
      addressPrefix: spokeSubnet1Address
      routeTable: {
        id: spokeRouteTable.id
      }
    }
  }
  resource spokeSubnet2 'subnets' = {
    name: spokeSubnet2Name
    properties: {
      addressPrefix: spokeSubnet2Address
      routeTable: {
        id: spokeRouteTable.id
      }
    }
    dependsOn: [
      spokeSubnet1
    ]
  }
}

resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-05-01' = {
  name: '${hubVnetName}-to-${spokeVnetName}'
  parent: hubVnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    doNotVerifyRemoteGateways: false
    remoteAddressSpace: {
      addressPrefixes: [
        spokeVnetAddress
      ]
    }
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
    useRemoteGateways: false
  }
  dependsOn: [
    spokeVnet::spokeSubnet2
  ]
}

resource spoketoHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-05-01' = {
  name: '${spokeVnetName}-to-${hubVnetName}'
  parent: spokeVnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    doNotVerifyRemoteGateways: false
    remoteAddressSpace: {
      addressPrefixes: [
        hubVnetAddress
      ]
    }
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
    useRemoteGateways: false
  }
  dependsOn: [
    spokeVnet::spokeSubnet2
  ]
}

resource spokeRouteTable 'Microsoft.Network/routeTables@2022-05-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: routeName
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: fwbasic.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

resource hubFwPolicy 'Microsoft.Network/firewallPolicies@2022-05-01' = {
  name: fwPolicyName
  location: location
  properties: {
    sku: {
      tier: 'Basic'
    }
    threatIntelMode: 'Alert'
  }
}

resource hubFwPolicyRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-05-01' = {
  name: fwPolicyRuleCollectionGroupName
  parent: hubFwPolicy
  properties: {
    priority: 600
    ruleCollections: [
      {
        name: 'nat_rule_collection1'
        priority: 300
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        action: {
          type: 'DNAT'
        }
        rules: [
          {
            name: 'nat_rule_collection1_rule1'
            ruleType: 'NatRule'
            destinationAddresses: [
              fwMainPip.properties.ipAddress
            ]
            destinationPorts: [
              '33889'
            ]
            ipProtocols: [
              'TCP'
              'UDP'
            ]
            sourceAddresses: [
              '*'
            ]
            translatedAddress: windowsNic.properties.ipConfigurations[0].properties.privateIPAddress
            translatedPort: '3389'
          }
        ]
      }
      {
        name: 'network_rule_collection1'
        priority: 400
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Deny'
        }
        rules: [
          {
            name: 'network_rule_collection1_rule1'
            ruleType: 'NetworkRule'
            destinationAddresses: [
              '8.8.8.8'
            ]
            destinationPorts: [
              '80'
              '443'
            ]
            ipProtocols: [
              'TCP'
              'UDP'
            ]
            sourceAddresses: [
              spokeVnetAddress
            ]
          }
        ]
      }
      {
        name: 'application_rule_collection1'
        priority: 500
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'application_rule_collection1_rule1'
            ruleType: 'ApplicationRule'
            targetFqdns: [
              '*.microsoft.com'
            ]
            protocols: [
              {
                port: 80
                protocolType: 'Http'
              }
              {
                port: 443
                protocolType: 'Https'
              }
            ]
            sourceAddresses: [
              spokeVnetAddress
            ]
          }
        ]
      }
    ]
  }
}

resource fwMainPip 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: fwPip
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource fwManagementPip 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: fwMngmtPip
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource fwbasic 'Microsoft.Network/azureFirewalls@2022-05-01' = {
  name: fwName
  location: location
  properties: {
    firewallPolicy: {
      id: hubFwPolicy.id
    }
    ipConfigurations: [
      {
        name: 'transitconfig'
        properties: {
          publicIPAddress: {
            id: fwMainPip.id
          }
          subnet: {
            id: hubVnet::hubSubnet1.id
          }
        }
      }
    ]
    managementIpConfiguration: {
      name: 'mgmtconfig'
      properties: {
        publicIPAddress: {
          id: fwManagementPip.id
        }
        subnet: {
          id: hubVnet::hubSubnet2.id
        }
      }
    }
    sku: {
      name: 'AZFW_VNet'
      tier: 'Basic'
    }
    threatIntelMode: 'Alert'
  }
}

resource windowsNic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: '${vmName}-NIC'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${vmName}NicConfig1'
        properties: {
          subnet: {
            id: spokeVnet::spokeSubnet1.id
          }
        }
      }
    ]
  }
}

resource windowsVm 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: vmOsProfile
    storageProfile: {
      imageReference: vmImage
      osDisk: vmOsDisk
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: windowsNic.id
        }
      ]
    }
  }
}
