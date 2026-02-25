# Alert: Distributed Low Rate DDoS - Carpet Bombing Detection

## Overview

This detection identifies **distributed low-rate DDoS attacks** (commonly known as "carpet bombing") targeting resources protected by Azure Firewall. These attacks are characterized by many source IPs each sending low-volume traffic to the same destination, deliberately staying below per-IP detection thresholds while the aggregate traffic degrades availability.

## Why This Detection Matters

Traditional DDoS detection focuses on volumetric spikes from single sources or obvious traffic anomalies. Carpet bombing attacks evade these defenses by:

- **Distributing traffic** across hundreds or thousands of source IPs
- **Keeping per-source rates low** (each IP sends only a few requests)
- **Rotating protocols** (TCP, UDP, ICMP) to avoid protocol-specific signatures
- **Leveraging geo-distributed botnets** to appear as diverse legitimate traffic

Even with Azure DDoS Protection enabled, these attacks can slip through because:
1. Individual source behavior appears "normal"
2. No single protocol shows anomalous volume
3. Rate limiting per-IP is ineffective when each IP is already low-rate

## Detection Logic

The alert triggers when ALL of the following conditions are met:

| Condition | Default Value | Purpose |
|-----------|---------------|---------|
| Unique source IPs ≥ threshold | 50 | Ensures attack is distributed |
| Events per source ≤ threshold | 10 | Confirms "low rate" per source |
| Distinct protocols ≥ threshold | 2 | Detects protocol rotation |
| Max protocol share ≤ threshold | 80% | Ensures no single protocol dominates |
| Total events ≥ threshold | 500 | Confirms aggregate impact potential |
| Distinct countries ≥ threshold | 3 | Indicates geo-distributed botnet |

## Alert Output

When triggered, the alert provides:

- **TargetDestination**: The IP/FQDN under attack
- **TotalEvents**: Aggregate traffic volume in the window
- **UniqueSourceIPs**: Count of distinct attacking IPs
- **MaxEventsFromSingleSource**: Confirms low-rate per source
- **ProtocolsObserved**: List of protocols used (TCP, UDP, ICMP, etc.)
- **MaxProtocolDominancePct**: Highest single protocol percentage
- **UniqueCountries**: Geographic diversity indicator
- **CountriesList**: Countries where traffic originated
- **SampleSourceIPs**: Sample of source IPs for investigation
- **AllowedTraffic / DeniedTraffic**: Traffic disposition breakdown
- **AlertSeverity**: Computed severity (High/Medium/Low)
- **AlertDescription**: Human-readable summary

## Deployment

### Prerequisites

- Azure Firewall with diagnostics enabled
- Log Analytics workspace receiving firewall logs
- Choose the correct template based on your log configuration:
  - **Classic (AzureDiagnostics)**: Most common, uses legacy diagnostic settings
  - **Resource-Specific**: Newer tables (`AZFWNetworkRule`, `AZFWApplicationRule`) for better performance

### Deploy via Azure Portal

1. Navigate to **Custom deployment** in Azure Portal
2. Select **Build your own template in the editor**
3. Copy the contents of the appropriate JSON file
4. Click **Save**, then fill in parameters
5. Deploy to the same resource group as your Log Analytics workspace

### Deploy via Azure CLI

**Classic Schema:**
```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file DistributedLowRateDDoS_Classic.json \
  --parameters workspaceName=<your-workspace-name>
```

**Resource-Specific Schema:**
```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file DistributedLowRateDDoS_ResourceSpecific.json \
  --parameters workspaceName=<your-workspace-name>
```

### Deploy via PowerShell

```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "<your-resource-group>" `
  -TemplateFile "DistributedLowRateDDoS_Classic.json" `
  -workspaceName "<your-workspace-name>"
```

## Tuning Guide

### Conservative Tuning (Fewer Alerts, High Confidence)

For environments with high legitimate traffic diversity:

