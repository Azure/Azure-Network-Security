# Listing Ports Allowed on Load Balancers - Azure Resource Graph Query Deployment Template
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FCross%2520Product%2FNetSec%2520Queries%2FListing%2520Ports%2520Allowed%2520and%2520Denied%2520on%2520NSGs%2FPortsonNSGsQueryDeploy.json)

This Azure Resource Graph query provides details of all ports allowed with load balancing and inbound NAT rules on Azure Load Balancers in the selected Azure subscriptions.

## How it Works
The query looks for all Azure Load Balancers in the subscriptions selected in the Azure Portal and then parses the load balancing and inbound NAT rule details from the properties of the associated load balancers.

```
Resources
| where type contains 'microsoft.network/loadbalancers'
| extend loadBalancingRules = properties.loadBalancingRules
| extend NatRules = properties.inboundNatRules
| extend frontendIPConfig = properties.frontendIPConfigurations
| mv-expand bagexpansion=array loadBalancingRules, NatRules
//| extend LBfrontendIP = loadBalancingRules.properties.frontendIPConfiguration.id
| extend LBrulename = loadBalancingRules.name
| extend LBruleprotocol = loadBalancingRules.properties.protocol
| extend LBrulefrontendPort = loadBalancingRules.properties.frontendPort
| extend LBrulebackendPort = loadBalancingRules.properties.backendPort
| extend LBrulebackendPool = loadBalancingRules.properties.backendAddressPool.id
//| extend NATfrontendIP = NatRules.properties.frontendIPConfiguration.id
| extend Natrulename = NatRules.name
| extend Natruleprotocol = NatRules.properties.protocol
| extend NatrulefrontendPort = NatRules.properties.frontendPort
| extend NatrulebackendPort = NatRules.properties.backendPort
| extend NatrulebackendConfig = NatRules.properties.backendIPConfiguration.id
| extend frontendIPConfig = properties.frontendIPConfigurations
| mv-expand bagexpansion=array frontendIPConfig
| extend frontendIPAllocation = frontendIPConfig.properties.privateIPAllocationMethod
//| extend privateIPVersion = frontendIPConfig.properties.privateIPAddressVersion
| extend frontendprivateIPAddress = frontendIPConfig.properties.privateIPAddress
| extend frontendpublicIPResource = tostring(frontendIPConfig.properties.publicIPAddress.id)
| join ( Resources | where type=='microsoft.network/publicipaddresses' | extend frontendPublicIPAddress=properties.ipAddress | project frontendpublicIPResource=id,frontendPublicIPAddress ) on frontendpublicIPResource
| project-away kind, managedBy, apiVersion, aliases, identity, zones, frontendpublicIPResource, frontendpublicIPResource1
```

Tip: By default, the query shows association of the Load Balancer frontend Public IPs with the port details of load balancing and inbound NAT rules.  In order to see the association of Load Balancer Private IP (for internal load balancers) with the port details of load balancing and inbound NAT rules, you can comment out the join statement.

Azure Resource Graph Overview - https://docs.microsoft.com/en-us/azure/governance/resource-graph/overview

Network Security Group (NSG) Overview - https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview 

## Contributing
This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the Microsoft Open Source Code of Conduct. For more information see the Code of Conduct FAQ or contact opencode@microsoft.com with any additional questions or comments.
