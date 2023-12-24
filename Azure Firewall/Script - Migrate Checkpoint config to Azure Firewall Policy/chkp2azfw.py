import argparse
import json
import re
import os
import sys
import copy
# https://docs.python.org/3/library/ipaddress.html
import ipaddress

# Helper functions

# Arguments
parser = argparse.ArgumentParser(description='Generate an ARM template to create a Rule Collection Group from a Checkpoint ruleset exported with the Show Package Tool (https://support.checkpoint.com/results/sk/sk120342).')
parser.add_argument('--json-index-file', dest='json_index_file', action='store',
                    default="./index.json",
                    help='Local file containing in JSON the links to the rest of the exported JSON files. The default is "./index.json"')
parser.add_argument('--policy-name', dest='policy_name', action='store',
                    default="azfwpolicy",
                    help='Name for the Azure Firewall Policy. The default is "azfwpolicy"')
parser.add_argument('--policy-sku', dest='policy_sku', action='store',
                    default="Standard",
                    help='SKU for the Azure Firewall Policy. Possible values: Standard, Premium (default: Standard)')
parser.add_argument('--do-not-create-policy', dest='dont_create_policy', action='store_true',
                    default=False,
                    help='If specified, do not include ARM code for the policy, only for the rule collection group. Use if the policy already exists.')
parser.add_argument('--rcg-name', dest='rcg_name', action='store',
                    default="importedFromCheckpoint",
                    help='Name for the Rule Collection Group to create in the Azure Firewall Policy. The default is "importedFromCheckpoint"')
parser.add_argument('--rcg-priority', dest='rcg_prio', action='store',
                    default="10000",
                    help='Priority for the Rule Collection Group to create in the Azure Firewall Policy. The default is "10000"')
parser.add_argument('--no-ip-groups', dest='use_ipgroups', action='store_false',
                    default=True,
                    help='Whether some address groups should be converted to Azure IP Groups (default: True)')
parser.add_argument('--no-app-rules', dest='use_apprules', action='store_false',
                    default=True,
                    help='Whether it will be attempted to convert network rules using HTTP/S to application rules. Note that this might be a problem if a explicit network deny exists (default: True)')
parser.add_argument('--max-ip-groups', dest='max_ipgroups', action='store', type=int, default=50,
                    help='Optional, maximum number of IP groups that will be created in Azure')
parser.add_argument('--rule-uid-to-name', dest='rule_id_to_name', action='store_true',
                    default=False,
                    help='Includes the UID of the Checkpoint rule in the name of the Azure rule, useful for troubleshooting (default: False)')
parser.add_argument('--remove-explicit-deny', dest='remove_explicit_deny', action='store_true',
                    default=False,
                    help='If a deny any/any is found, it will not be converted to the Azure Firewall syntax. Useful if using application rules (default: False)')
parser.add_argument('--output', dest='output', action='store',
                    default="none",
                    help='Output format. Possible values: json, none')
parser.add_argument('--pretty', dest='pretty', action='store_true',
                    default=False,
                    help='Print JSON in pretty mode (default: False)')
parser.add_argument('--log-level', dest='log_level_string', action='store',
                    default='warning',
                    help='Logging level (valid values: error/warning/info/debug/all/none. Default: warning)')
args = parser.parse_args()

# Variables
az_app_rcs = []
az_net_rcs = []
ipgroups = []
discarded_rules = []
rcg_name = args.rcg_name
rcg_prio = args.rcg_prio
rc_net_name = 'from-chkp-net'
rc_net_prio_start = "10000"
rc_app_name = 'from-chkp-app'
rc_app_prio_start = "11000"
cnt_apprules = 0
cnt_allow = 0
cnt_deny = 0
cnt_disabledrules = 0
cnt_apprules = 0
cnt_netrules_ip = 0
cnt_netrules_fqdn = 0
cnt_chkp_rules = 0

# Returns true if the string is a number
def is_number(value):
    for character in value:
        if character.isdigit():
            return True
    return False

# Returns a string formatted to be used as a name in Azure
def format_to_arm_name(name):
    name = name.replace(".", "-")
    name = name.replace("/", "-")
    name = name.replace(" ", "_")
    return name

# Returns true if the string is a UID
def is_uid(value):
    if len(value) == 36 and value[8] == '-' and value[13] == '-' and value[18] == '-' and value[23] == '-':
        return True

# Finds an object in a list by its UID
def find_uid(object_list, uid):
    for object in object_list:
        if object['uid'] == uid:
            return object
    return None

# Returns true if there is an IP group with the same chkp id
def is_ipgroup(ipgroup_list, uid):
    for ipgroup in ipgroup_list:
        if ipgroup['id'] == uid:
            return True
    return False

# Returns IP Group corresponding to the chkp id
def find_ipgroup(ipgroup_list, uid):
    for ipgroup in ipgroup_list:
        if ipgroup['id'] == uid:
            return ipgroup
    return None

