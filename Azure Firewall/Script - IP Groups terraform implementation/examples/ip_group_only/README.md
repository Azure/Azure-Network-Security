# IPGroup Deployment Example: Create IP Groups only

This example implements a set of IP groups using CSV files. This example uses csv files previously configured in the ip_group_csvs folder to create the IP groups. The instructions below include details for setting up Terraform as well as running the sample.  If you already have Terraform installed and configured you can skip to the usage section to complete implementation.

# Table of contents

- [Installation](#installation)
- [Usage](#usage)
- [Issues](#Issues)
- [Appendix](#Appendix)

# Installation
[(Back to top)](#table-of-contents)

To run the Terraform code, perform the following steps:
- Configure the deployment machine to use Terraform with Azure. If deploying from cloud shell, Terraform and azure cli applications are preinstalled and login is done automatically so those steps can be skipped.
    - Install Terraform.  Instructions can be found at this [link](https://learn.hashicorp.com/tutorials/terraform/install-cli)
    - Install the Azure CLI.  Instructions can be found at this [link](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
    - Sign-in to the Azure CLI. Instructions for sign-in options can be found at this [link](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli)
    - Set the subscription context to the subscription that will hold the Terraform state using the cli `az account set --subscription <id>` or `az account set --subscription "<subscription name>"`
- Clone the repo (assumes git is installed)
    - `git clone https://github.com/jchancellor-ms/Azure-Firewall-IPGroup.git`
    - Change directory into the cloned directory `cd Azure-Firewall-IPGroup\examples\ip_groups_only`
- Optionally, configure a remote state configuration using an Azure Storage Account
    - Create a resource group (or use an existing resource group) 
    - Create a storage account configured to your retention needs and ensure the account logged in has the ability to write and read blobs
    - Create a blob container for storing tfstate files
    - Open the providers.tf file
    - Remove the comment start/stop text and populate the storage account details from the previous step 
    - Save the providers.tf file
- At this point you can proceed to using the project

# Usage
[(Back to top)](#table-of-contents)

To implement the example, edit the `ip_groups_only.json` file replacing the resource_group_name and resource_group_location to values consistent with the desired configuration. Additionally, update any name fields in the configuration with the names you would like for the ip groups resources if you have a specific naming convention that is of interest.

If you want to modify the IP group contents, you can modify the CSV's and update the references in the IP_groups section of the json input file.

Once the JSON input file has been configured then it is possible to run the Terraform workflow to implement the example. 

```
terraform init
terraform plan 
terraform apply 
```
After accepting the config changes you should now be able to see the new rule collection, ip groups, and rules.

If you need to update an IP group or create additional IP Groups the only requirement is to modify the JSON file containing the definition details, create/update the CSV file, and re-run the Terraform init/plan/apply sequence.


# Issues
[(Back to top)](#table-of-contents)
- Ensure that the JSON file is properly formed JSON with a configuration that is valid. Invalid JSON can generate unusual errors that may be difficult to troubleshoot. 
- Ensure that each IP Group has a unique name to avoid troubleshooting errors related to intersection issues.


# Appendix - Powershell Script to split CSV into multiple files
To assist with large input files that exceed the limits for IP group sizes, a Powershell script that splits a CSV into smaller files has been included with the CSV files.  To run the script in the simplest form, just include the filename you want to split.
```
./splitCSV.ps1 "full_input_example.csv"
```

If you need to modify the maximum size or want to change things like the prefix values a full example with all parameters follows.
```
./splitCSV.ps1 -inputFile "full_input_example.csv" -maxRows 5000 -outFilePrefix "ipg_part_" -headerRow $true -headerValue "cidr"
```




<!-- Add the footer here 
# Footer
[(Back to top)](#table-of-contents)

Leave a star in GitHub, give a clap in Medium and share this guide if you found this helpful.


 ![Footer](https://github.com/navendu-pottekkat/awesome-readme/blob/master/fooooooter.png) -->
