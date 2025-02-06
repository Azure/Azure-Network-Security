# WAF on  Azure Application Gateway should have request body inspection enabled


Ensure that Web Application Firewalls associated to Azure Application Gateways have Request body inspection enabled. This allows the WAF to inspect properties within the HTTP body that may not be evaluated in the HTTP headers, cookies, or URI.  


More information : Azure [Built-in Policy](https://learn.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies) to enable [Request Body inspection for Azure WAF on Application Gateway](https://ms.portal.azure.com/#view/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2Fca85ef9a-741d-461d-8b7a-18c2da82c666)  