# Azure WAF Tuning - Postman collections

These Postman collections demonstrate a high-level overview of understanding Azure WAF diagnostic logs to help identify how to create exclusions and custom rules for the Azure WAF on Azure Application Gateway and Azure Front Door.

## How to import and use the Postman collection

### 1. Select Import on your workspace

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-Import.png?raw=true "Import")

You can either download the file locally and import from file selection, or you can use the raw url in GitHub and paste the url in the prompt.

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-Import-Step.png?raw=true "Import Step")

### 2. Input Variables on the collection
Once the collection has been imported, select the collection called **Azure WAF Tuning – Application Gateway** or **Azure WAF Tuning – Front Door** and select the **Variables** tab. Input the domain that is associated to your Application Gateway WAF_v2 or to the Front Door profile.

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-DomainVariable.png?raw=true "Variables")

### 3. Add a malicious cookie
Next, we'll create a malicious cookie to add to the request. This cookie will append itself to all requests for the domain until you remove it. 

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-Cookie.png?raw=true "Cookie")

With the prompt open, input the domain from the previous step and select **Add domain**. You'll see the domain appear in the list but with no cookies. Select **Add Cookie** and replace *value* with **my!@#$%^&Cookie**. This value can be changed back and forth as the value of the cookie or the key of the cookie. In the example screenshot, **Cookie_1** is the key.

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-Cookie-Value.png?raw=true "Cookie Add")

### 4. Send the request
Now our Postman collection is prepared, we can send a malicious request to our Azure WAF and check the logs for the sensitive fields we've defined in our Azure WAF policy.

![alt text](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20WAF/Postman%20-%20Collections%20for%20Azure%20WAF/Images/Postman-RequestSent.png?raw=true "Request")
