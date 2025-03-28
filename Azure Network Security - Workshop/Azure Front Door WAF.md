# Module 3 - Azure Front Door WAF

⬅️[Return to the main page](https://github.com/gumoden/Azure-Network-Security/blob/master/Azure%20Network%20Security%20-%20Workshop/README.md)

## Scenarios
- [Redirect a HTTP request from a Mozilla Firefox browser to Edge download site](#redirect-a-http-request-from-a-mozilla-firefox-browser-to-edge-download-site)
- [Rate Limit when keyword "search" exists in the URI](#rate-limit-when-keyword-search-exists-in-the-uri)

## Redirect a HTTP request from a Mozilla Firefox browser to Edge download site

In this scenario, we'll use the Web Application Firewall (WAF), applied to our Premium SKU Front Door profile, to redirect any request that comes from a Mozilla Firefox browser to the Microsoft Edge download page. Using Custom rules, we'll use information from a HTTP request, such as User-Agent header, to identify that a request has originated from the Mozilla Firefox browser and redirect it accordingly.

Let's verify the settings on the WAF associated with our Azure Front Door first.
1. In the search bar of the Azure Portal, search for **Firewall Manager** and select it. This will bring you to the 'Getting Started' page for Firewall Manager.
2. Once there, select **Web Application Firewall Policies** under Security. You should see a policy named **wafafdwhmzgkcjeovje**, select it.
3. Select **Policy settings** under 'Settings' to see the Redirect URL that has been configured. It's set to the Microsoft Edge download page.
4. Now select **Custom rules** and click on the rule named **RedirectFirefoxUserAgent**. You'll see that this rule is configured to check the **RequestHeader** portion of an HTTP request. Within the 'RequestHeader', the WAF will look for the header called **User-Agent** and check if there is a value within the 'User-Agent' of **rv:127.0**, the current running version of Mozilla Firefox. If the value matches, then the request will be redirected.
>[!note] The rv will change over time. As of now the rv is currently 109.0. The rules will be maintained to reflect the current running version of Mozilla.

!IMAGE[afd-redirect-1.png](instructions281582/afd-redirect-1.png)

Now, let's test the Custom rule we just reviewed.
1. To run through this scenario, you'll need Mozilla Firefox installed.
2. With the browser installed, launch the browser and hit **F12** on your keyboard before moving forward. This should pull up the browser's 'developer tools' on the bottom of the page. Make sure that you select the **Network** tab to see what happens with the HTTP request.
3. With the developer tools up, navigate to **https://afd-owasp-whmzgkcjeovje-bnbqesg6brf3b9b4.z01.azurefd.net**, you should have been redirected to https://www.microsoft.com/en-us/edge. 

Let's look at the images below to see what happened during our HTTP request.

!IMAGE[afd-redirect-2.png](instructions281582/afd-redirect-2.png)
!IMAGE[afd-redirect-3.png](instructions281582/afd-redirect-3.png)

This allows us to observe the impact of the custom redirect rule when a specific condition is satisfied.

**You've reached the end of this module**

⬅️ [Go to the top](#scenarios)

## Rate Limit when keyword "search" exists in the URI

In this scenario, we'll use the Web Application Firewall (WAF), applied to our Premium SKU Front Door profile, to rate limit requests that have the keyword **search** within the URI. Using Custom rules, we'll use information to block requests that use the keyword more than 3 times within 5 minutes.

Let's verify the settings on the WAF associated with our Azure Front Door first.
1. In the search bar of the Azure Portal, search for **Firewall Manager** and select it. This will bring you to the 'Getting Started' page for Firewall Manager.
2. Once there, select **Web Application Firewall Policies** under Security. You should see a policy named **wafafdwhmzgkcjeovje**, select it.
3. Select **Custom rules** and click on the rule named **RateLimitRequest**. You'll see that this rule is configured to check the **RequestUri** and to find a value of search. If the policy has a match of more than 3 requests within 5 minutes from the same source, then it will deny the request.

!IMAGE[afd-rate-limit-1.png](instructions281582/afd-rate-limit-1.png)

Now, let's test the Custom rule we just reviewed.
1. Launch Microsoft Edge and hit **F12** on your keyboard before moving forward. This should pull up the browser's 'developer tools' on the right of the page. Make sure that you select the **Network** tab to see what happens with the HTTP request. This will look like a wi-fi icon.
2. With the developer tools up, navigate to **https://afd-owasp-whmzgkcjeovje-bnbqesg6brf3b9b4.z01.azurefd.net** and click on the search icon. Type in ​​**​​​​​apple** and hit enter.
3. Then refresh the entire browser (F5) so as to not get a cached response and force an actual second request to the Front Door. We'll need to use F5 a few times to trigger the rate limit rule. Since the value for the threshold is so low with a 5-minute window, you may need to hit F5 more than 3 times. This is not typical for a customer use-case that will have a much larger threshold defined, where the engine will excel. We should see no results on the page as the search was rate limited.

Let's look at the images below to see what happened during our HTTP request.

!IMAGE[afd-rate-limit-2.png](instructions281582/afd-rate-limit-2.png)
!IMAGE[afd-rate-limit-3.png](instructions281582/afd-rate-limit-3.png)

This enables us to observe the effect of the custom rate limit rule when a specific threshold is surpassed.

**You've reached the end of this module**

⬅️ [Go to the top](#scenarios)

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.
