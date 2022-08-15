#!/usr/bin/env python3
import requests
import argparse
import json
import re

# Helper functions

# True if any of the urls contained in the URL list contains a wildcard ('*')
def urls_contain_wildcard(urls):
    for url in urls:
        if '*' in url:
            return True
    return False

# Check whether URLs are correct:
#   - Wildcard needs to be in the beginning of the string, not valid in the middle
def verify_urls(urls):
    corrected_urls = []
    for url in urls:
        if url.find('*') <= 0:
            corrected_urls.append(url)
        else:
            corrected_urls.append(url[url.find('*'):])
            if args.verbose:
                print("WARNING: URL {0} reduced to {1}".format(url, url[url.find('*'):]))
    return corrected_urls

# Filters out IP addresses based on the args.ip_version parameter (can be ipv4, ipv6 or both)
def filter_ips(ip_list):
    # For both versions, dont filter
    if args.ip_version == 'both':
        return ip_list
    else:
        filtered_ips = []
        for ip in ip_list:
            # For 'ipv4', return only those who match the IPv4 check
            if is_ipv4(ip) and (args.ip_version == 'ipv4'):
                filtered_ips.append(ip)
            # For 'ipv6', return only non-IPv4 addresses (assumed to be ipv6 then)
            elif (not is_ipv4(ip)) and (args.ip_version == 'ipv6'):
                filtered_ips.append(ip)
        # if args.verbose:
        #     print("DEBUG: IP list {0} filtered to {1}".format(str(ip_list), str(filtered_ips)))
        return filtered_ips

# True if parameter is an ipv4 address
def is_ipv4(ip_address):
    return bool(re.match(r"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?:/\d{1,2}|)$",str(ip_address)))

# Arguments
parser = argparse.ArgumentParser(description='Generate an ARM template to create a Rule Collection Group in an Azure policy with rules that allow access to M365 endpoints.')
parser.add_argument('--policy-name', dest='policy_name', action='store',
                    default="",
                    help='Name for the Azure Firewall Policy. The default is "o365policy"')
parser.add_argument('--policy-sku', dest='policy_sku', action='store',
                    default="Premium",
                    help='SKU for the Azure Firewall Policy. Possible values: Standard, Premium (default: Premium)')
parser.add_argument('--do-not-create-policy', dest='dont_create_policy', action='store_true',
                    default=False,
                    help='If specified, do not include ARM code for the policy, only for the rule collection group. Use if the policy already exists.')
parser.add_argument('--rcg-name', dest='rcg_name', action='store',
                    default="o365_rulecollectiongroup",
                    help='Name for the Rule Collection Group to create in the Azure Firewall Policy. The default is "o365"')
parser.add_argument('--rcg-priority', dest='rcg_prio', action='store',
                    default="10000",
                    help='Priority for the Rule Collection Group to create in the Azure Firewall Policy. The default is "10000"')
parser.add_argument('--format', dest='format', action='store',
                    default="json",
                    help='Output format. Possible values: json, none')
parser.add_argument('--ip-version', dest='ip_version', action='store',
                    default="ipv4",
                    help='IP version of AzFW rules. Possible values: ipv4, ipv6, both. Default: ipv4')
parser.add_argument('--pretty', dest='pretty', action='store_true',
                    default=False,
                    help='Print JSON in pretty mode (default: False)')
parser.add_argument('--verbose', dest='verbose', action='store_true',
                    default=False,
                    help='Run in verbose mode (default: False)')
args = parser.parse_args()

# Variables
o365_endpoints_url = 'https://endpoints.office.com/endpoints/worldwide?clientrequestid=b10c5ed1-bad1-445f-b386-b919946339a7'
app_rules = []
net_rules = []
rcg_name = args.rcg_name
rcg_prio = args.rcg_prio
rc_app_name = 'o365app'
rc_app_prio = "11000"
rc_net_name = 'o365net'
rc_net_prio = "10900"

# Get O365 endpoints from the Internet
response = requests.get(o365_endpoints_url)
if response.status_code == 200:
    if args.verbose:
        print ("DEBUG: File {0} downloaded successfully".format(o365_endpoints_url))
    try:
        # Deserialize JSON to object variable
        o365_data = json.loads(response.text)
    except Exception as e:
        print("Error deserializing JSON content: {0}".format(str(e)))
        sys.exit(1)

