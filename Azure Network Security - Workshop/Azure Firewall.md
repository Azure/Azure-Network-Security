# Module 1: Azure Firewall

**Have any feedback?**

If you have any ideas or suggestions to improve this demo environment and its scripts, please share your thoughts with us.

**Scenario: Controlling access between apoke virtual networks (Network Rules)**

For this scenario, we'll demonstrate how to control traffic flows between servers in different spoke virtual networks using Network rules. There are two spoke virtual networks that are directly peered to the Hub virtual network, housing the Azure Firewall. Using Route tables, all traffic from both spokes is forced to the Azure Firewall for inspection.

Let's verify the Network rules configurations on the firewall policy first.
1. In the search bar of the Azure Portal, search for **Firewall Manager** and select it. This will bring you to the 'Getting Started' page for Firewall Manager.
2. Once there, select **Azure Firewall Policies** under Security. You should see a policy named fwpol-premium-alpineSkiHouse, select it.
3. Select Network rules and you should see a list of rules from a variety of Rule collections. We're going to focus on the Rule name **spoke1-to-spoke2-snet1-RDP**. This rule allows TCP traffic on port 3389 to the servers in spoke2 subnet 1.



## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.
