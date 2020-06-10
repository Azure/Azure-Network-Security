## Multiple sources affected by the same TI destination

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520Firewall%2FQueries%2520and%2520Alerts%2FMultiple%2520source%2520affected%2520by%2520the%2520same%2520TI%2520destination%2FMultipleSourceSameTI.json)

### Scope
This alert can indicate attack on the organization by the same attack group.

### How it works
The alert searches for multiple hosts affected by the same TI (Threat Intelligence) indicator.

Configurable Parameters:
- Minimum affected threshold - alert only if more than this number of hosts affected. Default is set to 5.

```
let RunTime = 1h;
let StartRunTime = 1d;
let EndRunTime = StartRunTime - RunTime;
let MinimumDifferentPortsThreashold = 100;
let BinTime = 30s;
AzureDiagnostics
| where TimeGenerated  between (ago(StartRunTime) .. ago(EndRunTime))
| where OperationName == "AzureFirewallApplicationRuleLog" or OperationName == "AzureFirewallNetworkRuleLog"
| parse msg_s with * "from " srcip ":" srcport " to " dsturl ":" dstport
| where isnotempty(dsturl) and isnotempty(srcip)
| summarize AlertTimedCountPortsInBinTime = dcount(dstport) by srcip, bin(TimeGenerated, BinTime)
| where AlertTimedCountPortsInBinTime > MinimumDifferentPortsThreashold
```

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
