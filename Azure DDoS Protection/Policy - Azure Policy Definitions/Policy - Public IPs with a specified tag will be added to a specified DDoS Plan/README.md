# Enforce DDoS IP Protection on Tagged Public IPs

This repository contains an Azure Policy definition that automatically enables **DDoS IP Protection** on **Public IP addresses** that are explicitly tagged and associates them with an existing **Azure DDoS Protection Plan**.

The policy is designed to provide **opt‑in enforcement** using tags and uses Azure Policy’s **modify** effect to remediate non‑compliant resources.

---

## Policy Description

This policy evaluates Public IP resources and, when the specified tag key/value is present, ensures that DDoS IP Protection is enabled and linked to a defined DDoS Protection Plan.  
If protection is already enabled, no action is taken.

---

## What the Policy Does

- Targets `Microsoft.Network/publicIPAddresses`
- Applies only to Public IPs with a specific **tag key/value**
- Enables **DDoS IP Protection** if it is not already enabled
- Associates the Public IP with a provided **DDoS Protection Plan**
- Automatically remediates non‑compliant resources using the `modify` effect

---

## What the Policy Does Not Do

- Does not create a DDoS Protection Plan
- Does not apply to untagged Public IPs
- Does not deny Public IP creation
- Does not protect private or internal IP addresses
- Does not apply protection at the VNet level

---

## Requirements

To function correctly, the following requirements must be met:

- The policy **must be assigned with a system‑assigned managed identity**
- The managed identity must have **Network Contributor** permissions at or above the Public IP scope
- An **existing Azure DDoS Protection Plan** must be available
- The DDoS Protection Plan must be in the **same Azure region** as the Public IPs
- Public IPs must be tagged with the configured tag key and value

---

## Parameters

| Parameter | Description |
|---------|------------|
| `tagName` | Tag key used to identify Public IPs that should be protected |
| `tagValue` | Tag value that must match for the policy to apply |
| `ddosPlanId` | Resource ID of an existing Azure DDoS Protection Plan |

### Example Parameters

```json
{
  "tagName": "EnableDDoS",
  "tagValue": "true",
  "ddosPlanId": "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/ddosProtectionPlans/<plan-name>"
}

## Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.
When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.
This project has adopted the Microsoft Open Source Code of Conduct. For more information see the Code of Conduct FAQ or contact opencode@microsoft.com with any additional questions or comments.
