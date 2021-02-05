# DDoS Mitigation Alert Enrichment

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Fmaster%2FAzure%2520DDoS%2520Protection%2FDDoS%2520Mitigation%2520Alert%2520Enrichment%2FEnrich-DDoSAlert.json)

This template deploys the necessary components of an enriched DDoS mitigation alert: Azure Monitor alert rule, action group, and Logic App. The result of the process is an email alert with details about the IP address under attack, including information about the resource associated with the IP. The owner of the resource is added as a recipient of the email, along with the security team. A basic application availability test is also performed and the results are included in the email alert.

The Log Analytics alert runs every 5 minutes and looks for DDoS MitigationStarted events.
The action group calls the webhook associated with the Logic App trigger.
The Logic App queries the Azure Resource Graph to enrich the alert, attempts an HTTP test against the attacked IP address (assuming the IP is listening for HTTP), and sends an enriched alert.

## Prerequisites

1. Existing Log Analytics workspace.
2. Owner tag must be populated on Public IP Address resources. The app expects this field to be only a user name so it can append @companydomain.com for email notification. Alternatively, the app can be modified to support other methods of identifying recipients.

## Deployment Instructions

1. Click the Deploy to Azure button above.
2. Choose a subscription and resource group to deploy to. The RG location must match the location of the Log Analytics workspace location.
3. Edit the names of the Logic App and alert if necessary.
4. Enter the email address for the security team or other primary alert recipient.
5. Enter the company domain in the form of @company.com.
6. Enter only the workspace name where DDoS Protection logs are stored.

## Post-Deployment

There are steps that must me done to configure the Logic App after it is deployed:

1. From the Logic App resource, click the Identity blade.
2. Ensure Status is On.
3. Click Azure Role Assignments.
4. Click Add Role Assignment.
5. Assign the Reader role to the scope of your choice.
6. Click the Logic App Designer blade.
7. For the first Send Email step (Connections), click Add New.
8. Authenticate with the account that will be used to send the notification emails.
9. Select the same account for the second Send Email step.
10. Save the Logic App.

## Step-by-step documentation
If you'd like more detailed step-by-step instructions on how to deploy this template, visit our Tech Community blog post https://aka.ms/ddosalert-techcommunity.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