# True if parameter is a valid FQDN according to RFCs 952, 1123
def is_fqdn(str_var):
    return bool(re.match(r"(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,4}$)",str(str_var)))

# True if parameter is a valid IP address (with or without mask)
# The regex is quite simple (for example it would match 999.999.999.999/99), but we assume that the IP addresses in the original policy are valid
def is_ipv4(str_var):
    return bool(re.match(r"^([0-9]{1,3}\.){3}[0-9]{1,3}($|/[0-9]{1,2}$)",str(str_var)))

# Perform some checks on the rule to add, and append it to the list of rules provided in the 2nd argument
# Some rules need to be broken down in multiple ones, so the function adds a suffix to the created rules in this case
def append_rule(rule_to_be_appended, rules_to_append_to):
    if log_level >= 8:
        print("DEBUG: appending to rules:", str(rule_to_be_appended), file=sys.stderr)
    src_fields = ('sourceAddresses', 'sourceIpGroups', 'sourceServiceTags')
    dst_fields = ('destinationAddresses', 'destinationIpGroups', 'destinationFqdns', 'destinationServiceTags')
    all_fields = src_fields + dst_fields
    # Count how many rules we will be splitting (to avoid unnecessary suffixes if there is only one rule)
    total_rule_no = 0
    for src_field in src_fields:
        for dst_field in dst_fields:
            if len(rule_to_be_appended[src_field]) > 0 and len(rule_to_be_appended[dst_field]) > 0:
                total_rule_no += 1
    # Process the rule
    split_rule_counter = 0
    for src_field in src_fields:
        for dst_field in dst_fields:
            # Only look at combinations where the src_field and dst_field are non-zero
            if len(rule_to_be_appended[src_field]) > 0 and len(rule_to_be_appended[dst_field]) > 0:
                # Should we split a rule that contains both IP addresses and service tags in either sourceAddresses or destinationAddresses?
                temp_rule = copy.copy(rule_to_be_appended)
                split_rule_counter += 1
                if total_rule_no > 1:
                    temp_rule['name'] = temp_rule['name'] + '-' + str(split_rule_counter)
                else:
                    temp_rule['name'] = temp_rule['name']
                # Blank all the rest fields
                for blank_field in all_fields:
                    if blank_field != src_field and blank_field != dst_field:
                        temp_rule [blank_field] = []
                rules_to_append_to.append(temp_rule)
                # The fields 'sourceServiceTags' and 'destinationServiceTags' are not supported in Azure Firewall, so we need to change them to 'sourceAddresses' and 'destinationAddresses'
                if src_field == 'sourceServiceTags':
                    temp_rule['sourceAddresses'] = temp_rule['sourceServiceTags']
                    temp_rule.pop('sourceServiceTags')
                if dst_field == 'destinationServiceTags':
                    temp_rule['destinationAddresses'] = temp_rule['destinationServiceTags']
                    temp_rule.pop('destinationServiceTags')
    if split_rule_counter > 1:
        if log_level >= 7:
            print("DEBUG: Checkpoint rule {0} has been split in {1} Azure Firewall rules".format(rule_to_be_appended['name'], split_rule_counter), file=sys.stderr)
    return rules_to_append_to

# Recursively finds all members of objects by their UID
def find_members(object_group_list, uid_list, member_list=[], debug=False, mode='ip'):
    # if debug:
    #     print("DEBUG: looking for UIDs '{0}'...".format(str(uid_list)), file=sys.stderr)
    # Make sure that the uid is a list
    if not isinstance(uid_list, list):
        uid_list = [uid_list]
    # Loop through all objects
    for object_group in object_group_list:
        if object_group['uid'] in uid_list:
            # if debug:
            #     print('DEBUG: found matching object', str(object_group), file=sys.stderr)
            if 'members' in object_group:
                if len(object_group['members']) > 0:
                    for member in object_group['members']:
                        if is_uid(member):
                            member_list = find_members(object_group_list, member, member_list=member_list)
                else:
                    if debug:
                        print('DEBUG: object group {0} has no members.'.format(str(object_group['name'])), file=sys.stderr)
            elif object_group['type'] == 'network':
                member_list.append(object_group['subnet4'] + '/' + str(object_group['mask-length4']))
            elif object_group['type'] == 'host':
                member_list.append(object_group['ipv4-address'] + '/32')
            elif object_group['type'] == 'dns-domain':
                member_list.append(str(object_group['name'])[1:])    # In checkpoint syntax, fqdn starts with a dot
            elif object_group['type'] == 'dynamic-object':  # Service Tag "AVDServiceRanges"
                if debug:
                    print('DEBUG: adding dynamic-object {0}'.format(object_group['name']), str(object_group), file=sys.stderr)
                if object_group['name'] == 'AVDServiceRanges':
                    member_list.append('WindowsVirtualDesktop')
                else:
                    if log_level >= 3:
                        print('ERROR: dynamic-object {0} cannot be mapped to an Azure service tag'.format(object_group['name']), file=sys.stderr)
            elif object_group['type'] == 'service-tcp':
                member_list.append(('tcp', object_group['port']))
            elif object_group['type'] == 'service-udp':
                member_list.append(('udp', object_group['port']))
            elif object_group['type'] == 'service-icmp':
                member_list.append(('icmp', '*'))
            elif object_group['type'] == 'CpmiAnyObject':
                if (mode == 'ip'):
                    member_list.append('*')
                else:
                    member_list.append(('any', '*'))
            elif object_group['type'] == 'RulebaseAction':
                member_list.append(object_group['name'])
            elif object_group['type'] in ('CpmiGatewayCluster', 'CpmiClusterMember', 'CpmiHostCkp', 'simple-cluster', 'Global'):
                if debug:
                    print('DEBUG: ignoring object type', object_group['type'], file=sys.stderr)
            else:
                if debug:
                    print('DEBUG: unknown object type', object_group['type'], file=sys.stderr)
    return list(set(member_list))

