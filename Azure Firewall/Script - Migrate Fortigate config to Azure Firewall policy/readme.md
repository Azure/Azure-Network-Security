
## Migrate from Fortinet config into Azure Firewall Policy
author: [Jose Moreno](https://github.com/erjosito)

This script provides a way read an existing Fortinet Fortigate configuration and export commands into an existing Azure Firewall Policy. 

Example:

    python ./read_fortigate_config.py --file ./fortigate_output.txt --format json


*add the rules*  

    az network firewall policy rule-collection-group collection rule add --name 1073742000 --source-addresses 10.15.5.20/32 10.15.5.40/32 10.15.5.30/32 10.15.5.50/32 10.5.22.140/32 10.5.22.145/32 10.5.22.150/32 10.5.22.155/32 --destination-addresses 10.10.40.21/32 10.10.40.22/32 --protocols tcp udp --destination-ports 288 33434

    az network firewall policy rule-collection-group collection rule add --name 1073742041 --source-addresses 10.15.5.40/32 10.15.5.50/32 10.5.22.140/32 10.5.22.150/32 --destination-addresses 10.10.40.21/32 10.10.40.22/32 --protocols tcp udp --destination-ports 22

This script has been provided by a community member and contributions are welcome

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
