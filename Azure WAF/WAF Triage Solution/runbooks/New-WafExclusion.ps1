<#
.SYNOPSIS
    Azure Automation Runbook to create WAF exclusions or disable rules for Application Gateway WAF policies.

.DESCRIPTION
    This runbook modifies Azure Application Gateway WAF policies.
    It can be triggered manually, via webhook, or from Azure Logic Apps.

    Supported actions:
    - createExclusion (default): Creates per-rule, per-group, or global exclusions
    - disableRule: Disables a specific managed rule in the WAF policy

    Match Variables (for createExclusion):
    - RequestHeaderValues, RequestHeaderNames, RequestHeaderKeys
    - RequestCookieValues, RequestCookieNames, RequestCookieKeys
    - RequestArgValues, RequestArgNames, RequestArgKeys

.PARAMETER Action
    The action to perform: 'createExclusion' (default) or 'disableRule'.
    - createExclusion: Requires MatchVariable, SelectorMatchOperator, Selector
    - disableRule: Requires RuleId, RuleGroupName, RuleSetType, RuleSetVersion

.PARAMETER ResourceGroupName
    The resource group containing the WAF policy.

.PARAMETER WafPolicyName
    The name of the WAF policy to update.

.PARAMETER RuleId
    The specific rule ID to create exclusion for (optional - if not provided, creates global exclusion).

.PARAMETER RuleGroupName
    The rule group name (e.g., 'REQUEST-942-APPLICATION-ATTACK-SQLI').

.PARAMETER RuleSetType
    The rule set type: 'OWASP', 'Microsoft_DefaultRuleSet', or 'Microsoft_BotManagerRuleSet'.

.PARAMETER RuleSetVersion
    The rule set version (e.g., '3.2', '2.1', '1.0').

.PARAMETER MatchVariable
    The match variable for the exclusion.
    Valid values: RequestHeaderValues, RequestHeaderNames, RequestHeaderKeys,
                  RequestCookieValues, RequestCookieNames, RequestCookieKeys,
                  RequestArgValues, RequestArgNames, RequestArgKeys

.PARAMETER SelectorMatchOperator
    The selector match operator.
    Valid values: Equals, StartsWith, EndsWith, Contains, EqualsAny

.PARAMETER Selector
    The selector value (the specific header/cookie/argument name to exclude).

.PARAMETER Description
    Optional description for logging purposes.

.EXAMPLE
    # Create a per-rule exclusion
    .\New-WafExclusion.ps1 `
        -ResourceGroupName "rg-waf" `
        -WafPolicyName "waf-policy-prod" `
        -RuleId "942110" `
        -RuleGroupName "REQUEST-942-APPLICATION-ATTACK-SQLI" `
        -RuleSetType "OWASP" `
        -RuleSetVersion "3.2" `
        -MatchVariable "RequestArgValues" `
        -SelectorMatchOperator "Equals" `
        -Selector "comment"

.EXAMPLE
    # Disable a specific rule
    .\New-WafExclusion.ps1 `
        -Action "disableRule" `
        -ResourceGroupName "rg-waf" `
        -WafPolicyName "waf-policy-prod" `
        -RuleId "920350" `
        -RuleGroupName "REQUEST-920-PROTOCOL-ENFORCEMENT" `
        -RuleSetType "OWASP" `
        -RuleSetVersion "3.2"

