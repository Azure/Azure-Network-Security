# WVD Firewall Policy Sample
author: Nathan Swift

This WVD Firewall policy can be deployed and used with Azure Firewall Premium to protect your WVD Host Pools, Rule sets are based on [Azure Docs Here](https://docs.microsoft.com/en-us/azure/firewall/protect-windows-virtual-desktop) and also based on testing.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%20Firewall%2FTemplate%20-%20Premium%20Firewall%20Policy%20for%20WVD%20hostpools%20protect%20with%20AzFW%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%20Firewall%2FTemplate%20-%20Premium%20Firewall%20Policy%20for%20WVD%20hostpools%20protect%20with%20AzFW%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

## Prerequistes

![Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-portal)
![Keyvault and Azure Firewall CACert](https://docs.microsoft.com/en-us/azure/firewall/premium-certificates) 
![User Assigned Identity w/ Access to CACert Secret in Keyvault](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-portal#create-a-user-assigned-managed-identity)

## Arrays

Use the following format for the Array data for WVDServiceBusURLs, WVDBlobURLs, WVDTableURLs, WVDQueueURLs

```["gsmUNIQUESTRINGeh.servicebus.windows.net/*","gsmUNIQUESTRINGeh.servicebus.windows.net/*"]```

<img src="https://github.com/Azure/Azure-Network-Security/blob/main/Azure%20Firewall/Template%20-%20Premium%20Firewall%20Policy%20for%20WVD%20hostpools%20protect%20with%20AzFW/images/urls.png"/>

Use the following format for the Array data for AD_DNSServers

```["xx.xx.xx.xx","yy.yy.yy.yy"]```

<img src="https://github.com/Azure/Azure-Network-Security/blob/main/Azure%20Firewall/Template%20-%20Premium%20Firewall%20Policy%20for%20WVD%20hostpools%20protect%20with%20AzFW/images/addnspic.png"/>

## Post Install

Azure Firewall WVD Policy is a sample as is and should be tested first. Additional rules to use AD Domain Services or Azure AD Domain Services and potentially other rules for Microsoft 365 services, Azure NetApp Files and others that may be appliacable for your WVD Host Pool may need to be added before adopting in production.

Assign WVD Firewall Policy