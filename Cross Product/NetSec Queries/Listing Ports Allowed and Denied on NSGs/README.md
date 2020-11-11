# Listing Ports Allowed and Denied with User Defined Rules on NSGs - Azure Resource Graph Query Deployment Template
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FCross%2520Product%2FNetSec%2520Queries%2FListing%2520Ports%2520Allowed%2520and%2520Denied%2520on%2520NSGs%2FPortsonNSGsQueryDeploy.json)

This Azure Resource Graph query provides details of all ports allowed or denied with user defined inbound and outbound security rules on NSGs in the selected Azure subscriptions. The query does not provide details of ports allowed or denied with the default inbound and outbound security rules on the NSGs.

## How it Works
The query looks for all Network Security Groups (NSGs) in the subscriptions selected in the Azure Portal and then parses the security rule details from the properties of the associated Network Interfaces. 

```
Resources
| where type contains 'microsoft.network/Networksecuritygroups'
| extend nic = properties.networkInterfaces
| mv-expand bagexpansion=array nic
| extend udrulenicid = nic.id
| extend udrulesubnetids = properties.subnets
| extend udrules = properties.securityRules
| mv-expand bagexpansion=array udrules
| extend udrulename = udrules.name
| extend udruleprotocol = udrules.properties.protocol
| extend udruledestinationport = udrules.properties.destinationPortRange
| extend udruledestinationportlist = udrules.properties.destinationPortRanges
| extend udruledirection = udrules.properties.direction
| extend udrulesourcenetwork = udrules.properties.sourceAddressPrefix
| extend udruledestinationnetwork = udrules.properties.destinationAddressPrefix
| extend udruleaccess = udrules.properties.access
| project-away udrules, kind, managedBy, nic, identity, zones
```

Azure Resource Graph Overview - https://docs.microsoft.com/en-us/azure/governance/resource-graph/overview

Network Security Group (NSG) Overview - https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview 

## Contributing
This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the Microsoft Open Source Code of Conduct. For more information see the Code of Conduct FAQ or contact opencode@microsoft.com with any additional questions or comments.
