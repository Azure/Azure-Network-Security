# Azure Network Security Lab Environment Deployment Template with Azure Premium Firewall

This ARM deployment includes everything needed to test Azure Network Security components including the new Azure Firewall Premium. If you are looking to test out a migration, please use the [old lab](https://github.com/Azure/Azure-Network-Security/tree/master/Lab%20Templates/Lab%20Template%20-%20NetSec%20Demo%20Lab-Standard) with Azure firewall standard.


[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FLab%2520Templates%2FLab%2520Template%2520-%2520NetSec%2520Demo%2520Lab%2FAzNetSecdeploy.json)  


## Step-by-step documentation:
If you'd like more detailed step-by-step instructions on how to deploy this lab, visit our Tech Community [blog post](https://aka.ms/labdeploy-techcommunity) created for the older lab and then use the new lab template at deployment

## PowerShell Deployment Example:

Please use this location as a reference on how this powershell commandlet works: https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-powershell#deploy-remote-template  

*There are 6 parameters with defaults*
* DefaultUserName
* DefaultPassword
* DiagnosticsWorkspaceName
* DiagnosticsWorkspaceSubscription - enter the Subscription ID where your Workspace is in
* DiagnosticsWorkspaceResourceGroup
* DDOSProtectionConfiguration (bool) - true by default  


*Adding some `samples` to give context*
- Subscription ID : "12345678-1234-1234-1234-b826eef6c592"
- Log Analyitcs Workspace name: "TestWorkspace"
- Resource Group Log Analytics workspace is in: "TestResourceGroup"  

**Example Powershell command with some parameters configured:**  
```New-AzResourceGroupDeployment -ResourceGroupName DeleteMe1 -TemplateUri https://raw.githubusercontent.com/Azure/Azure-Network-Security/master/Lab%20Templates/Lab%20Template%20-%20NetSec%20Demo%20Lab/AzNetSecdeploy.json -DiagnosticsWorkspaceName "TestWorkspace" -DiagnosticsWorkspaceSubscription "12345678-1234-1234-1234-b826eef6c592" -DiagnosticsWorkspaceResourceGroup "TestResourceGroup" -DDOSProtectionConfiguration $true```  


# Example Proof of Concept Scenarios designed for this lab  

- Network segmentation using Azure Firewall with Frontdoor and App Gateway plus Virtual Machines and Web App
- Azure Frontdoor and Azure Gateway plus WebApp scenarios
- WAF attack demo with App Gateway plus Webapp deployment
- Azure Firewall with Bastion and Windows Virtual Desktop deployment.
- Azure Premium Firewall for intermediate Certificate Authority
- Web Categories settings using Azure Firewall premium
- Network Security Integration with Azure Security Center and Azure Sentinel
- Rule Processing Logic
- DDOS response to volumetric attack in a controlled environment.  
For more information on POC scenarios, visit our [TechCommunity blog](https://techcommunity.microsoft.com/t5/azure-network-security/azure-network-security-demo-lab-environment-with-new-updates-v2/ba-p/2892204) 

## What is included with the AzNetSec Deployment Template  

| Resource |  Purpose |
|----------|---------|
| Virtual Network-1 |  VN1(Hub) has 2 Subnets 10.0.25.0/26 & 10.0.25.64/26 peered to VN1 and VN2 (Enabled with DDoSProtection)|
| Virtual Network-2 |  VN2(Spoke1) has 2 Subnets 10.0.27.0/26 & 10.0.27.64/26 peered to VN2 |
| Virtual Network-3 |  VN3(Spoke2) has 2 Subnets 10.0.28.0/26 & 10.0.28.64/26 peered to VN1 |
| PublicIPAddress-1 |  Static Public IP address for Application gateway |
| PublicIPAddress-2 |  Static Public IP address for Azure firewall |
| Virtual Machine-1 | Windows 10 Machine connected to VN2(subnet1) |
| Virtual Machine-2 | Kali Linux Box connected to VN2(subnet2) |
| Virtual Machine-3 | Server 2019 Machine connected to VN3(subnet1) |
| Network Security Group-1 | Pre-configured NSG to Virtual Networks associated to VN2 subnets |
| Network Security Group-2 | Pre-configured NSG to Virtual Networks associated to VN3 subnets |
| Route Table | Pre-configured RT Associated to VN2 and VN3 subnets with default route pointing to Azure firewall private IP address |
| Application Gateway v2 (WAF) | Pre-configured to publish webapp on HTTP on Public Interface|
| Azure Firewall Premium with Firewall Manager | Pre-configured with RDP(DNAT) rules to 3 VM's and allow search engine access(application rules) from VM's. Network rule configured to allow SMB, RDP and SSH access between VM's. Azure firewall is deployed in Hub Virtual Network managed by Firewall manager |
| Frontdoor | Pre-configured designer with Backend pool as Applicaion gateway public interface  |
| WebApp(PaaS) | Pre-configured app for Frontdoor and Application Gateway WAF testing |  


> This build has diagnostic settings enabled by default; it requires a Log Analytics workspace for logs to be collected. https://docs.microsoft.com/en-us/azure/azure-monitor/learn/quick-create-workspace  

<p align="center">
<img src="https://github.com/Azure/Azure-Network-Security/blob/master/Cross%20Product/MediaFiles/Cross-Product/demo_image.png">
</p>

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


