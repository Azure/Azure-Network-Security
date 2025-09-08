# Azure Policy - Enagle Geo Block Rules

## Description
This policy identifies Web Application Firewall (WAF) configurations that lack a Geo-Block rule, which may indicate that inbound traffic from all locations is being permitted unnecessarily.

## Parameters
- **effect**: The effect of the policy (audit)

## Scope
This policy applies to:
- Application Gateway WAF V2

## Compliance
This policy helps ensure:
- Security compliance by maintaining clean WAF configurations
- Proper utilization of Azure Application Gateway WAF V2