# Set log_level
if is_number(args.log_level_string):
    try:
        log_level = int(args.log_level_string)
    except:
        log_level = 4
else:
    if args.log_level_string == 'error':
        log_level = 3
    elif args.log_level_string == 'warning':
        log_level = 4
    elif args.log_level_string == 'notice':
        log_level = 5
    elif args.log_level_string == 'info':
        log_level = 6
    elif args.log_level_string == 'debug' or args.log_level_string == 'all':
        log_level = 7
    elif args.log_level_string == 'debugplus' or args.log_level_string == 'all':
        log_level = 8
    elif args.log_level_string == 'none':
        log_level = 0
    else:
        log_level = 4   # We default to 'warning'

# Get JSON index file list from the specified folder
if log_level > 7:
    print ("DEBUG: Loading file {0}...".format(args.json_index_file), file=sys.stderr)
try:
    with open(args.json_index_file) as f:
        json_index = json.load(f)
except Exception as e:
    if log_level >= 3:
        print("ERROR: Error when opening JSON index file", args.json_index_file, "-", str(e), file=sys.stderr)
    sys.exit(0)

# Go through the files and create the objects
access_layers = []
threat_layers = []
nat_layers = []
for package in json_index['policyPackages']:
    if 'objects' in package:
        if log_level >= 7:
            print ("DEBUG: Objects section found, file {0}...".format(package['objects']['htmlObjectsFileName']), file=sys.stderr)
        filename = package['objects']['htmlObjectsFileName']
        try:
            # Try to open the file with JSON extension
            filename = os.path.splitext(package['objects']['htmlObjectsFileName'])[0]+'.json'
            with open(filename) as f:
                policy_objects = json.load(f)
            if log_level >= 7:
                print ("DEBUG: File {0} loaded successfully".format(filename), file=sys.stderr)
        except Exception as e:
            if log_level >= 4:
                print("WARNING: Error when opening JSON file", filename, "-", str(e), file=sys.stderr)
            pass
    if 'accessLayers' in package:
        for layer in package['accessLayers']:
            if 'htmlFileName' in layer:
                if log_level >= 7:
                    print ("DEBUG: Access layer found, file {0}...".format(layer['htmlFileName']), file=sys.stderr)
                filename = layer['htmlFileName']
                try:
                    # Try to open the file with JSON extension
                    filename = os.path.splitext(layer['htmlFileName'])[0]+'.json'
                    with open(filename) as f:
                        access_layers.append(json.load(f))
                    if log_level >= 7:
                        print ("DEBUG: File {0} loaded successfully".format(filename), file=sys.stderr)
                except Exception as e:
                    if log_level >= 4:
                        print("WARNING: Error when opening JSON file for access layer", filename, "-", str(e), file=sys.stderr)
                    pass
    if 'threatLayers' in package:
        for layer in package['threatLayers']:
            if 'htmlFileName' in layer:
                if log_level >= 7:
                    print ("DEBUG: Threat layer found, file {0}...".format(layer['htmlFileName']), file=sys.stderr)
                filename = layer['htmlFileName']
                try:
                    filename = os.path.splitext(layer['htmlFileName'])[0] + '.json'
                    with open(filename) as f:
                        threat_layers.append(json.load(f))
                    if log_level >= 7:
                        print ("DEBUG: File {0} loaded successfully".format(filename), file=sys.stderr)
                except Exception as e:
                    if log_level >= 4:
                        print("WARNING: Error when opening JSON file for threat layer", filename, "-", str(e), file=sys.stderr)
                    pass
    if 'natLayer' in package:
        layer = package['natLayer']
        if 'htmlFileName' in layer:
            if log_level >= 7:
                print ("DEBUG: NAT layer found, file {0}...".format(layer['htmlFileName']), file=sys.stderr)
            filename = layer['htmlFileName']
            try:
                # Try to open the file with JSON extension
                filename = os.path.splitext(layer['htmlFileName'])[0]+'.json'
                with open(filename) as f:
                    # nat_layer = json.load(f)
                    nat_layers.append(json.load(f))
                if log_level >= 7:
                    print ("DEBUG: File {0} loaded successfully".format(filename), file=sys.stderr)
            except Exception as e:
                if log_level >= 4:
                    print("WARNING: Error when opening JSON file for NAT layer", filename, "-", str(e), file=sys.stderr)
                pass

