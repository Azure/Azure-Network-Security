Create a custom rule and apply it to deny or allow an IP list using Terraform

This Terraform module  will create a custom WAF rule blocking a list of IP's from a CSV file formatted with the CIDR name at the top
It includes a tfvars sample.
Currently, there is a limit on the number of CIDR ranges that can be included (600 per rule). See [here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits) for WAF limits  


For more information: [Deploy an Azure Application Gateway v2 using Terraform to direct web traffic](https://docs.microsoft.com/en-us/azure/developer/terraform/deploy-application-gateway-v2?toc=%2Fazure%2Fapplication-gateway%2Ftoc.json&bc=%2Fazure%2Fapplication-gateway%2Fbreadcrumb%2Ftoc.json)
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
