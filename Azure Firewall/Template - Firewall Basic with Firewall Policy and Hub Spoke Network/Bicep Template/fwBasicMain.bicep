targetScope = 'subscription'

@description('The Azure region into which the resources should be deployed.')
param location string

@description('Username for the Windows 11 VM.')
@secure()
param win11Username string

@description('Password for the Windows 11 VM.')
@secure()
param win11Password string

var rgName = 'AzureFW-Basic'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

module fwBasicResources 'modules/fwBasicTemplate.bicep' = {
  name: 'fwBasicResources'
  scope: rg
  params: {
    location: location
    win11Username: win11Username
    win11Password: win11Password
  }
}
