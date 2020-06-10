## Uncommon port to IP

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520Firewall%2FQueries%2520and%2520Alerts%2FUncommon%2520port%2520to%2520IP%2FUncommonPortToIp.json)

### Scope
This alert can indicate exfiltration attack or C2 control from machines in the organization by using new a port that has never been used on the machine for communication.

### How it works
The alert searches for abnormal ports used for this IP based on learning period activity.

Configurable Parameters:
- Learning period time - learning period for threshold calculation in days. Default is set to 7.

```
let LearningPeriod = 5d;
let RunTime = 1h;
let StartLearningPeriod = LearningPeriod + RunTime;
let EndRunTime = RunTime - 1d;
let AllowedCommonPorts = dynamic([80, 443]);
let TrafficLogs = (AzureFirewallLogs
| where isnotempty(srcip)
| where operationName == "AzureFirewallApplicationRuleLog" or operationName == "AzureFirewallNetworkRuleLog");
let LearningSrcIp = (TrafficLogs
| where PreciseTimeStamp between (ago(StartLearningPeriod) .. ago(RunTime))
| distinct srcip, dstport);
let AlertTimeSrcIpToPort = (TrafficLogs
| where PreciseTimeStamp between (ago(RunTime) .. ago(EndRunTime))
| distinct srcip ,dstport);
AlertTimeSrcIpToPort
| join kind=leftantisemi (LearningSrcIp) on srcip, dstport
| where dstport !in (AllowedCommonPorts)
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