.NOTES
    Version: 2.0
    Author: WAF Triage Solution
    Last Modified: 2025-06-30
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$WafPolicyName,

    [Parameter(Mandatory = $false)]
    [string]$RuleId,

    [Parameter(Mandatory = $false)]
    [string]$RuleGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateSet('OWASP', 'OWASP_CRS', 'Microsoft_DefaultRuleSet', 'Microsoft_BotManagerRuleSet')]
    [string]$RuleSetType = 'OWASP',

    [Parameter(Mandatory = $true)]
    [string]$RuleSetVersion,

    [Parameter(Mandatory = $false)]
    [ValidateSet(
        'RequestHeaderValues', 'RequestHeaderNames', 'RequestHeaderKeys',
        'RequestCookieValues', 'RequestCookieNames', 'RequestCookieKeys',
        'RequestArgValues', 'RequestArgNames', 'RequestArgKeys',
        'DisableRule', ''
    )]
    [string]$MatchVariable,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Equals', 'StartsWith', 'EndsWith', 'Contains', 'EqualsAny')]
    [string]$SelectorMatchOperator,

    [Parameter(Mandatory = $false)]
    [string]$Selector,

    [Parameter(Mandatory = $false)]
    [string]$Description = "Created by WAF Triage Automation",

    [Parameter(Mandatory = $false)]
    [ValidateSet('createExclusion', 'disableRule')]
    [string]$Action = "createExclusion"
)

#region Helper Functions

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$timestamp] [$Level] $Message"
}

function Get-RuleGroupFromRuleId {
    <#
    .SYNOPSIS
        Maps a rule ID to its corresponding rule group name.
        Supports both OWASP CRS (full prefix) and DRS (short name) formats.
    #>
    param(
        [string]$RuleId,
        [string]$RuleSetType = 'OWASP'
    )

    # OWASP CRS uses full prefix format: REQUEST-920-PROTOCOL-ENFORCEMENT
    $owaspGroupMap = @{
        '920' = 'REQUEST-920-PROTOCOL-ENFORCEMENT'
        '921' = 'REQUEST-921-PROTOCOL-ATTACK'
        '930' = 'REQUEST-930-APPLICATION-ATTACK-LFI'
        '931' = 'REQUEST-931-APPLICATION-ATTACK-RFI'
        '932' = 'REQUEST-932-APPLICATION-ATTACK-RCE'
        '933' = 'REQUEST-933-APPLICATION-ATTACK-PHP'
        '934' = 'REQUEST-934-APPLICATION-ATTACK-GENERIC'
        '941' = 'REQUEST-941-APPLICATION-ATTACK-XSS'
        '942' = 'REQUEST-942-APPLICATION-ATTACK-SQLI'
        '943' = 'REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION'
        '944' = 'REQUEST-944-APPLICATION-ATTACK-JAVA'
        '949' = 'REQUEST-949-BLOCKING-EVALUATION'
        '959' = 'REQUEST-959-BLOCKING-EVALUATION'
    }

    # Microsoft_DefaultRuleSet (DRS) uses short group names
    $drsGroupMap = @{
        '920' = 'PROTOCOL-ENFORCEMENT'
        '921' = 'PROTOCOL-ATTACK'
        '930' = 'LFI'
        '931' = 'RFI'
        '932' = 'RCE'
        '933' = 'PHP'
        '934' = 'General'
        '941' = 'XSS'
        '942' = 'SQLI'
        '943' = 'FIX'
        '944' = 'JAVA'
        '949' = 'General'
        '959' = 'General'
        '913' = 'General'
        '200' = 'MS-ThreatIntel-WebShells'
        '210' = 'MS-ThreatIntel-AppSec'
        '220' = 'MS-ThreatIntel-SQLI'
        '230' = 'MS-ThreatIntel-CVEs'
        '990' = 'METHOD-ENFORCEMENT'
        '911' = 'METHOD-ENFORCEMENT'
        '612' = 'NODEJS'
    }

    $prefix = $RuleId.Substring(0, 3)

    # Select the appropriate map based on RuleSetType
    if ($RuleSetType -eq 'Microsoft_DefaultRuleSet') {
        if ($drsGroupMap.ContainsKey($prefix)) {
            return $drsGroupMap[$prefix]
        }
    }

    # OWASP CRS map (also used as fallback for DRS)
    if ($owaspGroupMap.ContainsKey($prefix)) {
        return $owaspGroupMap[$prefix]
    }

    # Default fallback - return provided group name or throw error
    return $null
}

