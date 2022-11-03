Author : [Lara Goldstein](https://github.com/laragoldstein13)

Use this template to create an Azure Logic App that runs every three day to backup your Azure Firewall and Azure Firewall Policy.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Flaragoldstein13%2FAzure-Network-Security%2Fmaster%2FAzure%2520Firewall%2FTemplate%2520-%2520Logic%2520App%2520for%2520Azure%2520Firewall%2520Backups%2Fazuredeploy.json)

## Overview of Resources Deployed
**1. Storage Account:** The template deploys a Storage Account with a container to store the backups as Blobs.

**2. Logic App:** The Logic App is scheduled to run every three days to store the Azure Firewall and Azure Firewall Policy templates.

**3. Connections:** An API connections to Azure Blob Storage is created for the Logic App to run as expected. Learn more about Logic App connectors [here](https://docs.microsoft.com/en-us/azure/connectors/apis-list).

## Deployment

During the deployment, you must specify some details, including the subscription, resource group, name, and region to host this automation. You must also configure the following: 

**1. Playbook_Name:** name of the Logic App that will run the backup process.

**2. Storage Account Name:** name of the Storage Account to store the backups.

**3. Firewall_Name:** name of the Azure Firewall to backup via the Logic App.

**4. Firewall_Policy_Name:** name of the Azure Firewall Policyto backup via the Logic App.

**5. Subscription_ID:** ID of the subscription that hosts the Azure Firewall and Azure Firewall Policy to backup.

**6. Resource_Group_Name:** name of the Resource Group that hosts the Azure Firewall and Azure Firewall Policy to backup.

## Permissions Required

1. The Logic App must have the necessary permissions to export the Azure Firewall and Azure Firewall Policy templates via [the Export Template REST API](https://docs.microsoft.com/en-us/rest/api/resources/deployments/export-template). This can be obtained via assigning the Logic App a system-assigned Managed Identity with Contributor permissions on the Firewall Policy/Firewall resources or the Resource Group hosting these resources. Note that you can assign permissions only if your account has been assigned Owner or User Access Administrator roles to the underlying resource.
2. The user account forming the connection must have the necessary [permissions to create a Blob in the Storage Account](https://docs.microsoft.com/en-us/azure/storage/blobs/assign-azure-role-data-access?tabs=portal). This can be accomplished via assigning the Storage Blob Data Contributor role on the Storage Container to the user who will be running the Logic App.

**To assign Managed Identity to specific scope:**
1. Make sure you have User Access Administrator or Owner permissions for this scope (Firewall Policy resource or Resource Group hosting Firewall Policy resource).
2. Go to the Azure Firewall, Azure Firewall Policy pages or the Resource Group that hosts these resources.
3. Press Access Control (IAM) on the navigation bar.
4. Press +Add and Add role assignment.
5. Select the Contributor role.
6. Assign access to Managed identity.
7. Select the subscription where the Logic App was deployed.
8. Select Backup-Az-FW Logic App.
9. Press save.
For more info, go here for assigning Managing Identity to specific scope

**Authorize API Connections for the Logic App**

1. Go to the Resource Group you used to deploy the template resources. 
2. Select the Azure Blob API connection and press Edit API connection. 
3. Press the Authorize button. 
4. Make sure to authenticate against Azure AD. 
5. Press save. 
 
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
