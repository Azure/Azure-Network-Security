# Synchronization of Azure Firewall DNAT rules to AKS services

This PowerShell script propagates any changes in Kubernetes services that expose applications over internal Azure Load Balancers to DNAT rules in an Azure Firewall policy, so that there is one DNAT rule for every exposed service.

This PowerShell script should be configured as an Azure Automation runbook that is called when Event Grid detects a change in the internal ALB associated to AKS:

![Architecture of automatic synchronization between AKS and Azure Firewall](AzFW-AKS-sync,png "System architecture")

See a demo for this script here:

[![Watch the video](https://img.youtube.com/vi/6A8AdfsGAXk/0.jpg)](https://www.youtube.com/watch?v=6A8AdfsGAXk)