# Inspect the imported objects
# policy_object_types = []
# for policy_object in policy_objects:
#     if 'type' in policy_object:
#         if not policy_object['type'] in policy_object_types:
#             policy_object_types.append(policy_object['type'])
# if log_level >= 7:
#     print('Policy object types found:', str(policy_object_types))
# Policy object types found: ['vpn-community-star', 'RulebaseAction', 'CpmiAnyObject', 'service-group', 'group', 'Track', 'Global', 'service-tcp', 'network', 'dynamic-object', 'host', 'CpmiHostCkp', 'service-icmp', 'service-other', 'threat-profile', 'ThreatExceptionRulebase', 'service-udp', 'dns-domain', 'simple-cluster', 'CpmiClusterMember']

# Inspect the imported access layers
def inspect_access_layers(layer_list):
    for layer in layer_list:
        for rule in layer:
            # Check rule is a dictionary and contains a type key
            if isinstance(rule, dict) and 'type' in rule:
                if rule['type'] == 'access-rule':
                    # Rule Name
                    rule_name = rule['name'] if len(rule['name']) <= 38 else rule['name'][:38]
                    # action/src/dst/svc object Members
                    rule_action_members_str = str(find_members(policy_objects, rule['action'], member_list=[])[0])
                    rule_src_members = find_members(policy_objects, rule['source'], member_list=[], mode='ip')
                    rule_src_members_str = str(rule_src_members) if len(str(rule_src_members)) <= 38 else str(rule_src_members)[:38]
                    rule_dst_members = find_members(policy_objects, rule['destination'], member_list=[], mode='ip')
                    rule_dst_members_str = str(rule_dst_members) if len(str(rule_dst_members)) <= 38 else str(rule_dst_members)[:38]
                    rule_svc_members = find_members(policy_objects, rule['service'], member_list=[], mode='svc')
                    rule_svc_members_str = str(rule_svc_members) if len(str(rule_svc_members)) <= 38 else str(rule_svc_members)[:38]
                    # For each group ID used as source or destination, create an IP group object
                    if len(rule_src_members) > 0:
                        for src in rule['source']:
                            if not is_ipgroup(ipgroups, src):
                                ipgroups.append({'id': src, 'members': rule_src_members, 'member_count': len(rule_src_members), 'name': find_uid(policy_objects, src)['name']})
                    if len(rule_dst_members) > 0:
                        for dst in rule['destination']:
                            if not is_ipgroup(ipgroups, dst):
                                ipgroups.append({'id': dst, 'members': rule_dst_members, 'member_count': len(rule_dst_members), 'name': find_uid(policy_objects, dst)['name']})
                elif rule['type'] == 'nat-rule':
                    if log_level >= 7:
                        print('DEBUG: processing NAT rule', rule['rule-number'], file=sys.stderr)
                elif rule['type'] == 'threat-rule':
                    if log_level >= 7:
                        print('DEBUG: processing Threat rule', rule['rule-number'], file=sys.stderr)
                else:
                    if log_level >= 7:
                        print('DEBUG: ignoring rule of type', rule['type'], file=sys.stderr)
            else:
                print('ERROR: Rule is not a dictionary or does not contain a type key:', str(rule), file=sys.stderr)

def print_access_layer_rule(layer_list, rule_id_list, debug=False):
    for layer in layer_list:
        if log_level >= 7:
            print('{0:<40}{1:<40}{2:<40}{3:<40}{4:<40}'.format('Name', 'Action', 'Source', 'Destination', 'Service'), file=sys.stderr)
        for rule in layer:
            # Check rule is a dictionary and contains a type key
            if isinstance(rule, dict) and 'type' in rule:
                if rule['type'] == 'access-rule' and rule['uid'] in rule_id_list:
                    # Rule Name
                    rule_name = rule['name'] if len(rule['name']) <= 38 else rule['name'][:38]
                    # action/src/dst/svc object Members
                    rule_action_members_str = str(find_members(policy_objects, rule['action'], member_list=[])[0])
                    rule_src_members = find_members(policy_objects, rule['source'], member_list=[], mode='ip', debug=debug)
                    rule_src_members_str = str(rule_src_members) if len(str(rule_src_members)) <= 38 else str(rule_src_members)[:38]
                    rule_dst_members = find_members(policy_objects, rule['destination'], member_list=[], mode='ip', debug=debug)
                    rule_dst_members_str = str(rule_dst_members) if len(str(rule_dst_members)) <= 38 else str(rule_dst_members)[:38]
                    rule_svc_members = find_members(policy_objects, rule['service'], member_list=[], mode='svc', debug=debug)
                    rule_svc_members_str = str(rule_svc_members) if len(str(rule_svc_members)) <= 38 else str(rule_svc_members)[:38]
                    # Print
                    if log_level >= 7:
                        print('{0:<40}{1:<40}{2:<40}{3:<40}{4:<40}'.format(rule_name, rule_action_members_str, rule_src_members_str, rule_dst_members_str, rule_svc_members_str), file=sys.stderr)

