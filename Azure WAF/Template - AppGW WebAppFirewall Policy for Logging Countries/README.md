# AppGW Web App Firewall Policy Sample
author: Nathan Swift  


This Web App Firewall policy can be deployed and used with Application Gateway to block Geos in a sanctioned and embargoed list, in addition a 2nd rule captures and records the countries of the client ip requests to WAF by using a Log Only across all countries in a higher priority.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%20WAF%2FTemplate%20-%20AppGW%20WebAppFirewall%20Policy%20for%20Logging%20Countries%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%20WAF%2FTemplate%20-%20AppGW%20WebAppFirewall%20Policy%20for%20Logging%20Countries%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

## Post Install 

Assign WebAppFirewall Policy, if an existing AppGW Policy is present assign this one to the HTTP Listener or Route Path

## KQL Queries to Get Started

To produce a quick list

```AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated >= ago(5m)
//| where clientIP_s contains "1.1.1.1"
| where ruleSetType_s == "Custom"
| parse Message with * "(" CountryofOrgin ")" end
| project TimeGenerated, clientIp_s, CountryofOrgin```

<img src="https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF%2FTemplate%20-%20AppGW%20WebAppFirewall%20Policy%20for%20Logging%20Countries/images/results.png"/>

To render a piegraph

```AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where TimeGenerated >= ago(5m)
//| where clientIP_s contains "1.1.1.1"
| where ruleSetType_s == "Custom"
| parse Message with * "(" CountryofOrgin ")" end
| project TimeGenerated, clientIp_s, CountryofOrgin
| summarize count() by CountryofOrgin
| render piechart```

<img src="https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF%2FTemplate%20-%20AppGW%20WebAppFirewall%20Policy%20for%20Logging%20Countries/images/resultspie.png"/>