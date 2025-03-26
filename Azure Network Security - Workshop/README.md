# Azure Network Security Workshop

**Hi! Welcome to the Azure Network Security Workshop.**

To start practicing your skills in Azure Network Security, including exploring Azure DDoS, Azure Firewall, and Azure Web Application Firewall, you will need to deploy the proposed environment using the **Deploy to Azure** button below.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520Network%2520Security%2520-%2520Workshop%2FLabs.json)

Once the deployment is complete, you need to run the following PowerShell command on each of the four Windows virtual machines deployed. This PowerShell command will disable the Windows Firewall profiles, allowing you to practice the scenarios successfully.

- Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

Use the following documentation to learn how to run the PowerShell command by using Azure Portal: https://learn.microsoft.com/en-us/azure/virtual-machines/windows/run-command

# Objectives

This Workshop is designed to be an immersive and collaborative experience focused on harnessing the power of Azure DDoS, Azure Firewall and Azure Web Application Firewall to improve security measures.

# Acknowledgements

We would like to extend our gratitude to the following teams for their invaluable contributions to the content of this lab:
  - Azure Network Security CxE CAT
  - Azure DDoS PM
  - Azure Firewall PM
  - Azure Web Application Firewall PM

# Information

This Workshop is a subset of the demos used by our internal teams to demonstrate the features available in our products.

# Requirements

You must own or have access to an Azure subscription where you will deploy the resources used in this Workshop. While we strive to keep the materials updated, we cannot guarantee their accuracy at all times.

**User, passwords and other useful resources**

Please note that all passwords must be provided at the time of deploying the ARM (Azure Resource Manager) template. We are not pre-defining passwords in the template to prevent potential security risks associated with hardcoded credentials. By requiring passwords to be entered during deployment, we ensure that each deployment uses unique and secure passwords, reducing the risk of unauthorized access and enhancing the overall security of our infrastructure. This approach also aligns with best practices for managing sensitive information, ensuring that passwords are not exposed or stored in an insecure manner.

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.