# Process the imported access layers. inspect_access_layers needs to have run first to create the list of IP groups
def process_access_layers(layer_list, ipgroups):
    global cnt_netrules_ip, cnt_netrules_fqdn, cnt_chkp_rules
    last_action = None
    for layer in layer_list:
        for rule in layer:
            # Check rule is a dictionary and contains a type key
            if isinstance(rule, dict) and 'type' in rule:
                if rule['type'] == 'access-rule':
                    cnt_chkp_rules += 1
                    # Rule Name and action
                    rule_name = rule['name']
                    rule_action = str(find_members(policy_objects, rule['action'], member_list=[])[0])
                    # If there is a change from deny to allow, or from allow to deny, or if this is the first rule, we need to create a rule collection
                    if rule_action != last_action:
                        rule_collection = {
                            'name': rc_net_name + '-' + rule_action + '-' + str(len(az_net_rcs)),
                            'action': rule_action,
                            'rules': []
                        }
                        # Append the rule collection to the list of rule collections and set last_action to the new value
                        az_net_rcs.append(rule_collection)
                        last_action = rule_action
                    # action/src/dst/svc object Members
                    rule_src_members = find_members(policy_objects, rule['source'], member_list=[], mode='ip')
                    rule_dst_members = find_members(policy_objects, rule['destination'], member_list=[], mode='ip')
                    rule_svc_members = find_members(policy_objects, rule['service'], member_list=[], mode='svc')
                    # Print
                    if len(rule_src_members) > 0 and len(rule_dst_members) > 0 and len(rule_svc_members) > 0:
                        # 'sourceServiceTags' and 'destinationServiceTags' are auxiliary fields, since the service tags go actually in the 'sourceAddresses' and 'destinationAddresses' fields
                        # The fields will be removed in the function append_rule
                        new_rule = {
                            'name': rule['name'] + '-' + str(rule['uid']),
                            'ruleType': 'NetworkRule',
                            'sourceAddresses': [],
                            'sourceIpGroups': [],
                            'destinationAddresses': [],
                            'destinationFqdns': [],
                            'destinationIpGroups': [],
                            'sourceServiceTags': [],
                            'destinationServiceTags': []
                        }
                        if not args.rule_id_to_name:
                            new_rule['name'] = rule['name']
                        if len(rule_src_members) == 1 and is_ipgroup(ipgroups, rule_src_members[0]):
                            new_rule['sourceIpGroups'].append(find_ipgroup(ipgroups, rule_src_members[0]))['name']
                        else:
                            for src in rule_src_members:
                                if src == 'any' or src == '*' or 'any' in src or src[0] == 'any':
                                    new_rule['sourceAddresses'] = [ '*' ]
                                elif is_ipv4(src):
                                    if src not in new_rule['sourceAddresses']:
                                        new_rule['sourceAddresses'].append(src)
                                # If not an IP address, it must be a service tag
                                elif src not in new_rule['sourceAddresses']:
                                    if src not in new_rule['sourceServiceTags']:
                                        new_rule['sourceServiceTags'].append(src)
                        if len(rule_dst_members) == 1 and is_ipgroup(ipgroups, rule_dst_members[0]):
                            new_rule['destinationIpGroups'].append(find_ipgroup(ipgroups, rule_dst_members[0]))['name']
                        else:
                            for dst in rule_dst_members:
                                if dst == 'any' or dst == '*' or 'any' in dst:
                                    cnt_netrules_ip += 1
                                    new_rule['destinationAddresses'] = [ '*' ]
                                elif is_fqdn(dst):
                                    cnt_netrules_fqdn += 1
                                    if dst not in new_rule['destinationFqdns']:
                                        cnt_netrules_fqdn += 1
                                        new_rule['destinationFqdns'].append(dst)
                                elif is_ipv4(dst):
                                    if dst not in new_rule['destinationAddresses']:
                                        cnt_netrules_ip += 1
                                        new_rule['destinationAddresses'].append(dst)
                                # If not an IP address or a domain name, it must be a service tag
                                else:
                                    if dst not in new_rule['destinationServiceTags']:
                                        new_rule['destinationServiceTags'].append(dst)
                        # Services are in an array of 2-tuples (protocol, port)
                        if 'any' in rule_svc_members:
                            new_rule['ipProtocols'] = ['Any']
                            new_rule['destinationPorts'] = [ '*' ]
                        else:
                            new_rule['ipProtocols'] = []
                            new_rule['destinationPorts'] = []
                            for svc in rule_svc_members:
                                protocol = svc[0]
                                port = svc[1]
                                if protocol == 'tcp' or protocol == 'udp':
                                    if protocol not in new_rule['ipProtocols']:
                                        new_rule['ipProtocols'].append(protocol)
                                    if port not in new_rule['destinationPorts']:
                                        # Checkpoint accepts the syntax >1024, but Azure does not
                                        if port[0] == '>':
                                            new_rule['destinationPorts'].append(str(int(port[1:]) + 1) + '-65535')
                                        else:
                                            new_rule['destinationPorts'].append(port)
                                elif protocol == 'icmp':
                                    if protocol not in new_rule['ipProtocols']:
                                        new_rule['ipProtocols'].append(protocol)
                                    new_rule['destinationPorts'] = [ '*' ]
                                elif protocol == 'any':
                                    new_rule['ipProtocols'] = ['Any']
                                    new_rule['destinationPorts'] = [ '*' ]
                                else:
                                    print('ERROR: Unknown service protocol', protocol, 'in rule', rule_name, file=sys.stderr)
                        # Add new rule to the latest rule collection (the one we are working on)
                        if args.remove_explicit_deny and rule_action == 'Drop' and new_rule['sourceAddresses'] == [ '*' ] and new_rule['destinationAddresses'] == [ '*' ] and new_rule['destinationPorts'] == [ '*' ] and new_rule['ipProtocols'] == ['Any']:
                            discarded_rules.append(rule['uid'])
                            if log_level >= 6:
                                print('INFO: Skipping rule "{0}" as it is an explicit catch-all deny rule'.format(rule_name), file=sys.stderr)
                        else:
                            az_net_rcs[-1]['rules'] = append_rule(new_rule, az_net_rcs[-1]['rules'])
                    # If one of the objects was empty, add to the discarded rules
                    else:
                        discarded_rules.append(rule['uid'])


