## Warning

Check the newly created Azure KeyVault within Resource Group, then go to Secrets for having access to the username and password to log in into the Windows VM and MySQL single instance.

## Pre-requisites:
1. Configure your Terraform environment. Example using Terraform on Windows with PowerShell: https://learn.microsoft.com/en-us/azure/developer/terraform/get-started-windows-powershell?tabs=bash
2. Download the main.tf file

## Recommended TF Commands:
1. terraform init
2. terraform plan -out main.tfplan
3. terraform apply main.tfplan
