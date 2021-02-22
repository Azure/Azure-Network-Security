# Mapping Public IPs to Azure Assets - Azure Resource Graph Query Deployment Template
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FCross%2520Product%2FNetSec%2520Queries%2FMapping%2520Public%2520IPs%2520to%2520Azure%2520Assets%2FAzPIPtoAssetQuerydeploy.json)

This Azure Resource Graph query provides details of all public IPs and the assets associated with them in the selected Azure subscriptions.

## How it Works
The query looks for all Public IPs in the subscriptions selected in the Azure Portal and then parses the asset details from the properties of the IP address.

```
Resources
| where type contains 'publicIPAddresses' and isnotempty(properties.ipAddress)
| extend publicipaddress = properties.ipAddress
| extend pipallocationmethod = properties.publicIPAllocationMethod
| extend sku = sku.name
| extend ipConfiguration = parse_json(properties.ipConfiguration.id)
| extend BrkipConfig = split(ipConfiguration, '/')
| extend assetprovider = tostring(BrkipConfig[6])
| extend typeassetassociatedwith = tostring(BrkipConfig[7])
| extend nameassetassociatedwith = tostring(BrkipConfig[8])
| extend dnsname = parse_json(properties.dnsSettings.fqdn)
| project id, name, publicipaddress, pipallocationmethod, dnsname, typeassetassociatedwith, nameassetassociatedwith, tenantId, kind, location, resourceGroup, subscriptionId, managedBy, sku, plan, properties, tags, identity, zones
```

Different asset types that can have a public IP in Azure - VM NIC, Azure Firewall, VPN gateways, load balancers, Application Gateway and Bastion Host.

Azure Resource Graph Overview - https://docs.microsoft.com/en-us/azure/governance/resource-graph/overview

Public IP addresses (in Azure) - https://docs.microsoft.com/en-us/azure/virtual-network/public-ip-addresses

## Contributing
This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the Microsoft Open Source Code of Conduct. For more information see the Code of Conduct FAQ or contact opencode@microsoft.com with any additional questions or comments.
