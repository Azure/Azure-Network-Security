Author : [Lara Goldstein](https://github.com/laragoldstein13)

Use this template to create Logic App that sends notification for new Azure Firewall Premium IDPS signature updates.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520Firewall%2FTemplate%2520-%2520Logic%2520app%2520for%2520IDPS%2520signature%2520updates%2520notification%2FTemplate.json)

To view more information, see [this blog](https%3A%2F%2Ftechcommunity.microsoft.com%2Ft5%2Fazure-network-security-blog%2Freceive-email-notification-when-new-idps-rules-get-created-via%2Fba-p%2F3499588)  posted on Microsoft Tech Community.

## Deployment

During the deployment, you must specify some details, including the subscription, resource group, name, and region of this automation. You must also configure the following: 

1. Sender_Address: email address from which the automation will send the IDPS updates information to (this address is also used to form the connection to Office 365 Outlook, meaning the user deploying the automation must have access to the email account). 
2. Recipient_Address: email address to which the automation will send the IDPS updates information to (i.e., Security Team distribution list) 
3. Subscription_ID: name of the subscription that hosts the Firewall Policy with IDPS rules that you would like to receive updates about. 
4. Resource_Group_Name: name of the resource group that hosts the Firewall Policy with the IDPS rules that you would like to receive updates about. 
5. Policy_Name: name of the Firewall Policy with the IDPS rules you would like to receive updates about.  

**To authorize the API connection:** 

1. Go to the Resource Group you used to deploy the template resources. 
2. Select the Office365 API connection and press Edit API connection. 
3. Press the Authorize button. 
4. Make sure to authenticate against Azure AD. 
5. Press save. 
 
The Logic App must have the necessary permissions to query the IDPS rules on the Firewall Policy via the REST API.  This can be obtained via assigning the Logic App a system-assigned Managed Identity with Contributor permissions on the Firewall Policy resource or the Resource Group hosting the Firewall Policy resource. Note that you can assign permissions only if your account has been assigned Owner or User Access Administrator roles to the underlying resource. 

**To assign Managed Identity to specific scope:** 

1. Make sure you have User Access Administrator or Owner permissions for this scope (Firewall Policy resource or Resource Group hosting Firewall Policy resource). 
2. Go to the Firewall Policy resource/Resource Group page. 
3. Press Access Control (IAM) on the navigation bar. 
4. Press +Add and Add role assignment. 
5. Select the Contributor role. 
6. Assign access to Managed identity. 
7. Select the subscription where the Logic App was deployed. 
8. Select IDPSRulesNotification Logic App. 
9. Press save. 
 

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
