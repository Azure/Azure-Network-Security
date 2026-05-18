# Azure WAF Triage Solution

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmain%2FAzure%20WAF%2FWAF%20Triage%20Solution%2Fazuredeploy.json)

> **Disclaimer:** This solution is provided **as-is** with no warranty or support. It is a community sample, not an official Microsoft product or service. Use it at your own risk.
>
> **Before applying any changes**, always review the proposed WAF exclusion or rule change carefully. This workbook helps prioritize tuning candidates using statistical analysis of WAF logs, but **it cannot determine whether traffic is truly legitimate**. Creating exclusions or disabling rules reduces WAF protection for the affected match patterns. You are responsible for validating that any change is appropriate for your application and security posture.
>
> Test changes in **Detection mode** before switching to Prevention mode whenever possible.

A solution to help identify and resolve **false positives** in Azure Application Gateway Web Application Firewall (WAF). It provides an Azure Monitor Workbook with evidence-based scoring, anomaly-scoring-aware tracing, and one-click remediation via Azure Automation.

## Overview

This solution deploys:

1. **Azure Monitor Workbook** — Triages WAF blocked requests, scores tuning candidates, and provides one-click exclusion creation
2. **Azure Automation Runbook** — Creates WAF exclusions or disables rules programmatically
3. **Logic App** — HTTP trigger that connects workbook actions to the automation runbook

## Key Features

- **FP Confidence Scoring** — Ranks tuning candidates with a 0–100 evidence-based score using 7 signals: trace evidence, breadth, recurrence, concentration, selector quality, mitigation safety, and transaction volume
- **Anomaly Scoring Awareness** — Traces blocked transactions back to contributing Matched rules, so you see the actual rules to exclude rather than the mandatory blocking rules (949/959/980)
- **One-Click Remediation** — Create per-rule exclusions or disable rules directly from the workbook with a single click
- **Quick Lookup** — Paste a transaction ID from logs or a support ticket to find the exact blocked request and fix it immediately
- **Attack Payload Filtering** — Automatically filters out selectors that contain XSS, injection, or other attack patterns to prevent accidental security weakening
- **Window-Relative Scoring** — Score components automatically adjust to the selected time range, preventing score inflation on longer time windows
- **Disable-Rule Safety Cap** — Broad disable-rule recommendations are capped below "Very High" confidence since they have wider security impact than scoped exclusions

## Workbook Tabs

| Tab | Purpose |
| --- | --- |
| **Auto-Tuning** | Proactive workflow — view all tuning candidates ranked by FP Confidence score, review evidence, and apply fixes |
| **Quick Lookup** | Reactive workflow — paste a transaction ID to find and fix a specific blocked request |
| **Overview** | Dashboard with summary tiles, time charts, top blocking rules, top blocked IPs and URIs |

## Supported Actions

| Action | When Used | Description |
| --- | --- | --- |
| **Create Exclusion** | Match variable is excludable (ARGS, REQUEST_HEADERS, REQUEST_COOKIES, etc.) | Creates a per-rule exclusion for the specific match variable and selector |
| **Disable Rule** | Match variable is non-excludable (REQUEST_URI, XML, etc.) | Disables the entire managed rule in the WAF policy |

## FP Confidence Score

The score is additive (0–100) with 7 components:

| Component | Max Points | What it measures |
| --- | ---: | --- |
| Trace Evidence | 15 | Is the candidate linked to real blocked transactions? |
| Breadth | 25 | How many endpoints and IPs per day does the pattern affect? |
| Recurrence | 10 | Does it recur consistently over the observation window? |
| Concentration | 20 | Is the traffic spread across sources, or dominated by one IP/URI? |
| Selector Quality | 5 | Does the parser find a precise, usable selector? |
| Mitigation Safety | 5 | Is the action a scoped exclusion (safer) or a full rule disable? |
| Transaction Volume | 20 | How many transactions per day does it affect? |

| Score Range | Label | Recommended Action |
| ---: | --- | --- |
| 85–100 | Very High | Strong candidate — review evidence and apply |
| 70–84 | High | Good candidate — review carefully before applying |
| 50–69 | Medium | Investigate further before acting |
| < 50 | Low | Weak evidence — do not auto-tune |

> **Important:** The FP Confidence score measures statistical prominence of a pattern. It does not prove that traffic is legitimate. Always review sample data before applying changes.

## Prerequisites

1. **Azure Subscription** with permissions to create Automation Accounts, Logic Apps, and Workbooks
2. **Log Analytics Workspace** receiving WAF diagnostic logs (both `ApplicationGatewayFirewallLog` and `ApplicationGatewayAccessLog`)
3. **WAF Policy** attached to your Application Gateway