function Test-ExclusionExists {
    <#
    .SYNOPSIS
        Checks if an identical exclusion already exists in the WAF policy.
    #>
    param(
        [object]$WafPolicy,
        [string]$MatchVariable,
        [string]$SelectorMatchOperator,
        [string]$Selector,
        [string]$RuleId
    )

    foreach ($exclusion in $WafPolicy.ManagedRules.Exclusions) {
        if ($exclusion.MatchVariable -eq $MatchVariable -and
            $exclusion.SelectorMatchOperator -eq $SelectorMatchOperator -and
            $exclusion.Selector -eq $Selector) {

            # Check if it's for the same rule
            if ($RuleId) {
                foreach ($ruleSet in $exclusion.ExclusionManagedRuleSets) {
                    foreach ($ruleGroup in $ruleSet.RuleGroups) {
                        foreach ($rule in $ruleGroup.Rules) {
                            if ($rule.RuleId -eq $RuleId) {
                                return $true
                            }
                        }
                    }
                }
            } else {
                # Global exclusion check - if no ExclusionManagedRuleSets, it's global
                if (-not $exclusion.ExclusionManagedRuleSets -or $exclusion.ExclusionManagedRuleSets.Count -eq 0) {
                    return $true
                }
            }
        }
    }

    return $false
}

#endregion

#region Main Execution

