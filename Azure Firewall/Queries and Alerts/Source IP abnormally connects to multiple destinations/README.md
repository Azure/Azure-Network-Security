## First Time Source IP to Destination

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520Firewall%2FQueries%2520and%2520Alerts%2FFirst%2520time%2520source%2520ip%2520to%2520destination%2FFirstTimeSrcIpToDst.json)

This alert searches for a source IP that abnormally connects to multiple destinations according to learning period activity.
Configurable Parameters:
- Minimum of stds threashold - the number of stds to use in the threashold calculation. Default set to 3.
- Learning period time - learning period for threashold calculation in days. Default set to 5.
- Bin time - learning buckets time in hours. Default set to 1 hour.
- Minimum threashold - minimum threashold for alert. Default set to 10.
- Minimum bucket threashold - minimum learning buckets threashold for alert. Default set to 5.

```
let LearningPeriod = 5d;
let RunTime = 1h;
let StartLearningPeriod = LearningPeriod + RunTime;
let EndRunTime = RunTime - 1d;
let BinTime = 1h;
let NumOfStdsThreshold = 3;
let MinThreshold = 10.0;
let MinLearningBuckets = 5;
let TrafficLogs = (AzureDiagnostics
| where OperationName == "AzureFirewallApplicationRuleLog" or OperationName == "AzureFirewallNetworkRuleLog"
| parse msg_s with * "from " srcip ":" srcport " to " dsturl ":" dstport "." *
| where isnotempty(dsturl) and isnotempty(srcip));
let LearningSrcIp = (TrafficLogs
| where TimeGenerated between (ago(StartLearningPeriod) .. ago(RunTime))
| summarize dcount(dsturl) by srcip, bin(TimeGenerated, BinTime)
| summarize LearningTimeSrcAvg = avg(dcount_dsturl), LearningTimeSrcStd = stdev(dcount_dsturl), LearningTimeBuckets = count() by srcip
| where LearningTimeBuckets > MinLearningBuckets);
let AlertTimeSrcIp = (TrafficLogs
| where TimeGenerated between (ago(RunTime) .. ago(EndRunTime))
| summarize AlertTimeSrcIpdCount = dcount(dsturl) by srcip);
AlertTimeSrcIp
| join kind=leftouter (LearningSrcIp) on srcip
| extend LreaningThreshold = max_of(LearningTimeSrcAvg + NumOfStdsThreshold * LearningTimeSrcStd, MinThreshold)
| where AlertTimeSrcIpdCount > LreaningThreshold
| project-away srcip1, LearningTimeSrcAvg, LearningTimeSrcStd
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
