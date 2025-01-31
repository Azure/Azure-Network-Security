## ARM Template for Deploying WAF Policy

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Network-Security%2Frefs%2Fheads%2Fmaster%2FAzure%2520WAF%2FTemplate%2520-%2520QuickStart%2520Deployment%2520template%2520for%2520Azure%2520WAF%2520with%2520latest%2520Features%2520Jan%25202025%2FWAF%2520Quickstart%2520Template%2520v2.json)


This ARM template deploys a Web Application Firewall (WAF) policy for either an Application Gateway or Azure Front Door. 

The WAF policy includes the latest Microsoft Default Rule Set (DRS) 2.1 and Bot Manager Rule Set 1.1.

Features:
Sensitive Data Protection: Enables log scrubbing to protect sensitive data.
Prevention Mode: The WAF policy is deployed in Prevention mode by default.
Default Policy Settings have been enabled.

Deployment Options:
Provides the option to deploy an Application Gateway WAF Policy or an Azure Front Door WAF Policy.

Customization:
Log Scrubbing: Fields can be added and customized as needed.
Policy Settings: Default settings can be adjusted to fit specific requirements.

Post-Deployment:
Once deployed, the WAF policy can be associated with an Application Gateway or Azure Front Door