# Go through the rules
cnt_apprules = 0
cnt_netrules_ip = 0
cnt_netrules_fqdn = 0
cnt_endpoints = 0
for endpoint in o365_data:
    cnt_endpoints += 1


    # IP-based Net Rule
    if ('ips' in endpoint):
        cnt_netrules_ip += 1
        if ('ips' in endpoint) and (('tcpPorts' in endpoint) or ('udpPorts' in endpoint)):
            new_rule = {
                'name': 'id' + str(endpoint['id']) + '-' + str(endpoint['serviceAreaDisplayName']).replace(" ", ""),
                'ruleType': 'NetworkRule',
                'sourceAddresses': [ '*' ],
                'destinationAddresses': filter_ips(endpoint['ips']),
                'destinationFqdns': []
            }
            if 'tcpPorts' in endpoint:
                new_rule['ipProtocols'] = [ 'tcp' ]
                new_rule['destinationPorts'] = str(endpoint['tcpPorts']).split(",")
            else:
                new_rule['ipProtocols'] = [ 'udp' ]
                new_rule['destinationPorts'] = str(endpoint['udpPorts']).split(",")
            net_rules.append(new_rule)
            # Watch out for UDP+TCP!
            if ('udpPorts' in endpoint) and ('tcpPorts' in endpoint):
                print("WARNING: Endpoint ID {0} has both TCP and UDP ports!".format(endpoint['id']))
        else:
            if not ('ips' in endpoint):
                print('ERROR: Endpoint ID {0} is IP-based with wildcards, but does not have ips'.format(endpoint['id']))
            if not ('udpPorts' in endpoint):
                print('ERROR: Endpoint ID {0} is IP-based with wildcards, but does not have udpPorts'.format(endpoint['id']))
            if args.verbose:
                print('DEBUG: endpoint:', str(endpoint))

    # App Rule
    elif ('tcpPorts' in endpoint) and ((endpoint['tcpPorts'] == "80,443") or (endpoint['tcpPorts'] == "443") or (endpoint['tcpPorts'] == "80")):
        cnt_apprules += 1
        if 'urls' in endpoint:
            new_rule = {
                'name': 'id' + str(endpoint['id']) + '-' + str(endpoint['serviceAreaDisplayName']).replace(" ", ""),
                'ruleType': 'ApplicationRule',
                'sourceAddresses': [ '*' ],
                'targetFqdns': verify_urls(endpoint['urls']),
                'protocols': []
            }
            dst_ports = str(endpoint['tcpPorts']).split(",")
            if '80' in dst_ports:
                new_rule['protocols'].append({'protocolType': 'Http', 'port': 80})
            if '443' in dst_ports:
                new_rule['protocols'].append({'protocolType': 'Https', 'port': 443})
            app_rules.append(new_rule)
        else:
            print('ERROR Endpoint ID {0} is web-based but does not have URLs'.format(endpoint['id']))
    # FQDN-based Net Rule
    else:
        cnt_netrules_fqdn += 1
        if ('urls' in endpoint) and (('tcpPorts' in endpoint) or ('udpPorts' in endpoint)):
            new_rule = {
                'name': 'id' + str(endpoint['id']) + '-' + str(endpoint['serviceAreaDisplayName']).replace(" ", ""),
                'ruleType': 'NetworkRule',
                'sourceAddresses': [ '*' ],
                'destinationAddresses': [],
                'destinationFqdns': endpoint['urls'],
            }
            if 'tcpPorts' in endpoint:
                new_rule['ipProtocols'] = [ 'tcp' ]
                new_rule['destinationPorts'] = str(endpoint['tcpPorts']).split(",")
            else:
                new_rule['ipProtocols'] = [ 'udp' ]
                new_rule['destinationPorts'] = str(endpoint['udpPorts']).split(",")
            net_rules.append(new_rule)
            # Watch out for UDP+TCP!
            if ('udpPorts' in endpoint) and ('tcpPorts' in endpoint):
                print("WARNING: Endpoint ID {0} has both TCP and UDP ports!".format(endpoint['id']))
        else:
            if not ('urls' in endpoint):
                print('ERROR: Endpoint ID {0} is IP-based with wildcards, but does not have urls'.format(endpoint['id']))
            if not ('udpPorts' in endpoint):
                print('ERROR: Endpoint ID {0} is IP-based with wildcards, but does not have udpPorts'.format(endpoint['id']))
            if args.verbose:
                print('DEBUG: endpoint:', str(endpoint))

##########
# Output #
##########

# Generate JSON would be creating an object and serialize it
if args.format == "json":
    api_version = "2021-02-01"
    azfw_policy_name = args.policy_name
    arm_template = {
        '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#',
        'contentVersion': '1.0.0.0',
        'parameters': {},
        'variables': {
            'location': '[resourceGroup().location]'
        },
        'resources': []
    }
    if not args.dont_create_policy:
        resource_policy = {
            'type': 'Microsoft.Network/firewallPolicies',
            'apiVersion': api_version,
            'name': azfw_policy_name,
            'location': '[variables(\'location\')]',
            'properties': {
                'sku': {
                    'tier': args.policy_sku
                },
                'dnsSettings': {
                    'enableProxy': 'true'
                },
                'threatIntelMode': 'Alert'
            }
        }
        arm_template['resources'].append(resource_policy)
    resource_rcg = {
        'type': 'Microsoft.Network/firewallPolicies/ruleCollectionGroups',
        'apiVersion': api_version,
        'name': azfw_policy_name + '/' + rcg_name,
        'dependsOn': [],
        'location': '[variables(\'location\')]',
        'properties': {
            'priority': rcg_prio,
            'ruleCollections': []
        }
    }
    if not args.dont_create_policy:
        resource_rcg['dependsOn'].append('[resourceId(\'Microsoft.Network/firewallPolicies\', \'' + azfw_policy_name +'\')]'),

    resource_net_rc = {
        'ruleCollectionType': 'FirewallPolicyFilterRuleCollection',
        'name': rc_net_name,
        'priority': rc_net_prio,
        'action': {
            'type': 'allow'
        },
        'rules': net_rules
    }
    resource_app_rc = {
        'ruleCollectionType': 'FirewallPolicyFilterRuleCollection',
        'name': rc_app_name,
        'priority': rc_app_prio,
        'action': {
            'type': 'allow'
        },
        'rules': app_rules
    }
    resource_rcg['properties']['ruleCollections'].append(resource_net_rc)
    resource_rcg['properties']['ruleCollections'].append(resource_app_rc)
    arm_template['resources'].append(resource_rcg)
    if args.pretty:
        print(json.dumps(arm_template, indent=4, sort_keys=True))
    else:
        print(json.dumps(arm_template))

elif args.format == "none":
    if args.verbose:
        print('DEBUG: {0} endpoints analized: {1} app rules, {2} FQDN-based net rules and {3} IP-based net rules'.format(str(cnt_endpoints), str(cnt_apprules), str(cnt_netrules_fqdn), str(cnt_netrules_ip)))
        # print('DEBUG: Net rules:', str(net_rules))
        # print('DEBUG: App rules:', str(app_rules))
else:
    print ("Format", args.format, "not recognized!")
