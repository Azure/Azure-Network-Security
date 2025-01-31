## ARM Template for Deploying WAF Policy

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
