# Azure Network Security Cross-Product deployment
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://raw.githubusercontent.com/Azure/Azure-Network-Security/master/Cross%20Product/AzNetSecdeploy.json)

## What is included with the AzNetSec Deployment Template

| Resource |  Purpose |
|----------|---------|
| Virtual Network-1 |  VN1 has 2 Subnets 10.0.25.0/24 & 10.0.25.64/24 (Enabled with DDoSProtection)|
| Virtual Network-2 |  VN2 has 2 Subnets 10.0.27.0/24 & 10.0.27.64/24 |
| Virtual Network-3 |  VN3 has 2 Subnets 10.0.28.0/24 & 10.0.28.64/24 |
| PublicIPAddress-1 |  Static Public IP address |
| PublicIPAddress-2 |  Static Public IP address |
| Virtual Machine-1 | Windows 10 Machine |
| Virtual Machine-2 | Kali Linux Box |
| Virtual Machine-3 | Server 2019 Machine |
| Network Security Group-1 | Pre-configured NSG to Virtual Networks |
| Network Security Group-2 | Pre-configured NSG to Virtual Networks |
| Route Table | Pre-configured RT to Virtual Network Subnets |
| Application Gateway (WAF) | Pre-configured |
| Firewall | Pre-configured |
| Frontdoor | Pre-configured to webserver |
| ServerFarm | Pre-configured live site for Frontdoor testing |

> This build has diagnostic settings enabled by default; it requires a Log Analytics workspace for logs to be collected. https://docs.microsoft.com/en-us/azure/azure-monitor/learn/quick-create-workspace





## Cross Product Samples

Samples in this folder apply to multiple Azure Network Security products.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
