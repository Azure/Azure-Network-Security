@description('The Azure region where the resources should be deployed.')
param location string = resourceGroup().location

var frontDoorEndpointName = 'afd-owasp-${uniqueString(resourceGroup().id)}'
var frontDoorProfileName = 'afd-owasp-${uniqueString(resourceGroup().id)}'
var frontDoorOriginGroupName = 'OwaspBackend'
var frontDoorOriginName = 'OwaspJuiceShop'
var frontDoorRouteName = 'MainRoute'
var frontDoorSkuName = 'Premium_AzureFrontDoor'
var frontDoorWafName = 'wafafd${uniqueString(resourceGroup().id)}'
var managedRuleSets = [
  {
    ruleSetAction: 'Block'
    ruleSetType: 'Microsoft_DefaultRuleSet'
    ruleSetVersion: '2.1'
  }
]
var serverFarmName = 'asf-${uniqueString(resourceGroup().id)}'
var webAppName = 'owasp-${uniqueString(resourceGroup().id)}'
var linuxFxVersion = 'DOCKER|bkimminich/juice-shop:latest'
var logAnalyticsWorkspaceName = 'waf-workspace-${uniqueString(resourceGroup().id)}'
var afdDiagnosticName = 'afd-diag'

resource frontDoorProfile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: frontDoorProfileName
  location: 'global'
  sku: {
    name: frontDoorSkuName
  }
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = {
  name: frontDoorEndpointName
  parent: frontDoorProfile
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: frontDoorOriginGroupName
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
  }
}

resource frontDoorOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: frontDoorOriginName
  parent: frontDoorOriginGroup
  properties: {
    hostName: webApp.properties.defaultHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: webApp.properties.defaultHostName
    priority: 1
    weight: 1000
  }
}

resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
  name: frontDoorRouteName
  parent: frontDoorEndpoint
  dependsOn: [
    frontDoorOrigin // This explicit dependency is required to ensure that the origin group is not empty when the route is created.
  ]
  properties: {
    originGroup: {
      id: frontDoorOriginGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
}

resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2021-06-01' = {
  parent: frontDoorProfile
  name: 'sp-${frontDoorProfileName}'
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: frontDoorWaf.id
      }
      associations: [
        {
          domains: [
            {
              id: frontDoorEndpoint.id
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }
      ]
    }
  }
}

resource frontDoorWaf 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2022-05-01' = {
  name: frontDoorWafName
  location: 'global'

  sku: {
    name: frontDoorSkuName
  }
  properties: {
    managedRules: {
      managedRuleSets: managedRuleSets
    }
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention'
      requestBodyCheck: 'Enabled'
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

resource afdDiagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  scope: frontDoorProfile
  name: afdDiagnosticName
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'FrontDoorAccessLog'
        enabled: true
      }
      {
        category: 'FrontDoorHealthProbeLog'
        enabled: true
      }
      {
        category: 'FrontDoorWebApplicationFirewallLog'
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

output appServiceHostName string = webApp.properties.defaultHostName
output frontDoorEndpointHostName string = frontDoorEndpoint.properties.hostName