try {
    Write-Log "Starting WAF policy change — Action: $Action"
    Write-Log "Parameters:"
    Write-Log "  Action: $Action"
    Write-Log "  Resource Group: $ResourceGroupName"
    Write-Log "  WAF Policy: $WafPolicyName"
    Write-Log "  Rule ID: $(if ($RuleId) { $RuleId } else { 'Global (all rules)' })"
    Write-Log "  Rule Group: $(if ($RuleGroupName) { $RuleGroupName } else { 'Auto-detect' })"
    Write-Log "  Rule Set: $RuleSetType $RuleSetVersion"
    if ($Action -eq 'createExclusion') {
        Write-Log "  Match Variable: $MatchVariable"
        Write-Log "  Selector Operator: $SelectorMatchOperator"
        Write-Log "  Selector: $Selector"
    }

    # Validate required parameters based on action
    if ($Action -eq 'createExclusion') {
        if (-not $MatchVariable -or -not $SelectorMatchOperator -or -not $Selector) {
            throw "createExclusion requires MatchVariable, SelectorMatchOperator, and Selector parameters."
        }
    }
    elseif ($Action -eq 'disableRule') {
        if (-not $RuleId) {
            throw "disableRule requires RuleId parameter."
        }
    }

    # Connect to Azure using Managed Identity (for Automation Account)
    Write-Log "Connecting to Azure..."

    try {
        # Try Managed Identity first (for Azure Automation)
        $null = Connect-AzAccount -Identity -ErrorAction Stop
        Write-Log "Connected using Managed Identity"
    }
    catch {
        # Fallback - assume already authenticated (for local testing)
        Write-Log "Managed Identity not available, assuming already authenticated" -Level "WARN"
    }

    # Get the WAF policy
    Write-Log "Retrieving WAF policy..."
    $wafPolicy = Get-AzApplicationGatewayFirewallPolicy `
        -Name $WafPolicyName `
        -ResourceGroupName $ResourceGroupName `
        -ErrorAction Stop

    if (-not $wafPolicy) {
        throw "WAF Policy '$WafPolicyName' not found in resource group '$ResourceGroupName'"
    }

    Write-Log "WAF Policy found: $($wafPolicy.Id)"

    # Normalize RuleSetType - WAF logs report 'OWASP_CRS' or 'OWASP CRS' but the cmdlet expects 'OWASP'
    if ($RuleSetType -match 'OWASP') {
        $RuleSetType = 'OWASP'
        Write-Log "Normalized RuleSetType to: $RuleSetType"
    }

    # Normalize RuleGroupName based on rule set type
    if ($RuleSetType -eq 'Microsoft_DefaultRuleSet' -and $RuleId) {
        # DRS uses short group names (SQLI, XSS, LFI, etc.) - always auto-detect from RuleId
        $autoGroup = Get-RuleGroupFromRuleId -RuleId $RuleId -RuleSetType $RuleSetType
        if ($autoGroup) {
            if ($RuleGroupName -and $RuleGroupName -ne $autoGroup) {
                Write-Log "Overriding RuleGroupName '$RuleGroupName' with correct DRS name '$autoGroup'"
            }
            $RuleGroupName = $autoGroup
        }
    }
    elseif ($RuleGroupName -and $RuleGroupName -notmatch '^REQUEST-\d+' -and $RuleGroupName -notmatch '^RESPONSE-\d+') {
        # OWASP CRS: logs may report short form - try to find full group name
        $fullGroupName = $null
        foreach ($rs in $wafPolicy.ManagedRules.ManagedRuleSets) {
            foreach ($rg in $rs.RuleGroupOverrides) {
                if ($rg.RuleGroupName -like "*$RuleGroupName*") {
                    $fullGroupName = $rg.RuleGroupName
                    break
                }
            }
            if ($fullGroupName) { break }
        }
        if ($fullGroupName) {
            Write-Log "Normalized RuleGroupName from '$RuleGroupName' to '$fullGroupName'"
            $RuleGroupName = $fullGroupName
        } else {
            Write-Log "Could not normalize RuleGroupName '$RuleGroupName' from overrides, trying auto-detect" -Level "WARN"
            # Fall through to auto-detect below
            $RuleGroupName = $null
        }
    }

    # Auto-detect rule group if not provided but RuleId is specified
    if ($RuleId -and -not $RuleGroupName) {
        $RuleGroupName = Get-RuleGroupFromRuleId -RuleId $RuleId -RuleSetType $RuleSetType
        if (-not $RuleGroupName) {
            throw "Could not auto-detect rule group for Rule ID '$RuleId'. Please provide RuleGroupName parameter."
        }
        Write-Log "Auto-detected Rule Group: $RuleGroupName"
    }

    #region Disable Rule Action
    if ($Action -eq 'disableRule') {
        Write-Log "Action: Disable Rule $RuleId in group $RuleGroupName"

        # Find the target managed rule set
        $targetRuleSet = $wafPolicy.ManagedRules.ManagedRuleSets | Where-Object {
            $_.RuleSetType -eq $RuleSetType -and $_.RuleSetVersion -eq $RuleSetVersion
        }
        if (-not $targetRuleSet) {
            throw "Rule set '$RuleSetType' version '$RuleSetVersion' not found in WAF policy '$WafPolicyName'"
        }

        # Check if rule is already disabled
        $alreadyDisabled = $false
        foreach ($rgo in $targetRuleSet.RuleGroupOverrides) {
            if ($rgo.RuleGroupName -eq $RuleGroupName) {
                foreach ($ro in $rgo.Rules) {
                    if ($ro.RuleId -eq $RuleId -and $ro.State -eq 'Disabled') {
                        $alreadyDisabled = $true
                        break
                    }
                }
            }
        }

        if ($alreadyDisabled) {
            Write-Log "Rule $RuleId is already disabled in group $RuleGroupName. Skipping." -Level "WARN"
            Write-Output (@{
                Status    = "Skipped"
                Message   = "Rule $RuleId is already disabled"
                PolicyName = $WafPolicyName
                RuleId    = $RuleId
            } | ConvertTo-Json)
            return
        }

        # Create rule override with Disabled state
        $ruleOverride = New-AzApplicationGatewayFirewallPolicyManagedRuleOverride `
            -RuleId $RuleId `
            -State Disabled

        # Find existing group override or create new one
        $existingGroupOverride = $targetRuleSet.RuleGroupOverrides | Where-Object { $_.RuleGroupName -eq $RuleGroupName }

        if ($existingGroupOverride) {
            # Add to existing rules list (avoid duplicates)
            $rules = [System.Collections.Generic.List[Microsoft.Azure.Commands.Network.Models.PSApplicationGatewayFirewallPolicyManagedRuleOverride]]::new()
            foreach ($r in $existingGroupOverride.Rules) {
                if ($r.RuleId -ne $RuleId) {
                    $rules.Add($r)
                }
            }
            $rules.Add($ruleOverride)
            $existingGroupOverride.Rules = $rules
            Write-Log "Added rule override to existing group override '$RuleGroupName' ($($rules.Count) rules total)"
        }
        else {
            # Create new group override
            $groupOverride = New-AzApplicationGatewayFirewallPolicyManagedRuleGroupOverride `
                -RuleGroupName $RuleGroupName `
                -Rule $ruleOverride

            $overrides = [System.Collections.Generic.List[Microsoft.Azure.Commands.Network.Models.PSApplicationGatewayFirewallPolicyManagedRuleGroupOverride]]::new()
            if ($targetRuleSet.RuleGroupOverrides) {
                foreach ($rgo in $targetRuleSet.RuleGroupOverrides) {
                    $overrides.Add($rgo)
                }
            }
            $overrides.Add($groupOverride)
            $targetRuleSet.RuleGroupOverrides = $overrides
            Write-Log "Created new group override '$RuleGroupName' with disabled rule $RuleId"
        }

        # Save the policy
        Write-Log "Updating WAF policy to disable rule $RuleId..."
        $updatedPolicy = Set-AzApplicationGatewayFirewallPolicy `
            -InputObject $wafPolicy `
            -ErrorAction Stop

        Write-Log "Rule $RuleId disabled successfully!" -Level "SUCCESS"

        $result = @{
            Status     = "Success"
            Message    = "Rule $RuleId disabled successfully"
            Action     = "disableRule"
            PolicyName = $WafPolicyName
            PolicyId   = $updatedPolicy.Id
            RuleDetails = @{
                RuleId        = $RuleId
                RuleGroupName = $RuleGroupName
                RuleSetType   = $RuleSetType
                RuleSetVersion = $RuleSetVersion
                State         = "Disabled"
            }
            Timestamp  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
        }

        Write-Output ($result | ConvertTo-Json -Depth 5)
        return
    }
    #endregion

    # Check if exclusion already exists
    Write-Log "Checking for existing exclusions..."
    if (Test-ExclusionExists -WafPolicy $wafPolicy -MatchVariable $MatchVariable `
        -SelectorMatchOperator $SelectorMatchOperator -Selector $Selector -RuleId $RuleId) {
        Write-Log "An identical exclusion already exists. Skipping creation." -Level "WARN"
        Write-Output @{
            Status = "Skipped"
            Message = "Exclusion already exists"
            PolicyName = $WafPolicyName
            RuleId = $RuleId
        } | ConvertTo-Json
        return
    }

    # Create the exclusion entry
    Write-Log "Creating exclusion entry..."

    if ($RuleId) {
        # Per-rule exclusion
        Write-Log "Creating per-rule exclusion for Rule ID: $RuleId"

        # Create rule entry
        $ruleEntry = New-AzApplicationGatewayFirewallPolicyExclusionManagedRule `
            -RuleId $RuleId

        # Create rule group entry
        $ruleGroupEntry = New-AzApplicationGatewayFirewallPolicyExclusionManagedRuleGroup `
            -RuleGroupName $RuleGroupName `
            -Rule $ruleEntry

        # Create managed rule set entry
        $exclusionManagedRuleSet = New-AzApplicationGatewayFirewallPolicyExclusionManagedRuleSet `
            -RuleSetType $RuleSetType `
            -RuleSetVersion $RuleSetVersion `
            -RuleGroup $ruleGroupEntry

        # Create exclusion entry with managed rule set
        $exclusionEntry = New-AzApplicationGatewayFirewallPolicyExclusion `
            -MatchVariable $MatchVariable `
            -SelectorMatchOperator $SelectorMatchOperator `
            -Selector $Selector `
            -ExclusionManagedRuleSet $exclusionManagedRuleSet
    }
    elseif ($RuleGroupName) {
        # Per-rule-group exclusion
        Write-Log "Creating per-rule-group exclusion for group: $RuleGroupName"

        # Create rule group entry without specific rules
        $ruleGroupEntry = New-AzApplicationGatewayFirewallPolicyExclusionManagedRuleGroup `
            -RuleGroupName $RuleGroupName

        # Create managed rule set entry
        $exclusionManagedRuleSet = New-AzApplicationGatewayFirewallPolicyExclusionManagedRuleSet `
            -RuleSetType $RuleSetType `
            -RuleSetVersion $RuleSetVersion `
            -RuleGroup $ruleGroupEntry

        # Create exclusion entry with managed rule set
        $exclusionEntry = New-AzApplicationGatewayFirewallPolicyExclusion `
            -MatchVariable $MatchVariable `
            -SelectorMatchOperator $SelectorMatchOperator `
            -Selector $Selector `
            -ExclusionManagedRuleSet $exclusionManagedRuleSet
    }
    else {
        # Global exclusion
        Write-Log "Creating global exclusion (applies to all rules)"

        $exclusionEntry = New-AzApplicationGatewayFirewallPolicyExclusion `
            -MatchVariable $MatchVariable `
            -SelectorMatchOperator $SelectorMatchOperator `
            -Selector $Selector
    }

    # Add exclusion to policy
    Write-Log "Adding exclusion to WAF policy..."

    # Build a properly-typed exclusions list (fixes System.Object[] cast error)
    $typedExclusions = [System.Collections.Generic.List[Microsoft.Azure.Commands.Network.Models.PSApplicationGatewayFirewallPolicyExclusion]]::new()

    # Copy any existing exclusions
    if ($wafPolicy.ManagedRules.Exclusions -and $wafPolicy.ManagedRules.Exclusions.Count -gt 0) {
        foreach ($existing in $wafPolicy.ManagedRules.Exclusions) {
            $typedExclusions.Add($existing)
        }
    }

    # Add the new exclusion
    $typedExclusions.Add($exclusionEntry)
    $wafPolicy.ManagedRules.Exclusions = $typedExclusions

    # Update the WAF policy
    Write-Log "Updating WAF policy..."
    $updatedPolicy = Set-AzApplicationGatewayFirewallPolicy `
        -InputObject $wafPolicy `
        -ErrorAction Stop

    Write-Log "WAF Exclusion created successfully!" -Level "SUCCESS"

    # Output result
    $result = @{
        Status = "Success"
        Message = "Exclusion created successfully"
        PolicyName = $WafPolicyName
        PolicyId = $updatedPolicy.Id
        ExclusionDetails = @{
            MatchVariable = $MatchVariable
            SelectorMatchOperator = $SelectorMatchOperator
            Selector = $Selector
            RuleId = $RuleId
            RuleGroupName = $RuleGroupName
            RuleSetType = $RuleSetType
            RuleSetVersion = $RuleSetVersion
        }
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
    }

    Write-Output ($result | ConvertTo-Json -Depth 5)

}
catch {
    Write-Log "ERROR: $($_.Exception.Message)" -Level "ERROR"
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level "ERROR"

    $errorResult = @{
        Status = "Failed"
        Message = $_.Exception.Message
        PolicyName = $WafPolicyName
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
    }

    Write-Output ($errorResult | ConvertTo-Json)
    throw
}

#endregion
