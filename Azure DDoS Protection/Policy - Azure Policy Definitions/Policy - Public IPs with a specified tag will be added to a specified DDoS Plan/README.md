
## Policy - Public IPs with a specified tag will be added to a specified DDoS Plan

This Azure Policy automatically enables DDoS IP Protection for Azure Public IP resources that contain a specific tag. When a tagged Public IP is created or updated, the policy checks whether DDoS protection is enabled and associated with the specified DDoS Protection Plan. If not, the policy remediates the resource by attaching it to the configured plan. This policy requires the assignment’s managed identity to have the Network Contributor role on the DDoS Protection Plan so it can perform the Microsoft.Network/ddosProtectionPlans/join/action operation during remediation.

## Contributing
This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.
When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.
This project has adopted the Microsoft Open Source Code of Conduct. For more information see the Code of Conduct FAQ or contact opencode@microsoft.com with any additional questions or comments.
