# Azure Monitor Workbook for Azure Firewall 

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%20Firewall%2FAzure%20Monitor%20Workbook%2FAzure%20Firewall_ARM.json)

Gain insights into Azure Firewall events. You can learn about your application and network rules, see statistics for firewall activities across URLs, ports, and addresses. This workbook allows you to filter your Firewalls and Resource Groups, dynamically filter per category with easy to read data sets when investigating an issue in your logs. Import via ARM Template or Gallery Template.

When deploying via ARM Template, please make sure you know what Resource ID (Log Analytics Workgroup) you're wanting to use.

>Example of a value: /subscriptions/'GUID'/resourcegroups/'RG Name'/providers/microsoft.operationalinsights/workspaces/'Workspace Name'

This workbook visualizes security-relevant Azure Firewall events across several filterable panels for Mutli-Tenant/Workspace view. It works with all Azure Firewall data types, including Application Rule Logs, Network Rule Logs, DNS Proxy logs and ThreatIntel logs. Import via ARM Template or Gallery Template.

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