| Parameter | Conservative Value |
|-----------|-------------------|
| MinDistinctSources | 100 |
| MinTotalEvents | 1000 |
| MinDistinctCountries | 5 |
| MaxEventsPerSource | 5 |

### Aggressive Tuning (More Coverage, More Alerts)

For high-security environments or smaller deployments:

| Parameter | Aggressive Value |
|-----------|-----------------|
| MinDistinctSources | 20 |
| MinTotalEvents | 200 |
| MinDistinctCountries | 2 |
| MaxEventsPerSource | 20 |

### Recommended Baseline by Environment Type

| Environment | MinDistinctSources | MinTotalEvents | TimeWindow |
|-------------|-------------------|----------------|------------|
| **Small/Medium business** | 30 | 300 | 5m |
| **Enterprise with diverse traffic** | 75 | 750 | 5m |
| **API/CDN backend** | 100 | 1500 | 10m |
| **High-security (accept more alerts)** | 20 | 200 | 3m |

## Reducing False Positives

Common false positive scenarios and mitigations:

### 1. Legitimate API Traffic
**Symptom**: Many mobile clients accessing APIs
**Mitigation**: Increase `MinDistinctSources` and `MinTotalEvents`, or exclude known API endpoints

### 2. CDN Traffic
**Symptom**: CDN edge servers appear as diverse sources
**Mitigation**: The protocol rotation filter should help (CDN traffic is typically HTTPS-dominant)

### 3. Health Checks
**Symptom**: Load balancer or monitoring health checks
**Mitigation**: Low event counts per source typically exclude these, but increase `MinTotalEvents` if needed

### 4. Marketing Campaign Spikes
**Symptom**: Legitimate traffic surge after campaign launch
**Mitigation**: The geo-diversity and protocol diversity requirements should filter these out

## Known Limitations

1. **Geo-IP accuracy**: The `geo_info_from_ip_address()` function may not resolve all IPs accurately, especially private ranges
2. **Log latency**: Azure Firewall logs may have ingestion delay; consider this when setting time windows
3. **Cost implications**: This query performs multiple joins and aggregations; monitor Log Analytics costs
4. **IPv6 support**: Detection works with IPv6 but geo-IP resolution may be less accurate

## Testing the Detection

To validate the detection without a real attack, you can use this test query (adjust thresholds temporarily):

```kql
// Test query with lowered thresholds - DO NOT deploy in production
let TimeWindow = 60m;
let MinDistinctSources = 5;  // Lowered for testing
let MaxEventsPerSource = 100;  // Raised for testing
let MinProtocols = 1;  // Lowered for testing
let MaxProtocolSharePct = 100.0;  // Raised for testing
let MinTotalEvents = 50;  // Lowered for testing
let MinDistinctCountries = 1;  // Lowered for testing
// ... rest of query
```

## Integration with Response Workflows

### Azure Sentinel / Microsoft Sentinel

This alert can be promoted to a Sentinel Analytics Rule for enhanced investigation capabilities:

1. Import the ARM template into Sentinel
2. Configure automated investigation playbooks
3. Correlate with other network security signals

### Recommended Response Actions

1. **Immediate**: Review sample source IPs for known bad actors
2. **Short-term**: Consider geographic blocking if sources are from unexpected regions
3. **Investigation**: Check if target destination is experiencing availability issues
4. **Long-term**: Feed source IPs into threat intelligence for future blocking

## References

- [Carpet Bombing DDoS Attacks - Vercara](https://www.vercara.com/)
- [Low-Rate DDoS Attack Techniques - NSFocus](https://www.nsfocusglobal.com/)
- [Azure Firewall Logging](https://docs.microsoft.com/azure/firewall/logs-and-metrics)
- [Azure DDoS Protection](https://docs.microsoft.com/azure/ddos-protection/ddos-protection-overview)

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-02-23 | Initial release |

## Contributing

This project welcomes contributions and suggestions. See the [CONTRIBUTING.md](../../../../CONTRIBUTING.md) file for details.
