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
var customRules = [
  {
    name: 'CustomRule1'
    priority: 10
    ruleType: 'MatchRule'
    action: 'Block'
    state: 'Enabled'
    matchConditions: [
      {
        matchVariables: [
          {
            variableName: 'RequestHeaders'
            selector: 'User-Agent'
          }
        ]
        operator: 'Equal'
        negationConditon: false
        matchValues: [
          'PostmanRuntime/7.32.3'
        ]
        transforms: []
      }
      {
        matchVariables: [
          {
            variableName: 'RequestCookies'
            selector: 'Cookie_1'
          }
        ]
        operator: 'Contains'
        negationConditon: false
        matchValues: [
          'my!@#$%^&Cookie'
        ]
        transforms: []
      }
      {
        matchVariables: [
          {
            variableName: 'PostArgs'
            selector: 'comment'
          }
        ]
        operator: 'Contains'
        negationConditon: false
        matchValues: [
          'x-javascript&colon'
        ]
        transforms: []
      }
    ]
  }
]
var coreRuleSets = {
    ruleSetType: 'OWASP'
    ruleSetVersion: '3.2'
}
var botRuleSets = {
    ruleSetType: 'Microsoft_BotManagerRuleSet'
    ruleSetVersion: '1.0'
}
var logScrubRule1 = {
  matchVariable: 'RequestHeaderNames'
  selectorMatchOperator: 'Equals'
  selector: 'User-Agent'
  state: 'Enabled'
}
var logScrubRule2 = {
  matchVariable: 'RequestCookieNames'
  selectorMatchOperator: 'Equals'
  selector: 'Cookie_1'
  state: 'Enabled'
}
var logScrubRule3 = {
  matchVariable: 'RequestArgNames'
  selectorMatchOperator: 'Equals'
  selector: 'page'
  state: 'Enabled'
}
var logScrubRule4 = {
  matchVariable: 'RequestPostArgNames'
  selectorMatchOperator: 'Equals'
  selector: 'comment'
  state: 'Enabled'
}
var logScrubRule5 = {
  matchVariable: 'RequestJSONArgNames'
  selectorMatchOperator: 'Equals'
  selector: 'password'
  state: 'Enabled'
}
var logScrubRule6 = {
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
    customRules: customRules
    managedRules: {
      managedRuleSets: [
        coreRuleSets
        botRuleSets
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
          logScrubRule2
          logScrubRule3
          logScrubRule4
          logScrubRule5
          logScrubRule6
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
