Azure Policy - Enforce Explicit Proxy Configuration for Firewall Policies
This Azure Policy checks all deployed Firewall Policies (Microsoft.Network/firewallPolicies) to ensure the explicitProxy.enableExplicitProxy field is present. If it is missing, the policy flags or audits the resource based on the chosen effect.

How the Policy Works
Scope: Applies to all resources in scope with type Microsoft.Network/firewallPolicies.
Condition: Checks if explicitProxy.enableExplicitProxy does not exist ("exists": "false").
Action: Depending on the policy parameter effect, Azure Policy will either audit the non-compliant resource or disable the check.
Usage Instructions
Create/Assign the Policy: In the Azure Portal or via Azure CLI, upload this policy definition and assign it to a scope (management group, subscription, or resource group).
Choose the Effect: While assigning or editing the policy, select the desired effect (Audit or Disabled).
Review Compliance: In the Azure Policy blade, review which Firewall Policies do not meet the requirement if you have set the effect to Audit.