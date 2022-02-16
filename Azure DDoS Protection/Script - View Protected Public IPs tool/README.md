# AzDDOS-IPTool

## Prerequisites
* Current Version of [Azure Powershell](https://docs.microsoft.com/en-us/powershell/azure/install-az-p)
* User running script must be logged into Azure Powershell with the appropriate RBAC permissions to view/list Public IP Addresses and Virtual Networks

## How To Run

From a local PowerShell session or [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview) run the PowerShell command below - 

`Invoke-Expression $(Invoke-WebRequest -uri aka.ms/aznetsecddosip-ps -UseBasicParsing).Content`

or the shorthand version -

`iwr -useb aka.ms/aznetsecddosip-ps | iex`

To download a local copy of the latest version of the script run the command below - 

`Invoke-WebRequest -Uri aka.ms/aznetsecddosip-ps -OutFile Get-AzDDOSProtectedIPs.ps1`


## Output
This script will generate a CSV file containing the following information for each Public IP Address that is visible to the user running the script 

| Column Name           | Description                                                                                           |
|---------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| PIP_Name            | Name of the Azure Public IP Address resource   
| PIP_Address         | Public IP Address currently assigned to the Public IP Address resource                                                                 |
| PIP_Subscription    | Azure Subscription GUID for where the Public IP Address resource was found                                                             |
| Resource_Group      | Name of the Azure Resource Group that contains the Public IP Address                              |
| Associated_Resource | Name of the Azure resource associated with the Public IP Address |
| Resource_Type       | Type of resource associated with the Public IP Address                                                                         |
| Associated_Resource_RG       | Name of the Azure Resource Group that contains the associated resource                                                                         |
| VNet                | Name of the Azure Virtual Network that the Public IP Address and its associated resource are connected                               |
| DDOS_Enabled        | True or False value if Azure DDOS is enabled on the Virtual Network containing the Public IP Address and its associated resource |
| DDOS_Plan           | Name of the DDOS Plan applied to the Azure Virtual Network                                                                          |

## Things To Note

* If the associated resource can not be determined, the script will output "Associated resource type not found for sample-PIP", and the CSV file will populate the appropriate columns with "Unable_To_Determine"
* If the associated resource is an Azure Load Balancer that is not configured with a backend, the CSV will populate the VNet column with "Invalid_Subnet_ID"

## Known Issues 
* This script has not been tested to parse Public IP Addresses that are associated with an ExpressRoute Gateway