## Deploy your Azure Firewall to span multiple Availability Zones

Azure has identified that some of your firewalls are not deployed in multiple zones. Azure Firewall can be configured during deployment to span multiple Availability Zones for increased availability. By using Availability Zones, your availability increases to 99.99% uptime. For more information, see the Azure Firewall Service Level Agreement (SLA). The 99.99% uptime SLA is offered when two or more Availability Zones are selected.  

# Deploy an Azure Firewall with Availability Zones using Azure PowerShell

Azure Firewall can be configured during deployment to span [multiple Availability Zones](https://learn.microsoft.com/en-us/azure/firewall/deploy-availability-zone-powershell) for increased availability.

This feature enables the following scenarios:

- You can increase availability to 99.99% uptime. For more information, see the Azure Firewall [Service Level Agreement (SLA)](https://azure.microsoft.com/support/legal/sla/azure-firewall/v1_0/). The 99.99% uptime SLA is offered when two or more Availability Zones are selected.
- You can also associate Azure Firewall to a specific zone just for proximity reasons, using the service standard 99.95% SLA.

For more information about Azure Firewall Availability Zones, see [Azure Firewall Standard features](features.md#availability-zones).


## Parameters  
Name:	Effect \
Type:	String \
Default Value:	Audit \
Allowed Values:	Audit; Deny; Disabled
