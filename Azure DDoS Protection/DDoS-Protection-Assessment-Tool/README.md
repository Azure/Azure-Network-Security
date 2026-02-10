# Azure DDoS Protection Assessment Tool

A comprehensive PowerShell script to assess DDoS Protection status across your Azure environment.

## Features

This tool provides significant improvements over the original [View Protected Public IPs tool](https://github.com/Azure/Azure-Network-Security/tree/master/Azure%20DDoS%20Protection/Script%20-%20View%20Protected%20Public%20IPs%20tool):

| Feature | Original Tool | This Version |
|---------|--------------|--------------|
| **DDoS SKU Detection** | VNET-based only | IP Protection + Network Protection |
| **Risk Assessment** | None | High/Medium/Low with actionable recommendations |
| **Diagnostic Logging** | Not checked | Validates DDoS log categories are configured |
| **Multi-Subscription** | Limited | Full support with `-AllSubscriptions` flag |
| **API Throttling** | None | Built-in retry logic with exponential backoff |
| **Resource Types** | Basic | NAT Gateway, Bastion, Firewall, VNet Gateway, etc. |
| **Error Resilience** | None | `-ContinueOnError` for large environments |
| **Per-Subscription Export** | No | `-SavePerSubscription` option |
| **Token Refresh** | No | Automatic token refresh for long-running scans |

## Prerequisites

- [Azure PowerShell Module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps) (Az.Accounts, Az.Network)
- RBAC permissions to view/list:
  - Public IP Addresses
  - Virtual Networks
  - Diagnostic Settings
  - Associated resources (Load Balancers, Application Gateways, etc.)

## Installation

Download the script:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Azure/Azure-Network-Security/master/Azure%20DDoS%20Protection/DDoS-Protection-Assessment-Tool/Check-DDoSProtection.ps1" -OutFile Check-DDoSProtection.ps1
```

## Usage

### Basic Usage (Current Subscription)

```powershell
.\Check-DDoSProtection.ps1
```

### Scan a Specific Subscription

```powershell
.\Check-DDoSProtection.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012"
```

### Scan All Subscriptions

```powershell
.\Check-DDoSProtection.ps1 -AllSubscriptions
```

### Export Results to CSV

```powershell
.\Check-DDoSProtection.ps1 -AllSubscriptions -ExportPath "C:\Reports\DDoS-Report.csv"
```

### Large Environment (with error resilience)

```powershell
.\Check-DDoSProtection.ps1 -AllSubscriptions -ContinueOnError -SavePerSubscription -ExportPath "C:\Reports\DDoS.csv"
```

### Custom Throttle Delay

```powershell
.\Check-DDoSProtection.ps1 -AllSubscriptions -ThrottleDelayMs 200
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-SubscriptionId` | Specific subscription ID to scan | Current subscription |
| `-AllSubscriptions` | Scan all accessible subscriptions | False |
| `-ExportPath` | Path to export CSV report | None |
| `-ContinueOnError` | Continue if a subscription fails | False |
| `-SavePerSubscription` | Save separate CSV per subscription | False |
| `-ThrottleDelayMs` | Delay between API calls (ms) | 100 |

## Output

The script provides:

### Console Output
- Real-time progress with percentage completion
- Per-subscription results table
- Comprehensive summary including:
  - Protection status (Protected/Not Protected)
  - DDoS SKU breakdown (IP Protection vs Network Protection)
  - Risk assessment (High/Medium/Low)
  - Diagnostic logging status

### CSV Export

| Column | Description |
|--------|-------------|
| Subscription | Azure subscription name |
| Public IP Name | Name of the Public IP resource |
| Resource Group | Resource group containing the Public IP |
| Location | Azure region |
| IP Address | Assigned IP address (or "Dynamic") |
| IP SKU | Standard or Basic |
| Allocation | Static or Dynamic |
| DDoS Protected | Yes/No |
| Risk Level | High/Medium/Low |
| DDoS SKU | IP Protection / Network Protection / None |
| DDoS Plan Name | Name of the DDoS Protection Plan (if applicable) |
| VNET Name | Associated Virtual Network |
| Associated Resource | Resource using this Public IP |
| Resource Type | Type of associated resource |
| Diagnostic Logging | Enabled/Partial/Not Configured |
| Log Destination | Log Analytics/Storage/Event Hub |
| Recommendation | Suggested action to improve protection |

## Risk Assessment Criteria

| Risk Level | Condition |
|------------|-----------|
| **High** | Public IP not protected by DDoS (exposed to attacks) |
| **Medium** | DDoS protected but diagnostic logging not configured |
| **Low** | DDoS protected with diagnostic logging enabled |

## Supported Resource Types

- Virtual Machines (via Network Interface)
- Load Balancers (Standard & Basic)
- Application Gateways
- Azure Firewalls
- Bastion Hosts
- Virtual Network Gateways (VPN/ExpressRoute)
- NAT Gateways

## Known Limitations

- Basic SKU Public IPs cannot use DDoS IP Protection (Standard SKU required)
- Resources in different subscriptions than their VNETs may show "Access Denied"

## Contributing

Contributions are welcome! Please submit issues or pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file for details.
