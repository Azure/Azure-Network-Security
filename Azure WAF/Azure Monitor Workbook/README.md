# Azure Monitor Workbook for WAF

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520WAF%2FAzure%2520Monitor%2520Workbook%2FWAFWorkbook_ARM.json)

This workbook visualizes security-relevant WAF events across several filterable panels. It works with all WAF types, including Application Gateway, Front Door, and CDN, and can be filtered based on WAF type or a specific WAF instance. Import via ARM Template or Gallery Template.

When deploying via ARM Template, please make sure you know what Resource ID (Log Analytics Workgroup) you're wanting to use.

>Example of a value: /subscriptions/'GUID'/resourcegroups/'RG Name'/providers/microsoft.operationalinsights/workspaces/'Workspace Name'

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
