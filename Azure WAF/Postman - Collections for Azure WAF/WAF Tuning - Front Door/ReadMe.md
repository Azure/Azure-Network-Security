# Azure WAF Tuning - Postman collections & Deployment templates

This Postman collection demonstrates a high-level overview of understanding Azure WAF diagnostic logs to help identify how to create exclusions and custom rules for the Azure WAF on Azure Front Door. Using the collection, you'll be able to trigger different attacks that generate easy-to-follow logs to learn how to create Exclusions and Custom rules for false positives. For example, if you see in the log that there is a match for QueryParamValue, then you will create an exclusion using the Match variable of Query string args name.

| Log category | Match Variable |
|--------------|--------------------|
| HeaderValue | Request header name |
| CookieValue | Request cookie name |
| QueryParamValue | Query string args name |
| MultipartParamValue | Request body post args name |
| JsonValue | Request body JSON args name |
| URI | Custom Rule |


## How to import and use the Postman collection

### 1. Select Import on your workspace

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-Import.png?raw=true "Import")

You can either download the file locally and import from file selection, or you can use the raw url in GitHub and paste the url in the prompt.

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-Import-Step.png?raw=true "Import Step")

### 2. Input Variables on the collection
Once the collection has been imported, select the collection called **Azure WAF Tuning – Front Door** and select the **Variables** tab. Input the domain that is associated to your Front Door Profile.

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-DomainVariable.png?raw=true "Variables")

### 3. Add a malicious cookie
Next, we'll create a malicious cookie to add to the request. This cookie will append itself to all requests for the domain until you remove it. 

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-Cookie.png?raw=true "Cookie")

With the prompt open, input the domain from the previous step and select **Add domain**. You'll see the domain appear in the list but with no cookies. Select **Add Cookie** and replace *value* with **my!@#$%^&Cookie**. This value can be changed back and forth as the value of the cookie or the key of the cookie. In the example screenshot, **Cookie_1** is the key.

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-Cookie-Value.png?raw=true "Cookie Add")

### 4. Send the request
Now our Postman collection is prepared, we can send a malicious request to our Azure WAF.

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-RequestSent.png?raw=true "Request")


## Azure WAF Tuning - Front Door Template
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520WAF%2FPostman%2520-%2520Collections%2520for%2520Azure%2520WAF%2FWAF%2520Tuning%2520-%2520Front%2520Door%2FLab%2520Templates%2FAzureWAF-Quick-Tune-AFD.json)

## What is included:

| Resource Type | Resource Name | Purpose |
|---------------|---------------|---------|
| App Service Plan |  asf-uniqueString | Free tier (F1) App Service Plan for Linux OS |
| Web App |  owasp-uniqueString | Web App with OWASP Juice Shop installed. |
| WAF Policy |  wafafduniqueString | Front Door WAF Policy using DRS 2.1. WAF is enabled and set to Prevention mode. |
| Front Door | afd-owasp-uniqueString | Premium Front Door Profile with settings pre-configured. |
| Log Analytics Workspace | waf-workspace-uniqueString | Pay-as-you-go tier Log Analytics Workspace for ingesting WAF logs from Front Door resource. |

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