# Inspect the imported NAT layers
def inspect_nat_layers(layer_list):
    for layer in layer_list:
        print('{0:<5}{1:<20}{2:<20}{3:<20}{4:<20}{5:<20}{6:<20}'.format('ID', 'Original Src', 'Translated Src', 'Original Dst', 'Translated Dst', 'Original Svc', 'Translated Svc'), file=sys.stderr)
        for rule in layer:
            # Check rule is a dictionary and contains a type key
            if isinstance(rule, dict) and 'type' in rule:
                if rule['type'] == 'nat-rule':
                    if log_level >= 7:
                        # Rule ID
                        rule_id = rule['rule-number']
                        # src/dst/svc object Members
                        rule_osrc_members = find_members(policy_objects, rule['original-source'], member_list=[], mode='ip')
                        rule_osrc_members_str = str(rule_osrc_members) if len(str(rule_osrc_members)) <= 38 else str(rule_osrc_members)[:38]
                        rule_tsrc_members = find_members(policy_objects, rule['translated-source'], member_list=[], mode='ip')
                        rule_tsrc_members_str = str(rule_tsrc_members) if len(str(rule_tsrc_members)) <= 38 else str(rule_tsrc_members)[:38]
                        rule_odst_members = find_members(policy_objects, rule['original-destination'], member_list=[], mode='ip')
                        rule_odst_members_str = str(rule_odst_members) if len(str(rule_odst_members)) <= 38 else str(rule_odst_members)[:38]
                        rule_tdst_members = find_members(policy_objects, rule['translated-destination'], member_list=[], mode='ip')
                        rule_tdst_members_str = str(rule_tdst_members) if len(str(rule_tdst_members)) <= 38 else str(rule_tdst_members)[:38]
                        rule_osvc_members = find_members(policy_objects, rule['original-service'], member_list=[], mode='svc')
                        rule_osvc_members_str = str(rule_osvc_members) if len(str(rule_osvc_members)) <= 38 else str(rule_osvc_members)[:38]
                        rule_tsvc_members = find_members(policy_objects, rule['translated-service'], member_list=[], mode='svc')
                        rule_tsvc_members_str = str(rule_tsvc_members) if len(str(rule_tsvc_members)) <= 38 else str(rule_tsvc_members)[:38]
                        # Print
                        print('{0:<5}{1:<20}{2:<20}{3:<20}{4:<20}{5:<20}{6:<20}'.format(rule_id, rule_osrc_members_str, rule_tsrc_members_str, rule_odst_members_str, rule_tdst_members_str, rule_osvc_members_str, rule_tsvc_members_str), file=sys.stderr)
                else:
                    if log_level >= 7:
                        print('DEBUG: ignoring rule of type', rule['type'])
            else:
                print('ERROR: Rule is not a dictionary or does not contain a type key:', str(rule))


