# Sample - Azure Firewall with multiple Public IPs from a IP Prefix

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520Firewall%2FSamples%2Fazurefirewall-multiple-public-ips-from-ip-prefix%2Fazuredeploy.json) [![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520Firewall%2FSamples%2Fazurefirewall-multiple-public-ips-from-ip-prefix%2Fazuredeploy.json)

## Overview and deployed resources

This sample deploys a VNet with an AzureFirewallSubnet, a public IP Prefix, an Azure Firewall and multiple Public IPs assigned to the Firewall.

The following resources are part of the solution:

+ **Azure Firewall**
+ **VNET**: A single VNet with an AzureFirewallSubnet
+ **Public IP Prefix**: A Public IP Prefix used to allocated IP addresses for the Azure Firewall
+ **Multiple Public IPs**: Multiple Public IP addresses based on the amount specified during deployment

## Deployment steps

Click the "Deploy to Azure" button at the beginning of this document or deploy the templates through Azure Powershell or CLI.
