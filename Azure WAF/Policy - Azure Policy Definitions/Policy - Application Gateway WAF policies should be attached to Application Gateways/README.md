# Application Gateway WAF policies should be attached to Application Gateways

## Description
This policy identifies Application Gateway WAF policies that are not attached to any Application Gateways, indicating they may be orphaned and not protecting any resources. Orphaned WAF policies can result in unnecessary costs and should be reviewed for removal or proper assignment.

## Parameters
- **effect**: The effect of the policy (audit, disabled)

## Compliance
This policy helps ensure:
- Cost optimization by identifying unused WAF policies
- Resource governance through proper WAF policy management
- Security compliance by maintaining clean WAF configurations

