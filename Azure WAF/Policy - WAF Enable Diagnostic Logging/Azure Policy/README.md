# Enable Diagnostic Logs - Azure Policy

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520WAF%2FEnable%2520Diagnostic%2520Logging%2FAzure%2520Policy%2FWAFLogs-AppGateway.json) (Azure WAF on Application Gateway)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520WAF%2FEnable%2520Diagnostic%2520Logging%2FAzure%2520Policy%2FWAFLogs-FrontDoor.json) (Azure WAF on Front Door)

This template will create an Azure Policy definition to enable diagnostic logging. The result of the policy is deployIfNotExists, and a remediation task will create a diagnostic setting for Log Analytics. Follow the procedure below to assign the policy:

1. Using the Deploy to Azure button above, complete a deployment of the definition.
2. Navigate to Policy --> Definitions and locate the new definition (Apply Diagnostic Settings for...)
3. Open the definition and select Assign.
4. On the Basics tab, select the scope and exclusions.
5. On the Parameters tab, create a name for the diagnostic setting, choose a workspace, and select metrics, logs, or both.
6. On the Remediation tab, check the box to Create a remediation task.
7. Review and create the assignment. Any missing diagnostic settings within the scope will be created after evaluation.
8. Check status of evaluation and remediation in the Compliance and Remediation blades.

Note: These policies were created using the scripts from [our friend Jim Britt's repository](https://github.com/JimGBritt/AzurePolicy/tree/master/AzureMonitor/Scripts). It is recommended that these scripts be used to create a policy initiative that enables every type of diagnostic logs in your environment.

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
