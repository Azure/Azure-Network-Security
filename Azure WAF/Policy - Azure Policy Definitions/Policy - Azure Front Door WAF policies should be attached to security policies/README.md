# Azure Front Door WAF policies should be attached to security policies

## Description
This policy identifies Azure Front Door WAF policies that are not attached to any security policies, indicating they may be orphaned and not protecting any resources. Orphaned WAF policies can result in unnecessary costs and should be reviewed for removal or proper assignment.

## Parameters
- **effect**: The effect of the policy (audit, disabled)

## Scope
This policy applies to:
- Standard_AzureFrontDoor WAF policies
- Premium_AzureFrontDoor WAF policies

## Compliance
This policy helps ensure:
- Cost optimization by identifying unused WAF policies
- Resource governance through proper WAF policy management
- Security compliance by maintaining clean WAF configurations
- Proper utilization of Azure Front Door Standard/Premium features

