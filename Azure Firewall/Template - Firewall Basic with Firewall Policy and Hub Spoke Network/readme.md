## Warning

Username and password to log in into the Windows VM are hard coded within the template at lines 231 and 232.
Please, consider changing the password in the template or after the VM is deployed.

## Pre-requisites:
1. Configure your Terraform environment. Example using Terraform on Windows with PowerShell: https://learn.microsoft.com/en-us/azure/developer/terraform/get-started-windows-powershell?tabs=bash
2. Download the FwBasicTFMain.tf file

## Recommended TF Commands:
1. terraform init
2. terraform plan -out FwBasicTFMain.tfplan
3. terraform apply FwBasicTFMain.tfplan

## These are the resources deployed by the template:
1. Disk - myosdisk1
2. Firewall - FWBasic
3. Firewall Policy - FwBasicPolicy
4. NIC - AppVm1Nic1
5. Public IP - FWBasicManagementIP
6. Public IP - FWBasicTransitIP
7. Route Table - Spoke1RT
8. VM (Windows 11 Pro) - AppVm1
9. VNet - HubVnet
10. Vnet - SpokeVnet1
