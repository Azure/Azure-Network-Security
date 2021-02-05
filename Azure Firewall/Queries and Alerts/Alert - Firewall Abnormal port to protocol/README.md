## Abnormal port to protocol

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520Firewall%2FQueries%2520and%2520Alerts%2FAbnormal%2520port%2520to%2520protocol%2FAbnormalPortToProtocol.json)

### Scope
This alert can indicate malicious communication (C2) or exfiltration by attackers trying to communicate over known ports (22:SSH, 80:HTTP) but don’t use the known protocol headers to match the port number.

### How it works
The alert searches for abnormal protocol on port based on learning period activity

Configurable Parameters:
- Learning period time - learning period for protocol learning in days. Default is set to 7.

```
let LearningPeriod = 7d;
let RunTime = 1d;
let StartLearningPeriod = LearningPeriod + RunTime;
let EndRunTime = RunTime - 1d;
let LearningPortToProtocol = (AzureDiagnostics
| where OperationName == "AzureFirewallApplicationRuleLog"
| parse msg_s with protocol " request from " srcip ":" srcport " to " dsturl ":" dstport "." *
| where isnotempty(dstport)
| where TimeGenerated between (ago(StartLearningPeriod) .. ago(RunTime))
| summarize LearningTimeCount = count() by LearningTimeDstPort = dstport, LearningTimeProtocol = protocol);
let AlertTimePortToProtocol = (AzureDiagnostics
| where OperationName == "AzureFirewallApplicationRuleLog"
| parse msg_s with protocol " request from " srcip ":" srcport " to " dsturl ":" dstport "." *
| where isnotempty(dstport)
| where TimeGenerated between (ago(RunTime) .. ago(EndRunTime))
| summarize AlertTimeCount = count() by AlertTimeDstPort = dstport, AlertTimeProtocol = protocol);
AlertTimePortToProtocol 
| join kind=leftouter (LearningPortToProtocol) on $left.AlertTimeDstPort == $right.LearningTimeDstPort
| where LearningTimeProtocol != AlertTimeProtocol
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
