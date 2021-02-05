# Restrict creation of Azure DDoS Protection Standard plans with Azure Policy

## Overview

This Azure Policy will deny the creation of Azure DDoS Protection Standard plans in any subscription in scope. This policy helps prevent unplanned or unnapproved costs associated with the creation of DDoS plans across multiple subscriptions for the same tenant.

## Use cases

### Prevent new plans from being created

Deploying this policy in enforcement mode will deny the creation of DDoS plans for any subscription in scope from that moment on.

This policy will not retroactively delete DDoS plans that already existed prior to the assignment of this policy.

It is possible to define exclusions to allow desired subscriptions to deploy DDoS plans.

### Discover which subscriptions are non-compliant

This policy will show you which subscriptions are not compliant in the Policy Compliance section in Azure Portal.

It is possible to identify which subscriptions may be incurring unplanned or unnapproved costs by reviewing the compliance status of this policy.


## Requirements

* A **Management Group** must be used
* **Subscriptions** in scope must be part of the **Management Group**

## Creating the policy

<ol>
<li>In the <strong>Azure portal</strong>, browse to <strong>Policy</strong>.</li>

<li>Click on <strong>Definitions</strong>, and click on <strong>+ Policy definition</strong>.</li>

<li>Select the <strong>Definition location</strong>. The definition location must be the <strong>Management Group</strong> that holds all the subscriptions you want to monitor for compliance.</li>

<li>Enter a policy <strong>Name</strong>, for example: <em>Azure DDoS Protection Standard plans must not be created in non-approved subscriptions</em></li>

<li>Enter a policy <strong>Description</strong>, for example: <em>This policy blocks the creation of Azure DDoS Protection Standard plans in non-approved subscriptions.</em></li>

<li>Select a <strong>Category</strong>, for example: <em>Network</em>. Alternatively, you can create a new category if desired.</li>

<li>In the <strong>Policy Rule</strong> section, enter the code located in the AzurePolicyRuleDenyDDoSplan.json file at https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20DDoS%20Protection/Restrict%20creation%20of%20Azure%20DDoS%20Protection%20Standard%20Plans%20with%20Azure%20Policy/AzurePolicyRuleDenyDDoSPlan.json</li>
<li>Click on <strong>Save</strong> to create this custom policy.</li>
</ol>

## Assigning the policy

<ol>
<li>In the <strong>Azure portal</strong>, browse to <strong>Policy</strong>.</li>

<li>Click on <strong>Assigments</strong>, and click on <strong>-> Assign policy</strong>.</li>

<li>Select the <strong>Scope</strong>. The scope must be the <strong>Management Group</strong> that holds all the subscriptions you want to monitor for compliance.</li>

<li>If applicable, select the <strong>Exclusions</strong>. The exclusions would be any subscriptions that you want to allow to create DDoS plans.</li>

<li>In <strong>Policy definition</strong>, search for and select the custom policy you created in the previous step.</li>

<li>The <strong>Assignment name</strong> field will be automatically populated.</li>

<li>Enter an assigment <strong>Description</strong>, for example: <em>This policy blocks the creation of Azure DDoS Protection Standard plans in non-approved subscriptions. Branches must use the DDoS plan deployed in the Headquarter's subscription.</em></li>

<li>The <strong>Policy enforcement</strong> option must be <strong>Enabled</strong>.</li>

<li>Click on <strong>Review + create</strong>.</li>

<li>Review the <strong>Basics</strong> and note that no <strong>Paremeters</strong> or <strong>Remediation</strong> steps are required for this policy.</li>

<li>Click on <strong>Create</strong> to assign this policy to the selected scope.</li>
</ol>

## Reviewing policy compliance

<ol>
<li>After policy assigment, please allow approximately 30 minutes for the compliance status to change.</li>

<li>In the <strong>Azure portal</strong>, browse to <strong>Policy</strong>.</li>

<li>Click on <strong>Compliance</strong>, and click on the assigment you created in the previous step.</li>

<li>Observe your <strong>Compliance state</strong>.</li>

<li>If you are not compliant, verify the <strong>Resource compliance</strong> section. The subscriptions that are not compliant will be listed there.</li>
</ol>

## Expected behavior

When policy, assignment, and enforcement mode are configured, the administrator of a subscription in scope will see the following error message upon attempting to create a new DDoS plan. The deployment will fail and the DDoS plan will not be created.

![Error message screenshot - Request disallowed by policy](https://github.com/Azure/Azure-Network-Security/blob/master/Azure%20DDoS%20Protection/Restrict%20creation%20of%20Azure%20DDoS%20Protection%20Standard%20Plans%20with%20Azure%20Policy/AzurePolicyDenyMessageDDoSPlanCreation.png)

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
