@description('The Azure region where the resources should be deployed.')
param location string

var appgwVnetName = 'vnet-${uniqueString(resourceGroup().id)}-waf'
var appgwVnetAddress = '192.168.0.0/24'
var appgwVnetSubnet1Name = 'snet-appgw'
var appgwVnetSubnet1Address = '192.168.0.0/26'
var appgwPublicIp = 'pip-appgw-${uniqueString(resourceGroup().id)}-waf'
var appgwPublicIpDomainNameLabel = 'owasp-${uniqueString(resourceGroup().id)}'
var appgwPublicIpSku = {
  name: 'Standard'
  tier: 'Regional'
}
var coreRuleSets = {
    ruleSetType: 'Microsoft_DefaultRuleSet'
    ruleSetVersion: '2.1'
}
var logScrubRule1 = {
  matchVariable: 'RequestIPAddress'
  selectorMatchOperator: 'EqualsAny'
  state: 'Enabled'
}
var serverFarmName = 'asf-${uniqueString(resourceGroup().id)}'
var webAppName = 'owasp-${uniqueString(resourceGroup().id)}'
var linuxFxVersion = 'DOCKER|bkimminich/juice-shop:latest'
var logAnalyticsWorkspaceName = 'waf-workspace-${uniqueString(resourceGroup().id)}'
var appgwName = 'appgw-${uniqueString(resourceGroup().id)}-waf'
var appgwDiagnosticName = 'appgw-diag'

resource appgwVnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: appgwVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        appgwVnetAddress
      ]
    }
  }
  resource appgwSubnet 'subnets' = {
    name: appgwVnetSubnet1Name
    properties: {
      addressPrefix: appgwVnetSubnet1Address
    }
  }
}

resource appgwPip 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: appgwPublicIp
  location: location
  sku: appgwPublicIpSku
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: appgwPublicIpDomainNameLabel
    }
  }
}

resource appgwWaf 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-02-01' = {
  name: 'waf-appgw-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    managedRules: {
      managedRuleSets: [
        coreRuleSets
      ]
    }
    policySettings: {
      state: 'Enabled'
      mode: 'Prevention'
      requestBodyCheck: true
      maxRequestBodySizeInKb: 10
      fileUploadLimitInMb: 100
      logScrubbing: {
        scrubbingRules: [
          logScrubRule1
        ]
        state: 'Enabled'
      }
    }
  }
}

resource appServerFarm 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: serverFarmName
  location: location
  sku: {
    name: 'F1'
  }
  kind: 'app,linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServerFarm.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource appGW 'Microsoft.Network/applicationGateways@2023-02-01' = {
  name: appgwName
  location: location
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appgwVnet::appgwSubnet.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: webApp.properties.defaultHostName
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 120
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 80
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIp'
        properties: {
          publicIPAddress: {
            id: appgwPip.id
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appgwName, 'appGatewayFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appgwName, 'appGatewayFrontendPort')
          }
          protocol: 'Http'
          hostName: appgwPip.properties.dnsSettings.fqdn
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'appGatewayRule'
        properties: {
          priority: 10
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appgwName, 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appgwName, 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appgwName, 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
    firewallPolicy: {
      id: appgwWaf.id
    }
  }
}

resource appGWDiagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  scope: appGW
  name: appgwDiagnosticName
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
