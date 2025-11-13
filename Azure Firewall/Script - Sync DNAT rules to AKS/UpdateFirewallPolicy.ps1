##############################################
# Script to sync Azure Firewall DNAT rules
#    to AKS services exposed via an Internal
#    Azure Load Balancer.
#
# Jose Moreno, 2025
##############################################


# Constants - consider moving some of these to parameters
$resourceGroup = "akstest"
$aksName = "aks"
$azfwPolicyResourceGroup = "akstest"
$azfwPolicyName = "myazfwpolicy"
$azfwRCG = "DNAT_rcg"
$azfwRC = "DNAT-rc"
$azfwPublicIP = "1.2.3.4"
$ruleSuffixLength = 5
$randomCharacters = 'abcdefghijklmnopqrstuvwxyz0123456789'.ToCharArray()

# Ensures you do not inherit an AzContext in your runbook
$null = Disable-AzContextAutosave -Scope Process
# Connect using a Managed Service Identity
try {
    Write-Output "Authenticating to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Output "There is no system-assigned user identity. Aborting."
    exit
}

###########################
#         START           #
###########################

# Getting AKS information about the node RG and the load balancer
try {
    $aks = Get-AzAksCluster -Name $aksName -ResourceGroupName $resourceGroup
    if ($null -ne $aks.Name) {
        Write-Output "AKS cluster $($aks.Name) found successfully in resource group $($resourceGroup)."
    }
    else {
        Write-Output "AKS cluster $($aksName) could not be found, aborting"
        exit
    }
}
catch {
    Write-Output "AKS cluster $($aksName) could not be found, aborting"
    exit
}
$aksALBs = Get-AzLoadBalancer -resourcegroup $aks.NodeResourceGroup
Write-Output "$($aksALBs.Length) Load Balancers found in node resource group $($aks.NodeResourceGroup)."
# Make sure the Azure Firewall policy and the RCG/RC exist
try {
    $policy = Get-AzFirewallPolicy -Name $azfwPolicyName -ResourceGroupName $azfwPolicyResourceGroup
    if ($null -ne $policy.Name) {
        Write-Output "Azure Firewall Policy $($policy.Name) found successfully in resource group $($azfwPolicyResourceGroup)."
    }
    else {
        Write-Output "Azure Firewall Policy $($azfwPolicyName) could not be found in resource group $($azfwPolicyResourceGroup), aborting"
        exit
    }
}
catch {
    Write-Output "Azure Firewall Policy $($azfwPolicyName) could not be found in resource group $($azfwPolicyResourceGroup), aborting"
    exit
}
try {
    $rcg = Get-AzFirewallPolicyRuleCollectionGroup -Name $azfwRCG -AzureFirewallPolicyName $azfwPolicyName -ResourceGroupName $azfwPolicyResourceGroup
    if ($null -ne $rcg.Name) {
        Write-Output "Rule Collection Group $($rcg.Name) in Azure Firewall Policy $($policy.Name) found successfully."
    }
    else {
        Write-Output "Rule Collection Group $($azfwRCG) could not be found in Azure Policy $($azfwPolicyName), aborting"
        exit
    }
}
catch {
    Write-Output "Rule Collection Group $($azfwRCG) could not be found in Azure Policy $($azfwPolicyName), aborting"
    exit
}
try {
    $rc = $rcg.properties.GetRuleCollectionByName($azfwRC)
    Write-Output "Rule Collection $($rc.Name) in RCG $($rcg.Name) in Azure Firewall Policy $($policy.Name) found successfully with $($rc.Rules.Length) existing rules."
}
catch {
    Write-Output "Rule Collection $($azfwRC) could not be found in Rule Collection Group $($azfwRCG) in Azure Policy $($azfwPolicyName), aborting"
    exit
}
$azfwRules = $rc.Rules
# Process the ALBs found in the node resource group
$ALBrules = @()
$ALBIPAddress = ""
foreach ($ALB in $aksALBs) {
    if ($ALB.Name -eq "kube-apiserver") {
        Write-Output "System ALB $($ALB.Name) found in node resource group $($aks.NodeResourceGroup), skipping"
    }
    elseif ($null -ne $ALB.FrontendIpConfigurations[0].PrivateIpAddress) {
        $ALBIPAddress = $ALB.FrontendIpConfigurations[0].PrivateIpAddress
        Write-Output "Internal ALB $($ALB.Name) found in node resource group $($aks.NodeResourceGroup) with private IP address $($ALBIPAddress), processing rules..."
        $ALBrules = $ALB.LoadBalancingRules
        foreach ($rule in $ALBrules) {
            # Find the frontend IP for the rule
            $FrontendConfigFound = $false
            $FrontendIP = ""
            foreach ($FrontendIPConfig in $ALB.FrontendIpConfigurations) {
                if ($FrontendIPConfig.Id -eq $rule.FrontendIPConfiguration.Id) {
                    $FrontendIP = $FrontendIPConfig.PrivateIpAddress
                    $FrontendConfigFound = $true
                }
            }
            # Output
            if ($FrontendConfigFound) {
                Write-Output "Rule $($rule.Name) found, frontend IP is $($FrontendIP), frontend port is $($rule.FrontendPort)."
                # Look for an existing rule in the firewall's RC matching this ALB rule
                $ruleMatchFound = $false
                foreach ($azfwRule in $azfwRules) {
                    if ($azfwRule.TranslatedPort -eq $rule.FrontendPort -And $azfwRule.TranslatedAddress -eq $FrontendIP) {
                        $ruleMatchFound = $true
                        Write-Output "Found matching rule $($azfwRule.Name) in the Azure Firewall rule collection."
                    }
                }
                if (-Not $ruleMatchFound) {
                    # DestinationPort = TranslatedPort ?
                    Write-Output ("Adding rule for $($FrontendIP):$($rule.FrontendPort), since no existing rule found in the firewall")
                    $randomSuffix = -join ($randomCharacters | Get-Random -Count $ruleSuffixLength)
                    $newrule = New-AzFirewallPolicyNatRule -Name $($rule.Name + '-' + $randomSuffix) -Protocol "TCP" -SourceAddress "*" -DestinationAddress $azfwPublicIP -DestinationPort $rule.FrontendPort -TranslatedAddress $FrontendIP -TranslatedPort $rule.FrontendPort
                    $rc.Rules.Add($newrule)
                    Write-Output "Rule collection now has $($rc.Rules.Length.Length) rules."            # For some reason the .Rules property is not a flat array
                }
            }
            else {
                Write-Output "Could not find frontend IP address for rule $($rule.Name), skipping."
            }
        }
    } else {
        Write-Output "Public ALB ${$ALB.Name} found in node resource group $($aks.NodeResourceGroup), skippping."
    }
}
# Go over the Firewall DNAT rules and remove anything that is not in the ALB rules
$rulesToRemove = @()
foreach ($azfwRule in $azfwRules) {
    $ruleMatchFound = $false
    Write-Output "Verifying whether Azure Firewall Rule $($azfwRule.Name) ($($azfwRule.TranslatedAddress):$($azfwRule.TranslatedPort)) has a corresponding rule in the AKS Load Balancer"
    foreach ($albRule in $ALBrules) {
        # Find the frontend IP for the rule
        $FrontendConfigFound = $false
        $FrontendIP = ""
        foreach ($FrontendIPConfig in $ALB.FrontendIpConfigurations) {
            if ($FrontendIPConfig.Id -eq $albRule.FrontendIPConfiguration.Id) {
                $FrontendIP = $FrontendIPConfig.PrivateIpAddress
                $FrontendConfigFound = $true
            }
        }
        if ($FrontendConfigFound) {
            if ($azfwRule.TranslatedPort -eq $albRule.FrontendPort -And $azfwRule.TranslatedAddress -eq $FrontendIP) {
                $ruleMatchFound = $true
                Write-Output "Found matching rule $($albRule.Name) ($($FrontendIP):$($albRule.FrontendPort)) in the Azure Load Balancer."
            } else {
                Write-Output "No match for ALB rule $($albRule.Name) ($($FrontendIP):$($albRule.FrontendPort))"
            }
        } else {
            Write-Output "Could not find frontend IP address for rule $($albRule.Name), skipping."
        }
    }
    if (-Not $ruleMatchFound) {
        Write-Output ("Removing rule $($azfwRule.Name) from rule collection, since no matching rule found in the AKS Load Balancer.")
        $rulesToRemove += $azfwRule.Name
    }
    else {
        Write-Output "Keeping rule $($azfwRule.Name), since a corresponding rule exists in the AKS Load Balancer."
    }
}
foreach ($rule in $rulesToRemove) {
    $rc.RemoveRuleByName($rule)
}
Write-Output "Rule collection now has $($rc.Rules.Length.Length) rules."
# Apply changes
try {
    Set-AzFirewallPolicyRuleCollectionGroup -Name $azfwRCG -FirewallPolicyObject $policy -Priority $rcg.Properties.Priority -RuleCollection $rc
    Write-Output "Firewall policy updated successfully."
} catch {
    Write-Error "Failed to update firewall policy: $($_.Exception.Message)"
}

