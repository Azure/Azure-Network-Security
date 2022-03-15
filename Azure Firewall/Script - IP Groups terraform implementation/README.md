# Azure-Firewall-IPGroup

<!-- Project description -->
I created this project to enable the implementation of Azure Firewall IP Groups and rules in batch.  The goal was to minimize the writing of additional terraform code while being able to add new elements using JSON input files. 

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
    - Change directory into the cloned directory `cd Azure-Firewall-IPGroup`
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

The project works by creating a template JSON file which references individual CSV files containing the large numbers of CIDR ranges that will be included in each IP group and then creates policies or classic network configurations using those rules.  The Terraform code parses the JSON input and recursively identifies if the firewall objects exist, and then creates or updates them. This project currently only works for network collections and rules, but future iterations could also allow for additional configuration types. It assumes that the resource group where the IP groups will be created already exists or is being created with another Terraform module.

An examples directory has been included with different sample types that can be modified for your specific use case.  To use the module, take one of the JSON samples, modify it with the desired configuration and save it in the module directory.  

Once the JSON input file has been configured then it is possible to run the Terraform workflow to implement or update the Firewall objects.

```
terraform init
terraform plan -var="input_filename=<input JSON filename>" -out=<planfilename>.tfplan
terraform apply <planfilename>.tfplan
```

or if you're feeling brave:
```
terraform init
terraform apply -var="input_filename=<input JSON filename>" 
```

After accepting the config changes you should now be able to see the IP groups in the portal.

If you need to update an IP group or create additional IP Groups the only requirement is to modify the JSON file containing the definition details, create/update the CSV file, and re-run the Terraform init/plan/apply sequence.

## Included Example
In the examples folder included in this repo, there are multiple examples of the different ways to use this module. Each example has an accompanying readme with details on running that particular sample.

# Issues
[(Back to top)](#table-of-contents)

- Ensure that the JSON file is properly formed JSON with a configuration that is valid. Invalid JSON can generate unusual errors that may be difficult to troubleshoot.


# Appendix - Powershell Script to split CSV into multiple files
To assist with large input files that exceed the limits for IP group sizes, a Powershell script that splits a CSV into smaller files has been included.  To run the script in the simplest form, just include the filename you want to split.
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
