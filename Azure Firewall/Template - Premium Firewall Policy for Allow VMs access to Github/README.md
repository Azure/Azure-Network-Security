# GitHub Repo Firewall Policy Sample
Author: Nathan Swift

This GitHub Firewall policy template can be deployed and used with Azure Firewall Premium to allow VMs to access GitHub functionality and only certain GitHub Repos you want to grant

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%20Firewall%2FTemplate%20-%20Premium%20Firewall%20Policy%20for%20Allow%20VMs%20access%20to%20Github%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%20Firewall%2FTemplate%20-%20Premium%20Firewall%20Policy%20for%20Allow%20VMs%20access%20to%20Github%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

## Prerequisites

[Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-portal)  
[KeyVault and Azure Firewall CA Cert](https://docs.microsoft.com/en-us/azure/firewall/premium-certificates)    
[User Assigned Identity with Access to CA Cert Secret in KeyVault](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-portal#create-a-user-assigned-managed-identity)