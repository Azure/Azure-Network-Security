## Abnormal deny rate for source IP

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520Firewall%2FQueries%2520and%2520Alerts%2FAbnormal%2520deny%2520rate%2520for%2520source%2520ip%2FAbnormalDenyRate.json)

### Scope
This alert can provide indication of potential exfiltration, initial access or C2, where attacker tries to exploit the same vulnerability on machines in the organization, but is being blocked by firewall rules.

### How it works
The alert searches for an abnormal deny rate for source IP to destination IP based on the normal average and standard deviation learned during a configured period.

Configurable Parameters:
- Minimum of stds threshold - the number of stds to use in the threshold calculation. Default is set to 3.
- Learning period time - learning period for threshold calculation in days. Default is set to 5.
- Bin time - learning buckets time in hours. Default is set to 1 hour.
- Minimum threshold - minimum threshold for alert. Default is set to 5.
- Minimum bucket threshold - minimum learning buckets threshold for alert. Default is set to 5.

```
let LearningPeriod = 5d;
let RunTime = 1h;
let StartLearningPeriod = LearningPeriod + RunTime;
let EndRunTime = RunTime - 1d;
let BinTime = 1h;
let NumOfStdsThreshold = 3;
let MinThreshold = 5.0;
let MinLearningBuckets = 5;
let TrafficLogs = (AzureDiagnostics
| where TimeGenerated  between (ago(StartLearningPeriod) .. ago(EndRunTime))
| where OperationName == "AzureFirewallApplicationRuleLog" or OperationName == "AzureFirewallNetworkRuleLog"
| parse msg_s with * "from " srcip ":" srcport " to " dsturl ":" dstport ". Action: " action "." *
| where action == "Deny"
| where isnotempty(dsturl) and isnotempty(srcip));
let LearningSrcIpDenyRate = (TrafficLogs
| where TimeGenerated between (ago(StartLearningPeriod) .. ago(RunTime))
| summarize count() by srcip, bin(TimeGenerated, BinTime)
| summarize LearningTimeSrcIpDenyRateAvg = avg(count_), LearningTimeSrcIpDenyRateStd = stdev(count_), LearningTimeBuckets = count() by srcip
| where LearningTimeBuckets > MinLearningBuckets);
let AlertTimeSrcIpDenyRate = (TrafficLogs
| where TimeGenerated between (ago(RunTime) .. ago(EndRunTime))
| summarize AlertTimeSrcIpDenyRateCount = count() by srcip);
AlertTimeSrcIpDenyRate
| join kind=leftouter (LearningSrcIpDenyRate) on srcip
| extend LreaningThreshold = max_of(LearningTimeSrcIpDenyRateAvg + NumOfStdsThreshold * LearningTimeSrcIpDenyRateStd, MinThreshold)
| where AlertTimeSrcIpDenyRateCount > LreaningThreshold
| project-away srcip1, LearningTimeSrcIpDenyRateAvg, LearningTimeSrcIpDenyRateStd
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
