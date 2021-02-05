# Azure WAF Attack Testing Lab Environment Deployment Template
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520WAF%2FARM%2520Template%2520-%2520WAF%2520Attack%2520Testing%2520Lab%2FAzNetSecdeploy_Juice-Shop_AZFW-Rules_Updated.json)


This ARM deployment includes everything needed to test Azure WAF Security components.  Below are the differences from the default Azure Network Security deployment template.

- A custom Docker image with a modified version of the OWASP Juice Shop application
- Built-in Azure Firewall rules to allow inbound and outbound connectivity for the Kali VM

**Original Azure Network Security deployment template:**

https://github.com/Azure/Azure-Network-Security/tree/master/Cross%20Product/Network%20Security%20Lab%20Template  

## PowerShell Deployment Example:

Please use this location as a reference how this powershell commandlet works: https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-powershell#deploy-remote-template

There are 6 parameters with defaults
* DefaultUserName
* DefaultPassword
* DiagnosticsWorkspaceName
* DiagnosticsWorkspaceSubscription
* DiagnosticsWorkspaceResourceGroup
* DDOSProtectionConfiguration (bool) - true by default

Adding some `samples` to give context
- SubscriptionID : "12345678-1234-1234-1234-b826eef6c592"
- Log Analyitcs Workspace name: "TestWorkspace"
- Resource Group Log Analytics workspace is in: "TestResourceGroup"

**Example Powershell command with some parameters configured:**
>New-AzResourceGroupDeployment -ResourceGroupName DeleteMe1 -TemplateUri https://raw.githubusercontent.com/Azure/Azure-Network-Security/master/Azure%20WAF/ARM%20Template%20-%20WAF%20Attack%20Testing%20Lab/AzNetSecdeploy_Juice-Shop_AZFW-Rules_Updated.json -DiagnosticsWorkspaceName "TestWorkspace" -DiagnosticsWorkspaceSubscription "12345678-1234-1234-1234-b826eef6c592" -DiagnosticsWorkspaceResourceGroup "TestResourceGroup" -DDOSProtectionConfiguration $true


## What is included with the AzNetSec Deployment Template

| Resource |  Purpose |
|----------|---------|
| Virtual Network-1 |  VN1(Hub) has 2 Subnets 10.0.25.0/24 & 10.0.25.64/24 peered to VN1 and VN2 (Enabled with DDoSProtection)|
| Virtual Network-2 |  VN2(Spoke1) has 2 Subnets 10.0.27.0/24 & 10.0.27.64/24 peered to VN2 |
| Virtual Network-3 |  VN3(Spoke2) has 2 Subnets 10.0.28.0/24 & 10.0.28.64/24 peered to VN1 |
| PublicIPAddress-1 |  Static Public IP address for Application gateway |
| PublicIPAddress-2 |  Static Public IP address for Azure firewall |
| Virtual Machine-1 | Windows 10 Machine connected to VN2(subnet1) |
| Virtual Machine-2 | Kali Linux Box connected to VN2(subnet2) |
| Virtual Machine-3 | Server 2019 Machine connected to VN3(subnet1) |
| Network Security Group-1 | Pre-configured NSG to Virtual Networks associated to VN2 subnets |
| Network Security Group-2 | Pre-configured NSG to Virtual Networks associated to VN3 subnets |
| Route Table | Pre-configured RT Associated to VN2 and VN3 subnets with default route pointing to Azure firewall private IP address |
| Application Gateway v2 (WAF) | Pre-configured to publish webapp on HTTP on Public Interface|
| Azure Firewall with Firewall Manager | Pre-configured with RDP(DNAT) rules to 3 VM's and allow search engine access(application rules) from VM's. Network rule configured to allow SMB, RDP and SSH access between VM's. Azure firewall is deployed in Hub Virtual Network managed by Firewall manager |
| Frontdoor | Pre-configured designer with Backend pool as Applicaion gateway public interface  |
| WebApp(PaaS) | Pre-configured app for Frontdoor and Application Gateway WAF testing |

> This build has diagnostic settings enabled by default; it requires a Log Analytics workspace for logs to be collected. https://docs.microsoft.com/en-us/azure/azure-monitor/learn/quick-create-workspace


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

