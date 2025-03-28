# Module 2 - Azure Application Gateway WAF

⬅️[Return to the main page](https://github.com/gumoden/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/README.md)

## Scenarios
- [Block HTTP request from the Mozilla Firefox browser](#block-http-request-from-the-mozilla-firefox-browser)
- [Block a SQL Injection attack](#block-a-sql-injection-attack)
- [Use JavaScript Challenge to stop bad bots](#use-javascript-challenge-to-stop-bad-bots)
- [Use Azure Diagnostic logs and Metrics to analyze the Azure WAF](#use-azure-diagnostic-logs-and-metrics-to-analyze-the-azure-waf)

## Block HTTP request from the Mozilla Firefox browser

In this scenario, we'll use the Web Application Firewall (WAF), applied to our Application Gateway v2 resource, to block any request that comes from a Mozilla Firefox browser. Using **custom rules**, we'll use information from a HTTP request, such as User-Agent header, to identify that a request has originated from the Mozilla Firefox browser and block it accordingly.

Let's verify the settings on the WAF associated with our Application Gateway v2 first:
1. In the search bar of the Azure Portal, search for **Firewall Manager** and select it. This will bring you to the 'Getting Started' page for Firewall Manager.
2. Once there, select **Web Application Firewall Policies** under Security. You should see a policy named **wafappgwwhmzgkcjeovje**, select it.
3. Select **Custom rules** and click on the rule named **BlockFirefoxUserAgent**. You'll see that this rule is configured to check the **RequestHeader** portion of an HTTP request Whithin the 'RequestHeader', the WAF will look for the header called **User-Agent** and check if there is a value within the 'User-Agent'containing **rv:**, which are unique characters to Mozilla Firefox. If the value matches, then the request will be denied.

>>**Note:** The rv will change over time. As of now the rv is currently 109.0. The rules will be maintained to reflect the current running version of Mozilla.

!IMAGE[mozilla-user-agent-1.png](instructions281582/mozilla-user-agent-1.png)

Now, let's test the Custom rule we just reviewed:
1. To run through this scenario, you'll need Mozilla Firefox installed.
2. Lauch the browser and hit **F12** on your keyboard before moving forward. This should pull up the browser's 'developer tools' on the bottom of the page. Make sure that you select the **Network** tab to see what happens with the HTTP request.
3. With the developer tools up, navigate to http://owasp-whmzgkcjeovje.centralus.cloudapp.azure.com, your request should have been blocked with a '403 Forbidden' status code.

Let's look at the images below to see what happened during our HTTP request.

!IMAGE[mozilla-user-agent-2.png](instructions281582/mozilla-user-agent-2.png)

!IMAGE[mozilla-user-agent-3.png](instructions281582/mozilla-user-agent-3.png)

**You've reached the end of this scenario**

Click [back](#modules) to return to the list of modules and select a new one. You can also click the bottom right arrow to move ahead to the next page, Block a SQL Injection attack.

**You've reached the end of this scenario**

⬅️ [Go to the top](#scenarios)

## Block a SQL Injection attack

In this scenario, we'll use the Web Application Firewall (WAF), applied to our Application Gateway v2 resource, to block a SQL injection attack. Using Managed rules, the WAF will be able to identify a potential SQL injection attack and block it accordingly. 

Let's verify the settings on the WAF associated with our Application Gateway v2 first:
1. In the search bar of the Azure Portal, search for **Firewall Manager** and select it. This will bring you to the 'Getting Started' page for Firewall Manager.
2. Once there, select **Web Application Firewall Policies** under Security. You should see a policy named **wafappgwwhmzgkcjeovje**, select it.
3. Select **Managed rules** and change the grouping of the rules to **Group by Rule group**. Scroll down until you see **SQLI (40)** and click on the arrow to open the list. Ensure that the rules are all set to 'Anomaly score' and 'Enabled'.

!IMAGE[sql-injection-1.png](instructions281582/sql-injection-1.png)

!IMAGE[sql-injection-2.png](instructions281582/sql-injection-2.png)

Now, let's test the Managed rule we just reviewed. First, we'll show what a successful SQL injection attack against the web application looks like when we bypass the WAF and go directly to the application and not the Application Gateway.
1. Open your browser on your client machine and browse to http://13.89.231.38:8081.
2. Once the website is loaded, click on 'Account' and then 'Login'.
3. At the Login page, for username, use **'or1=1--** and anything can be used for the password.
4. Click Log in and you'll see a successful SQL injection attack as you get logged in as the admin user.

!IMAGE[sql-injection-3.png](instructions281582/sql-injection-3.png)

!IMAGE[sql-injection-4.png](instructions281582/sql-injection-4.png)

Next, we'll run the same test but this time, we'll go through the WAF applied to the Application Gateway.
1. Open your browser on your client machine and browse to http://owasp-whmzgkcjeovje.centralus.cloudapp.azure.com.
2. Once the website is loaded, click on 'Account' and then 'Login'.
3. At the Login page, for username, use **'or1=1--** and anything can be used for the password.
4. Click Log in and you should see a 405 Forbidden message at the log in prompt. The WAF has recognized the SQL injection attempt and has blocked the request.

!IMAGE[sql-injection-5.png](instructions281582/sql-injection-5.png)

**You've reached the end of this scenario**

⬅️ [Go to the top](#scenarios)

Click [back](#modules) to return to the list of modules and select a new one. You can also click the bottom right arrow to move ahead to the next page, Use JavaScript Challenge to stop bad bots.

## Use JavaScript Challenge to stop bad bots

Approximately **48% of internet traffic** is generated by bots, with **30%** attributed to malicious bots. These harmful bots are programmed to attack web and mobile applications for fraudulent and malevolent purposes. These bad bots are typically automated test scripts that scrape websites to manipulate SEO rankings or prices, launch denial-of-inventory attacks and commit other malicious activities. Considering the risks associated with internet-exposed web applications, it is necessary for Azure WAF to detect and mitigate the bad bots. The mitigation of these attacks is accomplished by the Azure WAF JavaScript challenge.

The Azure WAF JavaScript (JS) challenge feature is a non-interactive, invisible web challenge used to distinguish legitimate users from bad bots. It is an invisible check issued to legitimate users and attackers as an intermediate page. Bad bots will fail the JS challenge but real users will not. Furthermore, JS challenges eliminate friction for real users since they don’t require any intervention from humans.  Hence, Azure WAF JS challenge is an effective method to protect against bot attacks without introducing customer friction.

Let's verify the settings on the WAF associated with our Application Gateway v2 first:
1. In the search bar of the Azure Portal, search for **Firewall Manager** and select it. This will bring you to the 'Getting Started' page for Firewall Manager.
2. Once there, select **Web Application Firewall Policies** under Security. You should see a policy named **wafappgwwhmzgkcjeovje**, select it.
3. Select **Policy settings** to first look at how long a JS Challenge cookie will last for any given user who passes. In our policy, we have this set to 5 minutes. The default value is 30 minutes and can be configured to go up to 1440 minutes (24 hours).
4. Select **Custom rules** and click on the rule named **JSChallenge**. You'll see that this rule is configured to check the **RequestUri** and to find a value of **/ftp**. If the request matches this condition, then the Azure WAF will JS Challenge the request. A bot will be unable to solve the challenge while an actual user using a browser will have no issues.

!IMAGE[js-challenge-1.png](instructions281582/js-challenge-1.png)

!IMAGE[js-challenge-2.png](instructions281582/js-challenge-2.png)

Now, let's test the Customer rule we just reviewed.
1. Launch Microsoft Edge and hit **F12** on your keyboard before moving forward. This should pull up the browser's 'developer tools' on the right of the page. Make sure that you select the **Network** tab to see what happens with the HTTP request. This will look like a wi-fi icon.
2. With the developer tools up, navigate to http://owasp-whmzgkcjeovje.centralus.cloudapp.azure.com and click on the hamburger button on the top left. Select **About Us**.
3. In the middle of the Lorem Ipsum text, you'll see a hyperlink that says **Check out our boring terms of use if you are interested in such lame stuff**. Select that to activate the JS Challenge.

Let's look at the images below to see what happened during our HTTP request.
1. Our first image shows the actuall JS Challenge in effect. Users will see this appear on their screen for about 2-3 seconds and will not be required to interact with it. You'll notice that very quickly, a 403 Forbidden is seen in the Dev tools, this is expected.
2. Once the challenge is complete, we'll see our JS challenge cookie get set in the Response Headers. Navigating to any other page on this site, you'll see this same cookie as part of the Request Headers. You'll also notice that the 403 is now gone and has been replaced with a 200 OK.

!IMAGE[js-challenge-3.png](instructions281582/js-challenge-3.png)

!IMAGE[js-challenge-4.png](instructions281582/js-challenge-4.png)

Now let's take a look at the logs and metrics generated from JS Challenge.
1. On Azure Portal search for the Application Gateway **appgw-whmzgkcjeovje-waf**, then select it.
2. Once there, select **Metrics** under Monitoring.
3. Select the metric **WAF JS Challenge Request Count**. This metric shows the count of all challenges that were made by the WAF, both pass and failed challenges.

!IMAGE[js-challenge-5.png](instructions281582/js-challenge-5.png)

4. Next, select **Logs** under Monitoring.
5. Using the query below, we'll be able to see what has happened with the challenges that were sent out. If a challenge is issued and it was passed, you'll be able to see this in the log. If the same user returns to the page that initiates a challenge and they still have an active cookie, you'll see that the message will say JSChallengeValid. You will not be able to see JS Challenges that have failed.

        AzureDiagnostics
        | where Category contains "ApplicationGatewayFirewallLog"
        | where action_s == "JSChallenge"
        | project TimeGenerated, clientIp_s, hostname_s, requestUri_s, ruleSetType_s, ruleSetVersion_s, ruleId_s, action_s, Message, details_message_s, details_file_s, details_line_s, transactionId_g

!IMAGE[js-challenge-6.png](instructions281582/js-challenge-6.png)

**You've reached the end of this scenario**

⬅️ [Go to the top](#scenarios)

## Use Azure Diagnostic logs and Metrics to analyze the Azure WAF

In this scenario, we'll first verify that diagnostic settings are enabled on the Application Gaterway v2 resource to ensure that we can see metrics and logs when a HTTP request has been processed by the Azure WAF. We'll then show you how to get a count of total requests serviced by the WAF and how many were blocked with Metrics. After, we'll demonstrate how to use the Kusto queries to investigate the WAF logs and reasons for actions.

1. In the search bar, search for the Application Gateway v2 resource, **appgw-whmzgkcjeovje-waf**.
2. Once selected, navigate to **Diagnostic settings** under 'Monitoring'. We should see a Diagnostic setting named **appgw-diag**. Select 'Edit setting' to view more.
3. Inside the Diagnostid setting, under 'Logs', we can see 3 category logs selected.
    - Application Gateway Access Log (ApplicationGatewayAccess).
    - Application Gateway Performance Log (Performance Logs are only for the v1 SKU, for performance on the v2, use Metrics).
    - Application Gateway Firewall Log (AppplicationGatewayFirewallLog) **This is the category we'll focus on in this demo script**.
4. Under 'Destination details', we see that the logs are being sent to a Log Analytics workspace named '**CyberSOC**'.
5. Metrics are enabled and visible by default. You do not need to send these to a Log Analytics workspace to view metrics.

Now, let's explore what the metrics are available for WAF:

1. Stay on the Application Gateway V2 resource **appgw-whmzgkcjeovje-waf** page.
2. Select **Metrics** under 'Monitoring'.
3. In the chart, click on the drop-down under Metric and select **WAF Total Requests**. We're going to **Apply splitting** and split by **Action**.
4. Select **+ New chart** on the top left and select **WAF Managed Rule Matches** for the Metric. We're going to **Apply splitting** and split by **Rule Id**. This will allow us to see what rules are being hit the most frequent.
5. You can continue to create new charts for Custom Rule Matches and Bot Protection Matches to see all actions being taken by the WAF in a metric view.

!IMAGE[waf-diag-metrics-1.png](instructions281582/waf-diag-metrics-1.png)

Next, we'll explore the logs and look for the logs showing the actions taken by WAF when we send the HTTP requests testing the Mozilla Firefox user agent and the SQL Injection attacks.

***If you haven't done those 2 modules, don't worry! You can continue testing the queries below.***

1. Stay on the Application Gateway V2 resource **appgw-whmzgkcjeovje-waf** page.
2. Select **Logs** under 'Monitoring'. These logs are being sent to the CyberSOC log analytics workspace we say in the diagnostic setting.
3. Copy and paste query #1 from the 'Kusto Queries' section below. This query will show you all requests that were blocked/matched by Managed rules within the time range specified. Specifically, this query will look for the logs generated by module 'Block a SQL injection attack'. Open a log to get familiar with the section **Message, details_message_s, and details_file_s** to understand what values matched the rule.
4. Copy and paste query #2 from the 'Kusto Queries' section below. This query will show you all requests that were blocked/matched by Custom rules within the time range specified. Open a log to get familiar with the section **Message** to understand what values matched the rule.
5. Copy and paste query #3 from the 'Kusto Queries' section below. This query will show you all requests that were blocked/matched by Bot Manager rules. Open a log to get familiar with the section **Message, details_message_s, and details_file_s** to understand what values matched the rule.

!IMAGE[waf-diag-metrics-2.png](instructions281582/waf-diag-metrics-2.png)

### Kusto Queries
1. **Default Rule Set**

```kql
AzureDiagnostics
| where Category contains "ApplicationGatewayFirewallLog"
| where ruleSetType_s == "Microsoft_DefaultRuleSet"
| project TimeGenerated, clientIp_s, hostname_s, requestUri_s, ruleSetType_s, ruleSetVersion_s, ruleId_s, action_s, Message, details_message_s, details_file_s, details_line_s, transactionId_g
```

2. **Custom rule**

```kql
AzureDiagnostics
| where Category contains "ApplicationGatewayFirewallLog"
| where ruleSetType_s == "Custom"
| project TimeGenerated, clientIp_s, hostname_s, requestUri_s, ruleSetType_s, ruleId_s, action_s, Message, transactionId_g
```

3. **Bot Manager Rule Set**

```kql
AzureDiagnostics
| where Category contains "ApplicationGatewayFirewallLog"
| where ruleSetType_s == "Microsoft_BotManagerRuleSet"
| project TimeGenerated, clientIp_s, hostname_s, requestUri_s, ruleSetType_s, ruleSetVersion_s, ruleId_s, action_s, Message, details_message_s, details_file_s, details_line_s, transactionId_g
```

**You've reached the end of this scenario**

⬅️ [Go to the top](#scenarios)

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.
