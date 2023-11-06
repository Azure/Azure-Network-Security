# generate_waf_exclusion.py

This script takes an export of a log query that shows WAF blocks and outputs a de-duped, sorted list of arguments and what rules were found to be problematic.  It can be used to generate WAF exclusions where necessary based on what's present in the logs.

## Samply Query

A sample KQL to export the blocked URLs is:

```
AzureDiagnostics 
| where ResourceProvider == "MICROSOFT.NETWORK" and Category == "ApplicationGatewayFirewallLog"
| where action_s =="Blocked"
| distinct requestUri_s, ruleId_s
```

## Usage

`python generate_waf_exclusion.py query_data.csv`

## Output

This is an output sample that can be used to then base WAF exclusions off of.

```
dashboard                                 942200
dashboard                                 942260
dashboard                                 942340
selection                                 942200
selection                                 942260
selection                                 942330
selection                                 942340
selection                                 942430
stickySessionKey                          942200
stickySessionKey                          942260
stickySessionKey                          942300
stickySessionKey                          942340
stickySessionKey                          942370
stickySessionKey                          942430
RegionRect                                942260
RegionRect                                942370
RegionRect                                942430
```