if log_level >= 7:
    print('DEBUG: Access layers found:', file=sys.stderr)
inspect_access_layers(access_layers)

# Other types of layers (not required)
# if log_level >= 7:
#     print('DEBUG: Threat layers found:')
# inspect_access_layers(threat_layers)
# if log_level >= 7:
#     print('DEBUG: NAT layer found:')
# inspect_nat_layers(nat_layers)

# Remove ipgroups that contain FQDNs
ipgroups_copy = ipgroups.copy()
for ipgroup in ipgroups_copy:
    for x in ipgroup['members']:
        if is_fqdn(x):
            if log_level >= 7:
                print('DEBUG: Removing IP group', ipgroup['name'], 'because it contains FQDN', x, '(IP Groups can only contain IP addresses)', file=sys.stderr)
            ipgroups.remove(ipgroup)
            break
if log_level >= 6:
    print('INFO: {0} out of {1} IP Groups remain after removing FQDNs'.format(len(ipgroups), len(ipgroups_copy)), file=sys.stderr)

# Show ipgroups
ipgroups = sorted(ipgroups, key=lambda d: d['member_count'], reverse=True)
if log_level >= 6:
    print('INFO: {0} IP groups found, capping them to the top {1}'.format(len(ipgroups), args.max_ipgroups), file=sys.stderr)
ipgroups = ipgroups[:args.max_ipgroups]
if log_level >= 8:
    print('{0:<50}{1:<38}{2:<5}{3:<80}'.format('IP group name', 'CHKP ID', 'Count', 'IP addresses'), file=sys.stderr)
    for ipgroup in ipgroups:
        ipgroup_members = str(ipgroup['members']) if len(str(ipgroup['members'])) <= 80 else str(ipgroup['members'])[:80]

        print('{0:<50}{1:<38}{2:<5}{3:<50}'.format(ipgroup['name'], ipgroup['id'], str(ipgroup['member_count']), ipgroup_members), file=sys.stderr)

# Check whether any IP group is repeated
if len(list(set([x['id'] for x in ipgroups]))) != len(ipgroups):
    if log_level >= 4:
        print('ERROR: IP groups with repeated IDs found', file=sys.stderr)
if len(list(set([x['name'] for x in ipgroups]))) != len(ipgroups):
    if log_level >= 4:
        print('ERROR: IP groups with repeated names found', file=sys.stderr)

# Process rules
process_access_layers(access_layers, ipgroups)
if log_level >= 6:
    print('INFO: {0} network rules found, spread across {1} rule collections ({2} allow rules, {3} deny rules)'.format(sum([len(x['rules']) for x in az_net_rcs]), len(az_net_rcs), sum([len(x['rules']) for x in az_net_rcs if x['action'] == 'Accept']), sum([len(x['rules']) for x in az_net_rcs if x['action'] == 'Drop'])), file=sys.stderr)

# Now we should have all rules stored as network rule collections. Check whether any can be transformed in an application rule
# App rules need to go into their own rule collections
def create_app_rules(net_rcs):
    last_action = None
    app_rcs = []
    # Loop through a copy of the rules (you cannot change a list while looping through it)
    net_rcs_copy = net_rcs.copy()
    for net_rc in net_rcs_copy:
        for net_rule in net_rc['rules']:
            # Check whether the rule is for ports 80/443, and whether the target is a FQDN
            if set(net_rule['destinationPorts']) in ({'80', '443'}, {'80'}, {'443'}) and len(net_rule['destinationFqdns']) > 0:
                if log_level >= 7:
                    print('DEBUG: Transforming rule', net_rule['name'], 'to an application rule', file=sys.stderr)
                if net_rc['action'] != last_action:
                    rule_collection = {
                        'name': rc_app_name + '-' + net_rc['action'] + '-' + str(len(az_app_rcs)),
                        'action': net_rc['action'],
                        'rules': []
                    }
                    # Append the rule collection to the list of rule collections and set last_action to the new value
                    app_rcs.append(rule_collection)
                    last_action = net_rc['action']
                # Remove the rule from net_rules
                net_rc['rules'].remove(net_rule)
                # Change the rule type
                net_rule['ruleType'] = 'applicationRule'
                # Change the ipProtocols/destinationPorts
                net_rule.pop('ipProtocols')
                net_rule['protocols'] = []
                if '80' in net_rule['destinationPorts']:
                    net_rule['protocols'].append({'protocolType': 'Http', 'port': 80})
                if '443' in net_rule['destinationPorts']:
                    net_rule['protocols'].append({'protocolType': 'Https', 'port': 443})
                    net_rule['terminateTls'] = False
                net_rule.pop('destinationPorts')
                # Set some app rule attributes
                net_rule['targetFqdns'] = net_rule['destinationFqdns']
                net_rule.pop('destinationFqdns')
                net_rule['targetUrls'] = []
                net_rule['webCategories'] = []
                net_rule['fqdnTags'] = []
                # Add the rule to the last app rule collection
                app_rcs[-1]['rules'].append(net_rule)
    # Finished
    return net_rcs, app_rcs
