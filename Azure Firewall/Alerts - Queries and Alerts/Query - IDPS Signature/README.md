# Query for IDPS Signatures in Network Firewall Logs

Azure Firewall Premium brings IDPS capabilities including logging IDPS Signatures when an alert or deny occurs due to IDPS.

## How it Works
Use this query to discover the Signature which can be used to bypass the default behaviour of IDPS per Signature.

```
AzureDiagnostics
| where TimeGenerated >= ago(15m)
| where Category == "AzureFirewallNetworkRule"
| where OperationName == "AzureFirewallIDSLog"
| parse msg_s with * "TCP request from " Source " to " Destination ". Action: " ActionTaken ". Rule: " IDPSSig ". IDS: " IDSMessage ". Priority: " Priority ". Classification: " Classification
| project TimeGenerated, Source, Destination, ActionTaken, IDPSSig, IDSMessage, Priority, Classification
```

[See more information on IDPS Testing](https://docs.microsoft.com/en-us/azure/firewall/premium-deploy#idps-tests)

## Contributing
This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the Microsoft Open Source Code of Conduct. For more information see the Code of Conduct FAQ or contact opencode@microsoft.com with any additional questions or comments.