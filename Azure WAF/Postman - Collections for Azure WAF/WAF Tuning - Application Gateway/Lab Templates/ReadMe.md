# Azure WAF Tuning - Application Gateway Template
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520WAF%2FPostman%2520-%2520Collections%2520for%2520Azure%2520WAF%2FWAF%2520Tuning%2520-%2520Application%2520Gateway%2FLab%2520Templates%2FAzureWAF-Quick-Tune-AppGW.json)

## What is included:

| Resource Type | Resource Name | Purpose |
|---------------|---------------|---------|
| Virtual Network |  vnet-uniqueString-waf | Virtual Network with a 192.168.0.0/24 address space with 1 subnet with a 192.168.0.0/26 address space. |
| Public IP |  pip-appgw-uniqueString-waf | Static Standard SKU Public IP associated with the Application Gateway. |
| App Service Plan |  asf-uniqueString | Free tier (F1) App Service Plan for Linux OS |
| Web App |  owasp-uniqueString | Web App with OWASP Juice Shop installed. |
| WAF Policy |  waf-appgw-uniqueString | Application Gateway WAF Policy using DRS 2.1 WAF is enabled and set to Prevention mode. Log Scrubbing has been enabled and Client IP rule defined. |
| Application Gateway | appgw-uniqueString-waf | WAF_v2 SKU Application Gateway with settings pre-configured. |
| Log Analytics Workspace | waf-workspace-uniqueString | Pay-as-you-go tier Log Analytics Workspace for ingesting WAF logs from Application Gateway resource. |

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