# Inspect both allow and deny network rules for candidates to transform into application rules
if args.use_apprules:
    if log_level >= 7:
        print('DEBUG: Checking whether any network rule can be transformed to an application rule', file=sys.stderr)
    # az_net_rules_allow, az_app_rules_allow = create_app_rules(az_net_rules_allow, az_app_rules_allow)
    # az_net_rules_deny, az_app_rules_deny = create_app_rules(az_net_rules_deny, az_app_rules_deny)
    az_net_rcs, az_app_rcs = create_app_rules(az_net_rcs)


##########
# Output #
##########

# Generate JSON would be creating an object and serialize it
if args.output == "json":
    api_version = "2021-08-01"
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

    if args.use_ipgroups:
        for ip_grp in ipgroups:
            resource_ipgroup = {
                'type': 'Microsoft.Network/ipGroups',
                'apiVersion': api_version,
                'name': format_to_arm_name(ip_grp['name']),
                'location': '[variables(\'location\')]',
                'properties': {
                    'ipAddresses': ip_grp['members']
                }
            }
            arm_template['resources'].append(resource_ipgroup)
            resource_rcg['dependsOn'].append("[resourceId('Microsoft.Network/ipGroups', '{0}')]".format(format_to_arm_name(ip_grp['name'])))

    # Add network rule collections to the template
    rc_net_prio = int(rc_net_prio_start)
    for net_rc in az_net_rcs:
        resource_rcg['properties']['ruleCollections'].append({
            'ruleCollectionType': 'FirewallPolicyFilterRuleCollection',
            'name': net_rc['name'],
            'priority': str(rc_net_prio),
            'action': {
                'type': 'deny' if net_rc['action'] == 'Drop' else 'allow'
            },
            'rules': net_rc['rules']
        })
        rc_net_prio += 10

    # Add application rule collections to the template
    rc_app_prio = int(rc_app_prio_start)
    for app_rc in az_app_rcs:
        resource_rcg['properties']['ruleCollections'].append({
            'ruleCollectionType': 'FirewallPolicyFilterRuleCollection',
            'name': app_rc['name'],
            'priority': str(rc_app_prio),
            'action': {
                'type': 'deny' if app_rc['action'] == 'Drop' else 'allow'
            },
            'rules': app_rc['rules']
        })
        rc_app_prio += 10

    # if len(az_net_rules_allow) > 0:
    #     resource_rcg['properties']['ruleCollections'].append(resource_net_rc_allow)
    # if len(az_net_rules_deny) > 0:
    #     resource_rcg['properties']['ruleCollections'].append(resource_net_rc_deny)
    # if len(az_app_rules_allow) > 0:
    #     resource_rcg['properties']['ruleCollections'].append(resource_app_rc_allow)
    # if len(az_app_rules_deny) > 0:
    #     resource_rcg['properties']['ruleCollections'].append(resource_app_rc_deny)
    arm_template['resources'].append(resource_rcg)
    if args.pretty:
        print(json.dumps(arm_template, indent=4, sort_keys=True))
    else:
        print(json.dumps(arm_template))
elif args.output == "none":
    if log_level >= 6:
        print('INFO: No output type selected', file=sys.stderr)
else:
    if log_level >= 3:
        print ("ERROR: Output type", args.output, "not recognized!", file=sys.stderr)

# Last info message
if log_level >= 6:
    print('INFO: Summary:', file=sys.stderr)
    print('INFO: {0} Checkpoint rules analized'.format(str(cnt_chkp_rules)), file=sys.stderr)
    print('INFO: {0} Azure Firewall network rules, spread across {1} rule collections ({2} allow rules, {3} deny rules)'.format(sum([len(x['rules']) for x in az_net_rcs]), len(az_net_rcs), sum([len(x['rules']) for x in az_net_rcs if x['action'] == 'Accept']), sum([len(x['rules']) for x in az_net_rcs if x['action'] == 'Drop'])), file=sys.stderr)
    print('INFO: {0} Azure Firewall application rules, spread across {1} rule collections ({2} allow rules, {3} deny rules)'.format(sum([len(x['rules']) for x in az_app_rcs]), len(az_app_rcs), sum([len(x['rules']) for x in az_app_rcs if x['action'] == 'Accept']), sum([len(x['rules']) for x in az_app_rcs if x['action'] == 'Drop'])), file=sys.stderr)
    print('INFO: {0} Checkpoint discarded rules:'.format(len(discarded_rules)), file=sys.stderr)
    print_access_layer_rule(access_layers, discarded_rules, debug=True)
