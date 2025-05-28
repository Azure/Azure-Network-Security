# App GW WAF Monitor - Resource Specific - Workbook 

# WAF Workbook V1 deployment button

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com/Azure/Azure-Network-Security/refs/heads/master/Azure%20WAF/Workbook%20-%20App%20GW%20WAF%20Monitor%20-%20Resource%20Specific/Azure%20App%20GW%20WAF%20Monitor%20Workbook%20-%20Resource%20Specific%20Logs%20-%20ARM.json)

This is a New Monitor Workbook that supports Resource Specific Logs for Application Gateway WAF. This workbook visualizes security-relevant WAF events across several filterable panels. It only works with Application Gateway WAF and can be filtered based on WAF type or a specific WAF instance. Import via ARM Template or Gallery Template.

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
