# Module 1 - Azure Firewall

⬅️[Return to the main page](https://github.com/gumoden/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/README.md)

## Scenarios
- [Controlling access between spoke virtual networks](#controlling-access-between-spoke-virtual-networks)
- [Securing Internet access using Azure Firewall](#securing-internet-access-using-azure-firewall)
- [Use Latency Probe and Flow Trace Log to troubleshoot network connection issues](#use-latency-probe-and-flow-trace-log-to-troubleshoot-network-connection-issues)

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

## Use Latency Probe and Flow Trace Log to troubleshoot network connection issues

Azure Firewall has a few metrics and logs for troubleshooting network connectivity issues in Azure environments. For this scenario, we’ll be focusing on Latency Probe and Flow Trace Log to troubleshoot network connection issues. Let's verify that the new logs are enabled and sent to a log analytics workspace.

In the search bar of the Azure Portal, search for **Firewall Manager** and select it. This will bring you to the 'Getting Started' page for Firewall Manager.
1. Once there, select **Azure Firewalls** under Security. You should see an Azure Firewall named **azfw-hub-alpineSkiHouse**, select it.
2. Under Monitoring, select **Metrics**. Choose Latency Probe as the Metric in the drop-down.
3. [Latency Probe](https://learn.microsoft.com/en-us/azure/firewall/monitor-firewall-reference#azfw-latency-probe) is designed to measure the overall latency of Azure Firewall and provide insight into the health of the service. Azure Firewall latency can be caused by various reasons, such as high CPU utilization, throughput, or networking issues. As an important note, this tool is powered by Ping Mesh technology, which means that it measures the average latency of the ping packets to the firewall itself. The metric does not measure end-to-end latency or the latency of individual packets. The average expected latency for a firewall may vary depending on deployment size and environment.

![AZFW-Latency-and-Flow-Logs-1](https://github.com/gumoden/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/Images/Azfw-latency-flow-logs-1.png)

Now, let’s trigger some asymmetric network flows and good network and check the new Flow Trace Log in our Log Analytics workspace.
1. Next, we'll use Bastion to remote into one of the VMs and test network connectivity. In the search bar of the Azure Portal, search for **Virtual Machines** and select **vm-win11-2**.
2. On the **vm-win11-2** Overview blade, select Connect and choose Bastion from the drop-down. For Username use **AzureUser**.
3. For Password you will use the password defined at the time of the deployment of the template. Click Connect.
4. Once you’re in the VM, open a a Windows PowerShell prompt and enter **test-netconnection 10.0.100.4 -p 3389**. This connection should fail. 
5. Next, we'll use Bastion to remote into **vm-win11-1**. Repeat steps **#2** and **#3** to get in **vm-win11-1**.
6. Once you're in the VM, open a a Windows PowerShell prompt and run **test-netconnection 10.0.200.4 -p 445**. This connection will succeed, and we’ll look at what these 2 requests look like in the logs.

![AZFW-Latency-and-Flow-Logs-2](https://github.com/gumoden/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/Images/Azfw-latency-flow-logs-2.png)

Navigate back to **Azure Firewall Manager > Azure Firewalls > azfw-hub-alpineSkiHouse**. Under Monitoring, select Logs.

7. The first query we’ll run is **#1** below. You’ll see that **10.0.100.4** was able to hit **10.0.200.4** on Port **3389**. This is an indication of a SYN packet making it to the Azure Firewall and the firewall making a decision on what action to take. We'll take note of the SourcePort being used so that we can find the SYN-ACK on the next query.
8. Now let’s run query **#2**. We're using the SourcePort found in query 1 to use in query 2. When we run this in our workspace, we're able to find the SYN-ACK that's part of the TCP 3-way handshake.
9. Next, we will run query **#3** to see what an asymmetric route will look like in the Azure Firewall logs. You can see in the screenshot that the Flag column says INVALID for all of the request coming from 10.0.100.4 destined for 10.0.100.36. This flag INVALID, shows that the Azure Firewall does not have a SYN packet in its tables to know what to do with this unexpected SYN-ACK. If you remember from our previous steps, the VM, vm-win11-2, sent a connection request to 10.0.100.4 that would fail. This is because 10.0.100.36 has a direct path to 10.0.100.4 while 10.0.100.4 has to send all traffic to the Azure Firewall first.

**Query 1:**

```sql
AZFWNetworkRule
| where SourceIp == "10.0.100.4"
| where DestinationIp == "10.0.200.4"
```

![AZFW-Latency-and-Flow-Logs-3](https://github.com/gumoden/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/Images/Azfw-latency-flow-logs-3.png)

**Query 2:**

```sql
AZFWFlowTrace
| where SourceIp == "10.0.200.4"
| where DestinationIp == "10.0.100.4"
| where DestinationPort == "62877"
```

![AZFW-Latency-and-Flow-Logs-4](https://github.com/gumoden/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/Images/Azfw-latency-flow-logs-4.png)

**Query 3:**

```sql
AZFWFlowTrace
| where SourceIp == "10.0.100.4"
| where DestinationIp == "10.0.100.36"
```

![AZFW-Latency-and-Flow-Logs-5](https://github.com/gumoden/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/Images/Azfw-latency-flow-logs-5.png)
## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.
