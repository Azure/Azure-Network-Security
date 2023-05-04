# Importing a Checkpoint ruleset into Azure Firewall

As documented in [https://support.checkpoint.com/results/sk/sk120342](https://support.checkpoint.com/results/sk/sk120342), Checkpoint's Show Package Tool can be used to export the ruleset to JSON format with this command:

```
$MDS_FWDIR/scripts/web_api_show_package.sh -o /var/tmp
```

The generated `.tar.gz` file will contain both HTML files (human-readable) and JSON files (the ones interesting for our purpose). There is an `index.json` file that contains references to the rest of the JSON files that comprise the ruleset. There are mostly two files interesting for the Azure Firewall ruleset, one with the rules, and another one with the objects. In this folder there is a (simplified) example of a set of 3 files generated with this process:

- [index.json](./index.json)
- [Network-Management server.json](./Network-Management%20server.json)
- [Standard_objects.json](./Standard_objects.json)

The script `chkp2azfw.py` will try to locate an `index.json` file in the working directory, and it will extract the location of the files containing the rules and the objects. It will then process the Checkpoint rules and transform them into Azure Firewall network rules, and the IP objects will be converted to Azure IP Groups. Optionally, it can convert network rules into application rules under certain conditions (if the destination is an FQDN and ports are 80 or 443), for example with:

```
python3 ./chkp2azfw.py --log-level info --output json --pretty >template.json
```

The script offers multiple options to customize the generated ruleset:

```
❯ python3 ./chkp2azfw.py --help
usage: chkp2azfw.py [-h] [--json-index-file JSON_INDEX_FILE] [--policy-name POLICY_NAME] [--policy-sku POLICY_SKU] [--do-not-create-policy] [--rcg-name RCG_NAME] [--rcg-priority RCG_PRIO] [--no-ip-groups] [--no-app-rules]
                    [--max-ip-groups MAX_IPGROUPS] [--rule-uid-to-name] [--remove-explicit-deny] [--output OUTPUT] [--pretty] [--log-level LOG_LEVEL_STRING]

Generate an ARM template to create a Rule Collection Group from a Checkpoint ruleset exported with the Show Package Tool (https://support.checkpoint.com/results/sk/sk120342).

optional arguments:
  -h, --help            show this help message and exit
  --json-index-file JSON_INDEX_FILE
                        Local file containing in JSON the links to the rest of the exported JSON files. The default is "./index.json"
  --policy-name POLICY_NAME
                        Name for the Azure Firewall Policy. The default is "azfwpolicy"
  --policy-sku POLICY_SKU
                        SKU for the Azure Firewall Policy. Possible values: Standard, Premium (default: Standard)
  --do-not-create-policy
                        If specified, do not include ARM code for the policy, only for the rule collection group. Use if the policy already exists.
  --rcg-name RCG_NAME   Name for the Rule Collection Group to create in the Azure Firewall Policy. The default is "importedFromCheckpoint"
  --rcg-priority RCG_PRIO
                        Priority for the Rule Collection Group to create in the Azure Firewall Policy. The default is "10000"
  --no-ip-groups        Whether some address groups should be converted to Azure IP Groups (default: True)
  --no-app-rules        Whether it will be attempted to convert network rules using HTTP/S to application rules. Note that this might be a problem if a explicit network deny exists (default: True)
  --max-ip-groups MAX_IPGROUPS
                        Optional, maximum number of IP groups that will be created in Azure
  --rule-uid-to-name    Includes the UID of the Checkpoint rule in the name of the Azure rule, useful for troubleshooting (default: False)
  --remove-explicit-deny
                        If a deny any/any is found, it will not be converted to the Azure Firewall syntax. Useful if using application rules (default: False)
  --output OUTPUT       Output format. Possible values: json, none
  --pretty              Print JSON in pretty mode (default: False)
  --log-level LOG_LEVEL_STRING
                        Logging level (valid values: error/warning/info/debug/all/none. Default: warning)
```