## Deployment

### Option 1: Deploy to Azure Button

Click the button at the top of this page. Fill in:

- **Resource Group** — Where to deploy the solution components
- **Workspace Name** — Name of your existing Log Analytics workspace with WAF logs
- **Workspace Resource Group** — Resource group of the workspace

All other parameters have sensible defaults.

### Option 2: Azure CLI

```bash
az deployment group create \
  --resource-group <your-rg> \
  --template-file azuredeploy.json \
  --parameters workspaceName=<your-workspace> workspaceResourceGroup=<workspace-rg>
```

### Post-Deployment Steps

1. **Grant the Automation Account's Managed Identity `Contributor` access** to the WAF policies you want to manage:

   ```bash
   # Get the Automation Account's principal ID from the deployment output
   az automation account show --name aa-waf-triage --resource-group <your-rg> \
     --query identity.principalId -o tsv

   # Grant Contributor on the WAF policy
   az role assignment create \
     --assignee <principal-id> \
     --role Contributor \
     --scope /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/<policy>
   ```

2. **Open the Workbook** in Azure Portal: Monitor > Workbooks > Azure WAF Triage Solution

## Usage

### Proactive Tuning (Auto-Tuning Tab)

1. Select your subscription and workspace
2. Select the time range
3. Click an Application Gateway row in Step 1
4. Review candidates in the Auto-Tuning tab — sorted by FP Confidence score
5. Click a candidate row to see the impact preview
6. Click **Create Exclusion** or **Disable Rule** to apply

### Reactive Fix (Quick Lookup Tab)

1. Get the transaction ID from WAF logs or a support ticket
2. Select the correct Application Gateway scope in Step 1
3. Switch to the Quick Lookup tab
4. Paste the transaction ID
5. Click the matched rule row you want to fix
6. Click **Apply Fix**

## Architecture

```
+------------------------------------------------------------------+
|                    Azure Monitor Workbook                          |
|  +----------------+  +--------------+  +--------+                 |
|  | Auto-Tuning    |  | Quick Lookup |  | Overview|                |
|  +--------+-------+  +------+-------+  +--------+                |
|           |                  |                                    |
|  KQL Queries ----------------+----> Log Analytics Workspace       |
|  ARG Queries ----------------+----> Azure Resource Graph          |
|           |                                                       |
|           | User clicks "Apply"                                   |
|           | ARM Action (HTTP POST)                                |
+-----------+-------------------------------------------------------+
            |
            v
+--------------------------+       +--------------------------+
|     Logic App (HTTP)     | ----> | Azure Automation Runbook |
|  - Validates input       |       |  - Creates exclusion     |
|  - Triggers runbook      |       |  - OR disables rule      |
+--------------------------+       +------------+-------------+
                                                |
                                                v
                                   +--------------------------+
                                   |    WAF Policy            |
                                   |  - Exclusion added       |
                                   |  - OR rule disabled      |
                                   +--------------------------+
```

## File Structure

```
WAF Triage Solution/
├── README.md                          # This file
├── azuredeploy.json                   # Unified ARM template (Deploy to Azure)
├── runbooks/
│   └── New-WafExclusion.ps1          # Automation Runbook
└── workbook/
    └── waf-triage-workbook.json      # Azure Monitor Workbook definition
```

## Match Variable Mapping

The workbook automatically maps WAF log match variables to the correct exclusion API variables:

| WAF Log Variable | Exclusion API Variable | Action |
| --- | --- | --- |
| `ARGS` / `ARGS_GET` / `ARGS_POST` | `RequestArgValues` | Create Exclusion |
| `ARGS_NAMES` | `RequestArgKeys` | Create Exclusion |
| `REQUEST_HEADERS` | `RequestHeaderValues` | Create Exclusion |
| `REQUEST_HEADERS_NAMES` | `RequestHeaderKeys` | Create Exclusion |
| `REQUEST_COOKIES` | `RequestCookieValues` | Create Exclusion |
| `REQUEST_COOKIES_NAMES` | `RequestCookieKeys` | Create Exclusion |
| `REQUEST_BODY` | `RequestArgValues` | Create Exclusion |
| `REQUEST_URI` / `REQUEST_FILENAME` | — | Disable Rule |
| `XML:` | — | Disable Rule |
| `REQUEST_METHOD` / `REQUEST_PROTOCOL` | — | Disable Rule |

## Contributing

This project welcomes contributions and suggestions. Please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](../../LICENSE) file for details.


