# WAF on  Azure Application Front Door should have request body inspection enabled


Ensure that Web Application Firewalls associated to Azure Application Front Doors have Request body inspection enabled. This allows the WAF to inspect properties within the HTTP body that may not be evaluated in the HTTP headers, cookies, or URI.  


More information : Azure [Built-in Policy](https://learn.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies) to enable [Request Body inspection for Azure WAF on Azure Front Door](https://ms.portal.azure.com/#view/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F4598f028-de1f-4694-8751-84dceb5f86b9)  