# Azure Firewall IDPS Signature Management Scripts

This repository contains PowerShell scripts to **query, export, and bulk‑update Intrusion Detection and Prevention System (IDPS) signature overrides** in **Azure Firewall Premium** using the supported **Az PowerShell modules**.

These scripts are designed to help customers and operators efficiently tune IDPS behavior (Alert, Deny, or Off) at scale while respecting Azure Firewall and ARM platform limits.

---

## Scripts Overview

### `ipssigs.ps1`
Exports IDPS signatures from an Azure Firewall Policy to a CSV file based on filter criteria such as:
- Traffic direction
- Current mode (Alert / Deny / Off)
- Severity (High / Medium / Low)

This CSV can then be edited and used as input for bulk updates.

---

### `ipssigupdate.ps1`
Bulk updates IDPS signature overrides in an Azure Firewall Policy using a CSV input file.

Key capabilities:
- Updates thousands of signature overrides in a single policy update
- Optionally updates (or preserves) the **global IDPS mode**
- Uses Az PowerShell modules instead of direct REST calls
- Submits the policy update asynchronously to avoid console timeouts

---

## Prerequisites

- **Azure Firewall Premium**
- Permissions to read and update Azure Firewall Policies
- PowerShell 5.1 or PowerShell 7+
- Azure PowerShell modules:
  - `Az.Accounts`
  - `Az.Network`

To install all required Azure PowerShell modules:
```powershell
Install-Module Az -Repository PSGallery -Force
```

## Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.
When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.
This project has adopted the Microsoft Open Source Code of Conduct. For more information see the Code of Conduct FAQ or contact opencode@microsoft.com with any additional questions or comments.
