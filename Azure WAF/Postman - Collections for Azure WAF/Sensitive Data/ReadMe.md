# Sensitive Data Lab - Postman collection & Deployment template

This Sensitive data lab demonstrates how to use the Azure WAF Sensitive data (log scrubbing) feature to hide potentially sensitive information from logs.

## How to import and use the Postman collection
You'll need to deploy the template before finishing the steps for Postman. The domain for the Application Gateway is not created until after template deployment completion. This is needed to send the requests.
### 1. Select Import on your workspace

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-Import.png?raw=true "Import")

You can either download the file locally and import from file selection, or you can use the raw url in GitHub and paste the url in the prompt.

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-Import-Step.png?raw=true "Import Step")

### 2. Input Variables on the collection
Once the collection has been imported, select the collection called **Azure WAF - Sensitive Fields** and select the **Variables** tab. Input the domain that is associated to the Public IP resource from the deployment template under Current value. It should start with **owasp-** and end with **cloudapp.azure.com**. 

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-DomainVariable.png?raw=true "Variables")

### 3. Add a malicious cookie
Next, we'll create a malicious cookie to add to the request. This cookie will append itself to all requests for the domain until you remove it. Select any request under the collection, like **Request Header Names - Scanner Detection** and select **Cookies** on the far right. 

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-Cookie.png?raw=true "Cookie")

With the prompt open, input the domain from previous step and select **Add domain**. You'll see the domain appear in the list but with no cookies. Select **Add Cookie** and replace *value* with **my!@#$%^&Cookie**. This value matches what will be created in the Custom rule in the deployment template.

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-Cookie-Value.png?raw=true "Cookie Add")

### 4. Send the request
Now our Postman collection is prepared, we can send a malicious request to our Azure WAF and check the logs for the sensitive fields we've defined in our Azure WAF policy.

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-RequestSent.png?raw=true "Request")


## Azure WAF - Sensitive Data Lab Template
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520WAF%2FPostman%2520-%2520Collections%2520for%2520Azure%2520WAF%2FSensitive%2520Data%2FLab%2520Templates%2FAzureWAF-SensitiveData-ARM.json)

The ARM & Bicep lab template files include everything needed to test Azure WAF's Sensitive Data feature.

## What is included:

| Resource Type | Resource Name | Purpose |
|---------------|---------------|---------|
| Virtual Network |  vnet-uniqueString-waf | Virtual Network with a 192.168.0.0/24 address space with 1 subnet with a 192.168.0.0/26 address space. |
| Public IP |  pip-appgw-uniqueString-waf | Static Standard SKU Public IP associated with the Application Gateway. |
| App Service Plan |  asf-uniqueString | Free tier (F1) App Service Plan for Linux OS |
| Web App |  owasp-uniqueString | Web App with OWASP Juice Shop installed. |
| WAF Policy |  waf-appgw-uniqueString | Application Gateway WAF Policy using CRS 3.2 and Bot Manager Ruleset 1.0 with a single custom rule. WAF is enabled and set to Prevention mode. Log Scrubbing has been enabled and rules defined. |
| Application Gateway | appgw-uniqueString-waf | WAF_v2 SKU Application Gateway with settings pre-configured. |
| Log Analytics Workspace | waf-workspace-uniqueString | Pay-as-you-go tier Log Analytics Workspace for ingesting WAF logs from Application Gateway resource. |

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
