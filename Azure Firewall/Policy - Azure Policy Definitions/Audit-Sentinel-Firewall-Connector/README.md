# Azure Policy - Audit Sentinel Azure Firewall Connector

## Description

This Azure Policy audits Microsoft Sentinel workspaces to ensure the Azure Firewall data connector is enabled. Organizations using Microsoft Sentinel for security monitoring should have the Azure Firewall connector configured to ingest firewall logs for threat detection and incident investigation.

## Policy Details

| Property | Value |
|----------|-------|
| **Policy Type** | Custom |
| **Mode** | All |
| **Effect** | AuditIfNotExists |
| **Category** | Security Center |

## Policy Logic

- **Condition**: Identifies resources where Microsoft Sentinel is enabled (`Microsoft.OperationsManagement/solutions` with product `OMSGallery/SecurityInsights`)
- **Existence Check**: Verifies that an Azure Firewall data connector (`Microsoft.SecurityInsights/dataConnectors` with kind `AzureFirewall`) exists
- **Result**: If Sentinel is enabled but the Azure Firewall connector is NOT configured, the resource is flagged as **non-compliant**

## Parameters

| Parameter | Type | Default | Allowed Values | Description |
|-----------|------|---------|----------------|-------------|
| effect | String | AuditIfNotExists | AuditIfNotExists, Disabled | Enable or disable the execution of the policy |

## Deployment

### Azure CLI

```bash
# Create the policy definition
az policy definition create \
  --name "audit-sentinel-firewall-connector" \
  --display-name "Audit - Microsoft Sentinel should have Azure Firewall connector enabled" \
  --description "This policy audits Microsoft Sentinel workspaces that do not have the Azure Firewall data connector configured." \
  --rules azure-policy-sentinel-firewall-connector.json \
  --mode All

# Assign the policy to a subscription
az policy assignment create \
  --name "sentinel-firewall-audit" \
  --policy "audit-sentinel-firewall-connector" \
  --scope "/subscriptions/<your-subscription-id>"
```

### PowerShell

```powershell
# Create the policy definition
$definition = New-AzPolicyDefinition `
  -Name "audit-sentinel-firewall-connector" `
  -DisplayName "Audit - Microsoft Sentinel should have Azure Firewall connector enabled" `
  -Description "This policy audits Microsoft Sentinel workspaces that do not have the Azure Firewall data connector configured." `
  -Policy "azure-policy-sentinel-firewall-connector.json" `
  -Mode All

# Assign the policy to a subscription
New-AzPolicyAssignment `
  -Name "sentinel-firewall-audit" `
  -PolicyDefinition $definition `
  -Scope "/subscriptions/<your-subscription-id>"
```

## Compliance

After policy assignment, allow up to 30 minutes for the initial compliance evaluation. Resources will show as:

- **Compliant**: Sentinel is enabled AND Azure Firewall connector is configured
- **Non-compliant**: Sentinel is enabled BUT Azure Firewall connector is NOT configured
- **Not applicable**: Sentinel is not enabled

## Remediation

To remediate non-compliant resources, enable the Azure Firewall data connector in Microsoft Sentinel:

1. Navigate to **Microsoft Sentinel** in the Azure Portal
2. Select your workspace
3. Go to **Data connectors**
4. Search for **Azure Firewall**
5. Click **Open connector page**
6. Follow the instructions to enable the connector

## Contributing

Contributions are welcome! Please submit a pull request with any improvements or additional policies.

## License

This project is licensed under the MIT License.
