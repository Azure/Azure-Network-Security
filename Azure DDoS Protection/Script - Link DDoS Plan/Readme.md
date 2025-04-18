
# Add Public IPs to Existing Azure DDoS Protection Plan  
**Author: Saleem Bseeu**

This PowerShell script allows users to assign the DDoS IP Protection SKU to selected Standard SKU Public IP addresses and link them to an existing Azure DDoS Network Protection plan. This is useful for selectively applying DDoS protection to only specific IPs in your environment and avoiding double billing.

## Example:

```powershell
# Edit these variables with your own values
$resourceGroupName = "MyResourceGroup"
$ddosProtectionPlanName = "MyDdosPlan"
$publicIpNames = @("PublicIP1", "PublicIP2")

# Run the script to enable protection and link to plan
.\link-ddos-ip-protection.ps1
```

The script will:
- Verify that each Public IP is using the Standard SKU
- Enable IP Protection on the Public IP if not already set
- Link the Public IP to the specified DDoS Network Protection plan
- Skip any IPs that are not eligible or already configured

## Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the Microsoft Open Source Code of Conduct. For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct) or contact opencode@microsoft.com with any additional questions or comments.
