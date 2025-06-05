# Azure Network Security Labs

## Introduction

👋 **Hi! Welcome to the Azure Network Security Labs.**

Our labs project will help you get ramped up with Azure Network Security and provide hands-on practical experience for product features, capabilities, and scenarios. The labs are divided into 4 main tracks, being one track for each of the following products: Azure DDoS, Azure Firewall, Azure Application Gateway WAF and Azure Frontdoor WAF. The labs contain multiple scenarios covering features that will help you learn how to use and implement them in your own environment. We continually update the content to include the latest capabilities – please feel free to [submit issue](https://github.com/Azure/Azure-Network-Security/issues/new/choose) for any changes and suggestions.

We also recommend you checking out our [Azure Network Security Ninja Training](https://aka.ms/aznetsecninja). This training covers basic to advanced scenarios for Azure network security. Ready to become an Azure NetSec ninja? Dive right in!

![Ninja-Cat-Logo-2](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/Images/ninja-cat-logo-2.png)

## Objectives

This project is designed to be an immersive and collaborative experience focused on harnessing the power of Azure DDoS, Azure Firewall and Azure Web Application Firewall to improve security measures.

## Acknowledgements

We would like to extend our gratitude to the following teams for their invaluable contributions to the content of this lab:
  - Azure Network Security CxE CAT
  - Azure DDoS PM
  - Azure Firewall PM
  - Azure Web Application Firewall PM

## Information

These labs are a subset of the demos used by our internal teams to demonstrate the features available in our products.

## Requirements

You must own or have access to an Azure subscription where you will deploy the resources used in this Workshop. While we strive to keep the materials updated, we cannot guarantee their accuracy at all times.

**User, passwords and other useful resources**

Please note that all passwords must be provided at the time of deploying the ARM (Azure Resource Manager) template. We are not pre-defining passwords in the template to prevent potential security risks associated with hardcoded credentials. By requiring passwords to be entered during deployment, we ensure that each deployment uses unique and secure passwords, reducing the risk of unauthorized access and enhancing the overall security of our infrastructure. This approach also aligns with best practices for managing sensitive information, ensuring that passwords are not exposed or stored in an insecure manner.

## Before you Start

To start practicing your skills in Azure Network Security, including exploring Azure DDoS, Azure Firewall, and Azure Web Application Firewall, you will need to deploy the proposed environment using the **Deploy to Azure** button below.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Frefs%2Fheads%2Fmaster%2FAzure%2520Network%2520Security%2520-%2520Workshop%2FTemplates%2Flabdeployment.json)

Once the deployment is complete, you need to run the following PowerShell command on each of the four Windows virtual machines deployed. This PowerShell command will disable the Windows Firewall profiles, allowing you to practice the scenarios successfully.

```powershell
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
```

Use the following documentation to learn how to run the PowerShell command by using Azure Portal: https://learn.microsoft.com/en-us/azure/virtual-machines/windows/run-command

## Modules

- [Module 1 - Azure Firewall](https://github.com/Azure/Azure-Network-Security/tree/master/Azure%20Network%20Security%20-%20Workshop/Azure%20Firewall.md)
- [Module 2 - Azure Application Gateway WAF](https://github.com/Azure/Azure-Network-Security/tree/master/Azure%20Network%20Security%20-%20Workshop/Azure%20Application%20Gateway%20WAF.md)
- [Module 3 - Azure Front Door WAF](https://github.com/Azure/Azure-Network-Security/tree/master/Azure%20Network%20Security%20-%20Workshop/Azure%20Front%20Door%20WAF.md)
- [Module 4 - Azure DDoS Protection](https://github.com/Azure/Azure-Network-Security/tree/master/Azure%20Network%20Security%20-%20Workshop/Azure%20DDoS%20Protection.md)

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.
