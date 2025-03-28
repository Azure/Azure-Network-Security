# Module 1 - Azure Firewall

⬅️[Return to the main page](https://github.com/gumoden/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/README.md)

## Scenarios
- [Controlling access between spoke virtual networks](#controlling-access-between-spoke-virtual-networks)
- [Securing Internet access using Azure Firewall](#securing-internet-access-using-azure-firewall)

## Controlling access between spoke virtual networks

For this scenario, we'll demonstrate how to control traffic flows between servers in different spoke virtual networks using Network rules. There are two spoke virtual networks that are directly peered to the Hub virtual network, housing the Azure Firewall. Using Route tables, all traffic from both spokes is forced to the Azure Firewall for inspection.

Let's verify the Network rules configurations on the firewall policy first.
1. In the search bar of the Azure Portal, search for **Firewall Manager** and select it. This will bring you to the 'Getting Started' page for Firewall Manager.
2. Once there, select **Azure Firewall Policies** under Security. You should see a policy named **fwpol-premium-alpineSkiHouse**, select it.
3. Select Network rules and you should see a list of rules from a variety of Rule collections. We're going to focus on the Rule name **spoke1-to-spoke2-snet1-RDP**. This rule allows TCP traffic on port 3389 to the servers in spoke2 subnet 1.

![AZFW-East_West-Network-Rule-1](https://github.com/gumoden/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/Images/Azfw-east-west-1.png)

4. Next, we'll use Bastion to remote into one of the VMs and test network connectivity. In the search bar of the Azure Portal, search for **Virtual Machines** and select **vm-win11-1**.
5. On the **vm-win11-1** Overview blade, select **Connect** and choose Bastion from the drop-down. For Username use **AzureUser**.
6. For Password you will use the password defined at the time of the deployment of the template. Click Connect.
7. Now that you're in the VM, click on the Windows icon and open a Windows PowerShell prompt. Enter '**test-netconnection 10.0.200.4**' to initiate an ICMP ping to the remote VM. You'll see that the pings fail since there are no network rules to allow ICMP traffic.
8. Next, click on the Windows icon, type RDP, and select **Remote Desktop Connection**. Enter 10.0.200.4 if it's not already populated and click Connect. You should be prompted to enter credentials for 10.0.200.4. This proves that we have connectivity between the servers on TCP port 3389. We'll be able to verify these tests in the logs.

![AZFW-East_West-Network-Rule-2](https://github.com/gumoden/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/Images/Azfw-east-west-2.png)

![AZFW-East_West-Network-Rule-3](https://github.com/gumoden/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/Images/Azfw-east-west-3.png)

## Securing Internet access using Azure Firewall

In this scenario, we'll use Application rules to control internet bound traffic from resources in our Azure virtual networks. We'll look at how to use FQDNs and Web Categories to filter what traffic should be allowed and to block the rest by not explicitly creating a rule to allow other traffic. Using Route tables, all traffic from both spokes is forced to the Azure Firewall for inspection.

Let's verify the Application rules configurations on the firewall policy first.
1. In the search bar of the Azure Portal, search for **Firewall Manager** and select it. This will bring you to the 'Getting Started' page for Firewall Manager.
2. Once there, select **Azure Firewall Policies** under Security. You should see a policy named **fwpol-premium-alpineSkiHouse**, select it.
3. Select **Application rules** and you should see a list of rules from multiple Rule collections. We're going to focus on the Rules named **spoke1-to-OWASPJuiceShopAndMicrosoft** and **spoke1-to-SearchEnginesandNewsSites**. These rules allow HTTP/S traffic on port 80/443 from the **spoke1** virtual network to ***.microsoft.com** and **owasp-<<ID_USED_AT_DEPLOYMENT>>.<<REGION_OF_YOUR_DEPLOYMENT>>.cloudapp.azure.com** (FQDN) and to all sites that fall under the Web categories **News**​​​​​​​ and **Search engines + portals** (Web categories).

![AZFW-Internet_Outbound-Application-Rule-1](https://github.com/gumoden/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/Images/Azfw-outbound-internet-1.png)

Next, we'll use Bastion to remote into one of the VMs and test network connectivity. If you already have a Bastion session open from the previous scenario, you can jump to step #7.

4. In the search bar of the Azure Portal, search for Virtual Machines and select **vm-win11-1**.
5. On the **vm-win11-1** Overview blade, select **Connect** and choose Bastion from the drop-down. For Username use **AzureUser**.
6. For Password you will use the password defined at the time of the deployment of the template. Click Connect.
7. Now that you're in the VM, click on the Edge icon to open a browser. Navigate to https://techcommunity.microsoft.com, you should be able to view the site due to the FQDN rule. Next, open another tab or Edge window and navigate to https://www.wsj.com, you should be able to view this site as well due to the Web Category rule. 
8. Next, open another tab or Edge window and navigate to https://www.facebook.com​​​​​​​, you should now get an error when trying to get to the site. In the browser, you may see 'Can't connect securely to this page' or 'Action: Deny: No rule matched. Proceeding with default action.' 
9. To force the 'Action: Deny' message, click on the Windows icon and open a Windows PowerShell prompt. Enter 'Invoke-WebRequest www.facebook.com' to initiate the call to the website. You should now see 'Action: Deny: No rule matched. Proceeding with default action.' if you didn't already in the browser.

![AZFW-Internet_Outbound-Application-Rule-2](https://github.com/gumoden/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/Images/Azfw-outbound-internet-2.png)

![AZFW-Internet_Outbound-Application-Rule-3](https://github.com/gumoden/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/Images/Azfw-outbound-internet-3.png)

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.
