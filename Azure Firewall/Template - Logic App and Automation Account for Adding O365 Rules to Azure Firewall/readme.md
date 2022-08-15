Author : [Lara Goldstein](https://github.com/laragoldstein13)

Use this template to create Logic App that sends notification for new Azure Firewall Premium IDPS signature updates.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520Firewall%2FTemplate%2520-%2520Logic%2520app%2520for%2520IDPS%2520signature%2520updates%2520notification%2FTemplate.json)

To view more information, see [this blog](https://techcommunity.microsoft.com/t5/azure-network-security-blog/receive-email-notification-when-new-idps-rules-get-created-via/ba-p/3499588) posted on Microsoft Tech Community.

## Deployment

During the deployment, you must specify some details, including the subscription, resource group, name, and region to host this automation. You must also configure the following: 

1. Sender_Address: email address from which the automation will send notifications to when the run is finished and the new O365 rules have been added to the Firewall Policy (this address is also used to form the connection to Office 365 Outlook, meaning the user deploying the automation must have access to the email account). 
2. Recipient_Address: email address to which the automation will send notifications to when the run is finished and the new O365 rules have been added to the Firewall Policy.
3. Subscription_ID: name of the subscription that hosts the Firewall Policy that you would like to add the O365 rule collection group to  or create for the purpose of including this rule collection group.. 
4. Resource_Group_Name: name of the resource group that hosts the Firewall Policy Firewall Policy that you would like to add the O365 rule collection group to  or create for the purpose of including this rule collection group..
5. Policy_Name: name of the Firewall Policy that you would like to add the O365 rule collection group to or create for the purpose of including this rule collection group.
6. Policy_Name: SKU of the Firewall that you would like to add the O365 rule collection group to or create for the purpose of including this rule collection group (accepted inputs are Standard or Premium).

**To authorize the API connection:** 

1. Go to the Resource Group you used to deploy the template resources. 
2. Select the Office365 API connection and press Edit API connection. 
3. Press the Authorize button. 
4. Make sure to authenticate against Azure AD. 
5. Press save. 
6. Complete the same steps for the Azure Automation and Azure Resource Manager API connections.
 
The account forming the connection must have the necessary permissions to create or update Azure Resource Manager template deployments and run the Azure Automation.

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
