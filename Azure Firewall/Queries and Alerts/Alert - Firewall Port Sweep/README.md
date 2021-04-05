## Port sweep

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520Firewall%2FQueries%2520and%2520Alerts%2FPort%2520Sweep%2FPortSweep.json)

### Scope
This alert can indicate malicious scanning of port by an attacker, trying to reveal machines with specific ports open in the organization. The ports can be compromised by attackers for initial access, most often by exploiting vulnerability.

### How it works
The alert searches for source IP scanning the same port on multiple hosts.

Configurable Parameters:
- Port sweep time - the time range to look for multiple hosts scanned. Default is set to 30 seconds.
- Minimum different hosts threshold - alert only if more than this number of hosts scanned. Default is set to 200.

```
let RunTime = 1h;
let StartRunTime = 1d;
let EndRunTime = StartRunTime - RunTime;
let MinimumDifferentHostsThreashold = 200;
let ExcludedPorts = dynamic([80, 443]);
let BinTime = 30s;
AzureDiagnostics
| where TimeGenerated  between (ago(StartRunTime) .. ago(EndRunTime))
| where OperationName == "AzureFirewallApplicationRuleLog" or OperationName == "AzureFirewallNetworkRuleLog"
| parse msg_s with * "from " srcip ":" srcport " to " dsturl ":" dstport
| where dstport !in (ExcludedPorts)
| where isnotempty(dsturl) and isnotempty(srcip) and isnotempty(dstport)
| summarize AlertTimedCountHostsInBinTime = dcount(dsturl) by srcip, bin(TimeGenerated, BinTime), dstport
| where AlertTimedCountHostsInBinTime > MinimumDifferentHostsThreashold
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
