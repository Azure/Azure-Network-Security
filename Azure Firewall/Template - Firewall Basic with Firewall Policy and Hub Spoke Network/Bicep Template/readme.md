# Firewall Basic SKU Bicep template
This Bicep deployment includes everything needed to quickly deploy and test Azure Firewall's Basic SKU. 

## Pre-requisites:
Install Bicep tools to author and deploy Bicep templates into your environment. To learn more, go to: [Install Bicep Tools](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)

The recommended Bicep editor is Visual Studio Code using the Bicep extension.

## Resources deployed by the main template:
| Resource | Name |
|----------|------|
| Resource Group |  AzureFW-Basic |
| Module |  fwBasicMainTemplate.bicep |

## Resources deployed by the module template:
| Resource | Name |
|----------|------|
| VNet |  HubVnet |
| VNet |  SpokeVnet1 |
| Route Table |  Spoke1RT |
| Firewall Policy |  FWBasicPolicy |
| Firewall Policy Rule Collection Group |  FwBasicLabRcg (1x NAT Rule Collection, 1x Network Rule Collection, 1x Application Rule Collection) |
| Public IP |  FWBasicTransitIP |
| Public IP |  FWBasicManagementIP |
| Firewall |  FWBasic |
| Network Interface Card |  AppVm1-NIC |
| OS Disk |  |
| VM |  AppVm1 (Windows) |

* Note: If you use the visualizer in Visual Studio Code, you'll see additional resources defined, such as virtual network peerings and sub-resources like subnets. These resources do not deploy as an actual resource type in Azure but are necessary to be defined in the template.*