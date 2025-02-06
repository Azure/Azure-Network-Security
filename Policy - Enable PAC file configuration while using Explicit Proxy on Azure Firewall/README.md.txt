Audit Azure Firewall Policies with Explicit Proxy and PAC File
Overview
This custom Azure policy ensures that if Explicit Proxy is enabled, the PAC File must also be enabled.

Policy Details
Display Name: Audit Azure Firewall Policies with Explicit Proxy and PAC File
Version: 1.0.0
Category: Network
Parameters
Effect: Enable or disable the policy (Allowed Values: Audit, Disabled; Default: Audit)
Policy Rule
Checks if explicitProxy.enableExplicitProxy is true and explicitProxy.enablePacFile is not true. If both conditions are met, the policy applies the specified effect.

Usage
Assign this policy to your Azure subscription or resource group and configure the Effect parameter as needed.