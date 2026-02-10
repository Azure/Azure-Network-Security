#Requires -Modules Az.Accounts, Az.Network

<#
.SYNOPSIS
    Comprehensive Azure DDoS Protection assessment for all Public IP addresses.

.DESCRIPTION
    This script provides a complete view of DDoS Protection status across your Azure environment:
    - Whether DDoS Protection is enabled for each Public IP
    - Which DDoS SKU is being used (IP Protection vs Network Protection)
    - The DDoS Protection Plan details
    - Diagnostic logging status for DDoS-protected IPs
    - Risk assessment for unprotected resources
    - Multi-subscription support with resilience for large environments

.PARAMETER SubscriptionId
    Optional. Specific subscription ID to scan. If not provided, uses current subscription.

.PARAMETER AllSubscriptions
    Optional. Scan all subscriptions the user has access to.

.PARAMETER ExportPath
    Optional. Path to export CSV report.

.PARAMETER ContinueOnError
    Optional. Continue scanning even if a subscription fails (useful for large environments).

.PARAMETER SavePerSubscription
    Optional. Save a separate CSV file for each subscription (requires -ExportPath).

.PARAMETER ThrottleDelayMs
    Optional. Delay in milliseconds between API calls to avoid throttling. Default: 100ms.

.EXAMPLE
    .\Check-DDoSProtection.ps1

.EXAMPLE
    .\Check-DDoSProtection.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012"

.EXAMPLE
    .\Check-DDoSProtection.ps1 -AllSubscriptions

.EXAMPLE
    .\Check-DDoSProtection.ps1 -AllSubscriptions -ExportPath "C:\Reports\DDoS-Report.csv"

.EXAMPLE
    .\Check-DDoSProtection.ps1 -AllSubscriptions -ContinueOnError -SavePerSubscription -ExportPath "C:\Reports\DDoS.csv"

.EXAMPLE
    .\Check-DDoSProtection.ps1 -AllSubscriptions -ThrottleDelayMs 200

.NOTES
    Author: Security Team
    Version: 14.0
    Requires: Az PowerShell module
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [switch]$AllSubscriptions,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath,

    [Parameter(Mandatory = $false)]
    [switch]$ContinueOnError,

    [Parameter(Mandatory = $false)]
    [switch]$SavePerSubscription,

    [Parameter(Mandatory = $false)]
    [int]$ThrottleDelayMs = 100
)

# Suppress Azure PowerShell breaking change warnings
$null = Update-AzConfig -DisplayBreakingChangeWarning $false -ErrorAction SilentlyContinue

# Function to refresh Azure token if needed
function Test-AzTokenExpiry {
    try {
        $context = Get-AzContext
        if (-not $context) { return $false }

        # Try a simple API call to verify token is valid
        $null = Get-AzSubscription -SubscriptionId $context.Subscription.Id -ErrorAction Stop
        return $true
    } catch {
        if ($_.Exception.Message -match "token" -or $_.Exception.Message -match "expired" -or $_.Exception.Message -match "authentication") {
            Write-Host "Azure token expired. Refreshing..." -ForegroundColor Yellow
            try {
                Connect-AzAccount -ErrorAction Stop | Out-Null
                return $true
            } catch {
                Write-Warning "Failed to refresh token: $($_.Exception.Message)"
                return $false
            }
        }
        return $true  # Other errors, assume token is fine
    }
}

# Function to execute with retry logic for throttling
function Invoke-WithRetry {
    param(
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = 3,
        [int]$InitialDelayMs = 1000
    )

    $retryCount = 0
    $delay = $InitialDelayMs

    while ($retryCount -lt $MaxRetries) {
        try {
            return & $ScriptBlock
        } catch {
            if ($_.Exception.Message -match "throttl" -or $_.Exception.Message -match "429" -or $_.Exception.Message -match "too many requests") {
                $retryCount++
                if ($retryCount -lt $MaxRetries) {
                    Write-Host "  API throttled. Waiting $($delay/1000) seconds before retry ($retryCount/$MaxRetries)..." -ForegroundColor Yellow
                    Start-Sleep -Milliseconds $delay
                    $delay = $delay * 2  # Exponential backoff
                } else {
                    throw $_
                }
            } else {
                throw $_
            }
        }
    }
}

# Ensure we're logged in
$context = Get-AzContext
if (-not $context) {
    Write-Host "Please login to Azure first..." -ForegroundColor Yellow
    Connect-AzAccount
    $context = Get-AzContext
}

# Determine which subscriptions to scan
$subscriptionsToScan = @()

if ($AllSubscriptions) {
    Write-Host "Retrieving all accessible subscriptions..." -ForegroundColor Yellow
    $subscriptionsToScan = Get-AzSubscription | Where-Object { $_.State -eq 'Enabled' }
    Write-Host "Found $($subscriptionsToScan.Count) subscription(s) to scan.`n" -ForegroundColor Green
} elseif ($SubscriptionId) {
    $subscriptionsToScan = Get-AzSubscription -SubscriptionId $SubscriptionId
} else {
    $subscriptionsToScan = Get-AzSubscription -SubscriptionId $context.Subscription.Id
}

# Global results collection
$allResults = @()

# Function to get VNET from an IP Configuration ID
function Get-VNetFromIpConfig {
    param(
        [string]$IpConfigId,
        [hashtable]$VnetCache
    )

    $vnetId = $null
    $vnetName = $null
    $status = "Unknown"

    try {
        if ($IpConfigId -match "/providers/Microsoft\.Network/networkInterfaces/") {
            # It's a NIC - get the NIC and find its subnet
            $nicId = $IpConfigId -replace "/ipConfigurations/.*$", ""
            $nic = Get-AzNetworkInterface -ResourceId $nicId -ErrorAction SilentlyContinue
            if ($nic -and $nic.IpConfigurations[0].Subnet) {
                $subnetId = $nic.IpConfigurations[0].Subnet.Id
                $vnetId = $subnetId -replace "/subnets/.*$", ""
            }
        } elseif ($IpConfigId -match "/providers/Microsoft\.Network/applicationGateways/([^/]+)") {
            # It's an Application Gateway
            $appGwName = $Matches[1]
            $rgName = ($IpConfigId -split "/resourceGroups/")[1] -split "/" | Select-Object -First 1
            $appGw = Get-AzApplicationGateway -Name $appGwName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if ($appGw -and $appGw.GatewayIPConfigurations[0].Subnet) {
                $subnetId = $appGw.GatewayIPConfigurations[0].Subnet.Id
                $vnetId = $subnetId -replace "/subnets/.*$", ""
            }
        } elseif ($IpConfigId -match "/providers/Microsoft\.Network/loadBalancers/([^/]+)") {
            # Load Balancer - check frontend config for internal LB, then backend pools
            $lbName = $Matches[1]
            $rgName = ($IpConfigId -split "/resourceGroups/")[1] -split "/" | Select-Object -First 1
            $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgName -ErrorAction SilentlyContinue

            if ($lb) {
                # First check if it's an internal LB with subnet on frontend
                foreach ($frontendConfig in $lb.FrontendIpConfigurations) {
                    if ($frontendConfig.Subnet) {
                        $subnetId = $frontendConfig.Subnet.Id
                        $vnetId = $subnetId -replace "/subnets/.*$", ""
                        break
                    }
                }

                # If not internal LB, try backend pools
                if (-not $vnetId -and $lb.BackendAddressPools) {
                    foreach ($backendPool in $lb.BackendAddressPools) {
                        # Try BackendIpConfigurations (NIC-based backends)
                        if ($backendPool.BackendIpConfigurations -and $backendPool.BackendIpConfigurations.Count -gt 0) {
                            $backendNicId = $backendPool.BackendIpConfigurations[0].Id -replace "/ipConfigurations/.*$", ""
                            $backendNic = Get-AzNetworkInterface -ResourceId $backendNicId -ErrorAction SilentlyContinue
                            if ($backendNic -and $backendNic.IpConfigurations[0].Subnet) {
                                $subnetId = $backendNic.IpConfigurations[0].Subnet.Id
                                $vnetId = $subnetId -replace "/subnets/.*$", ""
                                break
                            }
                        }
                        # Try LoadBalancerBackendAddresses (IP-based backends, used by AKS)
                        elseif ($backendPool.LoadBalancerBackendAddresses -and $backendPool.LoadBalancerBackendAddresses.Count -gt 0) {
                            foreach ($addr in $backendPool.LoadBalancerBackendAddresses) {
                                if ($addr.Subnet -and $addr.Subnet.Id) {
                                    $vnetId = $addr.Subnet.Id -replace "/subnets/.*$", ""
                                    break
                                }
                                # Check VirtualNetwork property
                                if ($addr.VirtualNetwork -and $addr.VirtualNetwork.Id) {
                                    $vnetId = $addr.VirtualNetwork.Id
                                    break
                                }
                            }
                            if ($vnetId) { break }
                        }
                    }
                }

                # If still no VNET found, it's an external LB with no backend association
                if (-not $vnetId) {
                    return @{
                        VNetId = $null
                        VNetName = "(External LB)"
                        Status = "ExternalLB"
                    }
                }
            }
        } elseif ($IpConfigId -match "/providers/Microsoft\.Network/azureFirewalls/([^/]+)") {
            # Azure Firewall
            $fwName = $Matches[1]
            $rgName = ($IpConfigId -split "/resourceGroups/")[1] -split "/" | Select-Object -First 1
            $fw = Get-AzFirewall -Name $fwName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if ($fw -and $fw.IpConfigurations[0].Subnet) {
                $subnetId = $fw.IpConfigurations[0].Subnet.Id
                $vnetId = $subnetId -replace "/subnets/.*$", ""
            }
        } elseif ($IpConfigId -match "/providers/Microsoft\.Network/virtualNetworkGateways/([^/]+)") {
            # VPN/ExpressRoute Gateway
            $gwName = $Matches[1]
            $rgName = ($IpConfigId -split "/resourceGroups/")[1] -split "/" | Select-Object -First 1
            $gw = Get-AzVirtualNetworkGateway -Name $gwName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if ($gw -and $gw.IpConfigurations[0].Subnet) {
                $subnetId = $gw.IpConfigurations[0].Subnet.Id
                $vnetId = $subnetId -replace "/subnets/.*$", ""
            }
        } elseif ($IpConfigId -match "/providers/Microsoft\.Network/bastionHosts/([^/]+)") {
            # Bastion Host
            $bastionName = $Matches[1]
            $rgName = ($IpConfigId -split "/resourceGroups/")[1] -split "/" | Select-Object -First 1
            $bastion = Get-AzBastion -ResourceGroupName $rgName -Name $bastionName -ErrorAction SilentlyContinue
            if ($bastion -and $bastion.IpConfigurations[0].Subnet) {
                $subnetId = $bastion.IpConfigurations[0].Subnet.Id
                $vnetId = $subnetId -replace "/subnets/.*$", ""
            }
        } elseif ($IpConfigId -match "/providers/Microsoft\.Network/natGateways/([^/]+)") {
            # NAT Gateway - get associated subnets
            $natGwName = $Matches[1]
            $rgName = ($IpConfigId -split "/resourceGroups/")[1] -split "/" | Select-Object -First 1
            $natGw = Get-AzNatGateway -Name $natGwName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if ($natGw -and $natGw.Subnets -and $natGw.Subnets.Count -gt 0) {
                $subnetId = $natGw.Subnets[0].Id
                $vnetId = $subnetId -replace "/subnets/.*$", ""
            }
        }

        # If we found a VNET ID, get the VNET name
        if ($vnetId) {
            if ($VnetCache.ContainsKey($vnetId)) {
                $vnet = $VnetCache[$vnetId]
            } else {
                $vnetRg = ($vnetId -split "/resourceGroups/")[1] -split "/" | Select-Object -First 1
                $vnetNameFromId = ($vnetId -split "/virtualNetworks/")[1]
                $vnet = Get-AzVirtualNetwork -Name $vnetNameFromId -ResourceGroupName $vnetRg -ErrorAction SilentlyContinue
                $VnetCache[$vnetId] = $vnet
            }

            if ($vnet) {
                return @{
                    VNetId = $vnetId
                    VNetName = $vnet.Name
                    VNet = $vnet
                    Status = "Found"
                }
            } else {
                return @{
                    VNetId = $vnetId
                    VNetName = "(Access Denied)"
                    Status = "AccessDenied"
                }
            }
        }
    } catch {
        return @{
            VNetId = $null
            VNetName = "(Error)"
            Status = "Error"
            ErrorMessage = $_.Exception.Message
        }
    }

    return @{
        VNetId = $null
        VNetName = "(Not Found)"
        Status = "NotFound"
    }
}

# Function to check diagnostic settings for a resource
function Get-DDoSDiagnosticStatus {
    param([string]$ResourceId)

    # DDoS category names - Azure uses different formats in different API versions
    # API names: DDoSProtectionNotifications, DDoSMitigationFlowLogs, DDoSMitigationReports
    # Display names may include spaces or variations
    $ddosCategoryPatterns = @(
        "DDoSProtectionNotifications",
        "DDoSMitigationFlowLogs",
        "DDoSMitigationReports",
        "DDoS protection notifications",
        "Flow logs of DDoS mitigation decisions",
        "Reports of DDoS mitigations"
    )

    try {
        $diagSettings = Get-AzDiagnosticSetting -ResourceId $ResourceId -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        if (-not $diagSettings -or $diagSettings.Count -eq 0) {
            return @{
                Configured = $false
                HasAnyDiagSettings = $false
                Categories = @()
                Destination = "None"
            }
        }

        $enabledCategories = @()
        $ddosLogsFound = 0
        $destinations = @()
        $hasAllLogs = $false

        foreach ($setting in $diagSettings) {
            # Check for destinations first
            if ($setting.WorkspaceId) { $destinations += "Log Analytics" }
            if ($setting.StorageAccountId) { $destinations += "Storage" }
            if ($setting.EventHubAuthorizationRuleId) { $destinations += "Event Hub" }

            # Check newer API format (Logs property)
            $logs = if ($setting.PSObject.Properties['Logs']) { $setting.Logs }
                    elseif ($setting.PSObject.Properties['Log']) { $setting.Log }
                    else { @() }

            foreach ($log in $logs) {
                # Check for category groups (e.g., "allLogs") - must check value is not null/empty
                if (-not [string]::IsNullOrEmpty($log.CategoryGroup)) {
                    if ($log.Enabled -and $log.CategoryGroup -eq 'allLogs') {
                        $hasAllLogs = $true
                        $enabledCategories += "allLogs"
                    }
                }
                # Check for individual categories
                if (-not [string]::IsNullOrEmpty($log.Category)) {
                    if ($log.Enabled) {
                        $enabledCategories += $log.Category
                        # Check if this is a DDoS category (case-insensitive, flexible matching)
                        $categoryLower = $log.Category.ToLower()
                        if ($categoryLower -match 'ddos' -or $categoryLower -match 'd_dos') {
                            $ddosLogsFound++
                        }
                    }
                }
            }
        }

        # DDoS logging is configured if we have allLogs enabled OR at least one DDoS-related category
        $isDdosLoggingConfigured = $hasAllLogs -or ($ddosLogsFound -gt 0)

        return @{
            Configured = $isDdosLoggingConfigured
            HasAnyDiagSettings = $true
            DDoSCategoriesFound = $ddosLogsFound
            Categories = $enabledCategories | Select-Object -Unique
            Destination = if ($destinations.Count -gt 0) { ($destinations | Select-Object -Unique) -join ", " } else { "None" }
        }
    } catch {
        return @{
            Configured = $false
            HasAnyDiagSettings = $false
            Categories = @()
            Destination = "Error: $($_.Exception.Message)"
        }
    }
}

# Track timing for large environment estimates
$scriptStartTime = Get-Date
$subscriptionCount = $subscriptionsToScan.Count
$subscriptionIndex = 0
$failedSubscriptions = @()

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  DDoS Protection Assessment" -ForegroundColor Cyan
Write-Host "  Subscriptions to scan: $subscriptionCount" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

foreach ($subscription in $subscriptionsToScan) {
    $subscriptionIndex++
    $subscriptionStartTime = Get-Date

    Write-Host "[$subscriptionIndex/$subscriptionCount]" -ForegroundColor Gray

    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "Scanning Subscription: $($subscription.Name) ($($subscription.Id))" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan

    # Check token validity every 10 subscriptions
    if ($subscriptionIndex % 10 -eq 0) {
        $null = Test-AzTokenExpiry
    }

    try {
        Set-AzContext -SubscriptionId $subscription.Id -ErrorAction Stop | Out-Null
    } catch {
        Write-Warning "Failed to set context for subscription $($subscription.Name): $($_.Exception.Message)"
        $failedSubscriptions += @{
            Name = $subscription.Name
            Id = $subscription.Id
            Error = $_.Exception.Message
        }
        if ($ContinueOnError) {
            Write-Host "  Skipping subscription due to -ContinueOnError flag..." -ForegroundColor Yellow
            continue
        } else {
            throw $_
        }
    }

    Write-Host "Retrieving Public IP addresses..." -ForegroundColor Yellow

    # Get all public IPs
    $publicIPs = Get-AzPublicIpAddress

    if ($publicIPs.Count -eq 0) {
        Write-Host "No Public IP addresses found in this subscription.`n" -ForegroundColor Yellow
        continue
    }

    Write-Host "Found $($publicIPs.Count) Public IP address(es). Analyzing..." -ForegroundColor Green

    # Cache for VNETs to avoid repeated API calls
    $vnetCache = @{}
    $ddosPlanCache = @{}

# Results collection
    $results = @()

    $counter = 0
    foreach ($pip in $publicIPs) {
        $counter++
        Write-Progress -Activity "Analyzing Public IPs" -Status "$counter of $($publicIPs.Count): $($pip.Name)" -PercentComplete (($counter / $publicIPs.Count) * 100)

        $result = [PSCustomObject]@{
            'Subscription'         = $subscription.Name
            'Public IP Name'       = $pip.Name
            'Resource Group'       = $pip.ResourceGroupName
            'Location'             = $pip.Location
            'IP Address'           = if ($pip.IpAddress) { $pip.IpAddress } else { "(Dynamic)" }
            'IP SKU'               = $pip.Sku.Name
            'Allocation'           = $pip.PublicIpAllocationMethod
            'DDoS Protected'       = "No"
            'Risk Level'           = "High"
            'DDoS SKU'             = "None"
            'DDoS Plan Name'       = "N/A"
            'VNET Name'            = "-"
            'Associated Resource'  = "Not attached"
            'Resource Type'        = "Unattached"
            'Diagnostic Logging'   = "N/A"
            'Log Destination'      = "N/A"
            'Recommendation'       = ""
        }

    $protectionMode = $pip.DdosSettings.ProtectionMode

    # Azure default: If ProtectionMode is empty/null, it defaults to VirtualNetworkInherited
    if ([string]::IsNullOrEmpty($protectionMode)) {
        $protectionMode = "VirtualNetworkInherited"
    }

        # Determine associated resource
        if ($pip.IpConfiguration) {
            $ipConfigId = $pip.IpConfiguration.Id
            # Extract resource type and name from ipConfiguration ID
            if ($ipConfigId -match "/providers/Microsoft\.Network/networkInterfaces/([^/]+)/") {
                $result.'Associated Resource' = $Matches[1]
                $result.'Resource Type' = "Network Interface"
            } elseif ($ipConfigId -match "/providers/Microsoft\.Network/loadBalancers/([^/]+)/") {
                $result.'Associated Resource' = $Matches[1]
                $result.'Resource Type' = "Load Balancer"
            } elseif ($ipConfigId -match "/providers/Microsoft\.Network/applicationGateways/([^/]+)/") {
                $result.'Associated Resource' = $Matches[1]
                $result.'Resource Type' = "Application Gateway"
            } elseif ($ipConfigId -match "/providers/Microsoft\.Network/azureFirewalls/([^/]+)/") {
                $result.'Associated Resource' = $Matches[1]
                $result.'Resource Type' = "Azure Firewall"
            } elseif ($ipConfigId -match "/providers/Microsoft\.Network/bastionHosts/([^/]+)/") {
                $result.'Associated Resource' = $Matches[1]
                $result.'Resource Type' = "Bastion Host"
            } elseif ($ipConfigId -match "/providers/Microsoft\.Network/virtualNetworkGateways/([^/]+)/") {
                $result.'Associated Resource' = $Matches[1]
                $result.'Resource Type' = "VNet Gateway"
            } elseif ($ipConfigId -match "/providers/Microsoft\.Network/natGateways/([^/]+)/") {
                $result.'Associated Resource' = $Matches[1]
                $result.'Resource Type' = "NAT Gateway"
            } else {
                $result.'Associated Resource' = "Other"
                $result.'Resource Type' = "Other"
            }
        }

        # Check for Basic SKU limitation
        if ($pip.Sku.Name -eq "Basic") {
            $result.'Recommendation' = "Upgrade to Standard SKU for DDoS IP Protection support"
        }

    switch ($protectionMode) {
            "Enabled" {
                # DDoS Protection enabled on the public IP
                $result.'DDoS Protected' = "Yes"
                $result.'Risk Level' = "Low"

                # Check if attached to a DDoS Plan (Network Protection) or standalone (IP Protection)
                if ($pip.DdosSettings.DdosProtectionPlan -and $pip.DdosSettings.DdosProtectionPlan.Id) {
                    # Attached to a DDoS Plan = Network Protection SKU
                    $result.'DDoS SKU' = "Network Protection"
                    $ddosPlanId = $pip.DdosSettings.DdosProtectionPlan.Id
                    $ddosPlanName = ($ddosPlanId -split "/ddosProtectionPlans/")[1]
                    $result.'DDoS Plan Name' = $ddosPlanName
                } else {
                    # No plan attached = IP Protection SKU
                    $result.'DDoS SKU' = "IP Protection"
                    $result.'DDoS Plan Name' = "N/A (IP Protection)"
                }

                # Look up VNET even for IP Protection (for informational purposes)
                if ($pip.IpConfiguration) {
                    $vnetInfo = Get-VNetFromIpConfig -IpConfigId $pip.IpConfiguration.Id -VnetCache $vnetCache
                    $result.'VNET Name' = $vnetInfo.VNetName
                } else {
                    $result.'VNET Name' = "(Unattached)"
                }

                # Check diagnostic logging
                $diagStatus = Get-DDoSDiagnosticStatus -ResourceId $pip.Id
                if ($diagStatus.Configured) {
                    $result.'Diagnostic Logging' = "Enabled"
                } elseif ($diagStatus.HasAnyDiagSettings) {
                    $result.'Diagnostic Logging' = "Partial (No DDoS logs)"
                } else {
                    $result.'Diagnostic Logging' = "Not Configured"
                }
                $result.'Log Destination' = $diagStatus.Destination

                if (-not $diagStatus.Configured) {
                    $result.'Risk Level' = "Medium"
                    $result.'Recommendation' = "Enable DDoS diagnostic categories (DDoSProtectionNotifications, DDoSMitigationFlowLogs, DDoSMitigationReports)"
                }
            }
            "Disabled" {
                # Explicitly disabled
                $result.'DDoS Protected' = "No"
                $result.'Risk Level' = "High"
                $result.'DDoS SKU' = "Disabled"
                $result.'Recommendation' = "Enable DDoS Protection (IP or Network)"
            }
            "VirtualNetworkInherited" {
                # Need to check the VNET
                if (-not $pip.IpConfiguration) {
                    # Not attached to any resource, can't inherit protection
                    $result.'DDoS Protected' = "No"
                    $result.'Risk Level' = "Low"
                    $result.'DDoS SKU' = "Not attached"
                    $result.'VNET Name' = "(Unattached)"
                    $result.'Recommendation' = "Public IP not in use - consider deleting if unused"
                } else {
                    # Use the helper function to find VNET
                    $vnetInfo = Get-VNetFromIpConfig -IpConfigId $pip.IpConfiguration.Id -VnetCache $vnetCache
                    $result.'VNET Name' = $vnetInfo.VNetName

                    if ($vnetInfo.Status -eq "Found" -and $vnetInfo.VNet) {
                        $vnet = $vnetInfo.VNet

                        if ($vnet.EnableDdosProtection -and $vnet.DdosProtectionPlan) {
                            $result.'DDoS Protected' = "Yes"
                            $result.'Risk Level' = "Low"
                            $result.'DDoS SKU' = "Network Protection"

                            # Get DDoS Plan name
                            $ddosPlanId = $vnet.DdosProtectionPlan.Id
                            if ($ddosPlanCache.ContainsKey($ddosPlanId)) {
                                $result.'DDoS Plan Name' = $ddosPlanCache[$ddosPlanId]
                            } else {
                                $ddosPlanName = ($ddosPlanId -split "/ddosProtectionPlans/")[1]
                                $ddosPlanCache[$ddosPlanId] = $ddosPlanName
                                $result.'DDoS Plan Name' = $ddosPlanName
                            }

                            # Check diagnostic logging
                            $diagStatus = Get-DDoSDiagnosticStatus -ResourceId $pip.Id
                            if ($diagStatus.Configured) {
                                $result.'Diagnostic Logging' = "Enabled"
                            } elseif ($diagStatus.HasAnyDiagSettings) {
                                $result.'Diagnostic Logging' = "Partial (No DDoS logs)"
                            } else {
                                $result.'Diagnostic Logging' = "Not Configured"
                            }
                            $result.'Log Destination' = $diagStatus.Destination

                            if (-not $diagStatus.Configured) {
                                $result.'Risk Level' = "Medium"
                                $result.'Recommendation' = "Enable DDoS diagnostic categories (DDoSProtectionNotifications, DDoSMitigationFlowLogs, DDoSMitigationReports)"
                            }
                        } else {
                            $result.'DDoS Protected' = "No"
                            $result.'Risk Level' = "High"
                            $result.'DDoS SKU' = "VNET not protected"
                            $result.'Recommendation' = "Enable DDoS Network Protection on VNET or IP Protection on this IP"
                        }
                    } elseif ($vnetInfo.Status -eq "ExternalLB") {
                        # External Load Balancer - no VNET association
                        $result.'DDoS Protected' = "No"
                        $result.'Risk Level' = "High"
                        $result.'DDoS SKU' = "No VNET association"
                        $result.'Recommendation' = "Enable DDoS IP Protection on this Public IP"
                    } elseif ($vnetInfo.Status -eq "AccessDenied") {
                        $result.'DDoS Protected' = "Unknown"
                        $result.'Risk Level' = "Unknown"
                        $result.'DDoS SKU' = "Could not retrieve VNET"
                        $result.'Recommendation' = "Verify VNET access permissions"
                    } else {
                        $result.'DDoS Protected' = "Unknown"
                        $result.'Risk Level' = "Unknown"
                        $result.'DDoS SKU' = "Could not find VNET"
                        $result.'Recommendation' = "Verify resource configuration"
                    }
                }
            }
        default {
            $result.'DDoS Protected' = "Unknown"
            $result.'Risk Level' = "Unknown"
            $result.'DDoS SKU' = "Unknown mode: $protectionMode"
            $result.'Recommendation' = "Investigate protection mode"
        }
    }

    $results += $result

    # Throttle delay to avoid API rate limits
    if ($ThrottleDelayMs -gt 0) {
        Start-Sleep -Milliseconds $ThrottleDelayMs
    }
}

    Write-Progress -Activity "Analyzing Public IPs" -Completed

    $allResults += $results

    # Save per subscription if requested (useful for large environments)
    if ($SavePerSubscription -and $ExportPath) {
        $subExportPath = $ExportPath -replace '\.csv$', "_$($subscription.Name -replace '[^\w]', '_').csv"
        $results | Export-Csv -Path $subExportPath -NoTypeInformation
        Write-Host "  Subscription results saved to: $subExportPath" -ForegroundColor Green
    }

    # Show subscription completion time
    $subDuration = (Get-Date) - $subscriptionStartTime
    Write-Host "  Subscription completed in $([math]::Round($subDuration.TotalSeconds, 1)) seconds" -ForegroundColor Gray

    # Display results for this subscription
    Write-Host "`nResults for $($subscription.Name):" -ForegroundColor Cyan
    $results | Format-Table -Property 'Public IP Name', 'IP Address', 'DDoS Protected', 'Risk Level', 'DDoS SKU', 'DDoS Plan Name', 'VNET Name', 'Diagnostic Logging' -AutoSize -Wrap
}

# Calculate total runtime
$totalRuntime = (Get-Date) - $scriptStartTime
$runtimeFormatted = $totalRuntime.ToString("hh\:mm\:ss")

# Final Summary across all subscriptions
Write-Host "`n" + "=" * 100 -ForegroundColor Cyan
Write-Host "OVERALL DDOS PROTECTION ASSESSMENT SUMMARY" -ForegroundColor Cyan
Write-Host "=" * 100 -ForegroundColor Cyan
Write-Host "Total Runtime: $runtimeFormatted" -ForegroundColor Gray
Write-Host "Subscriptions Scanned: $($subscriptionCount - $failedSubscriptions.Count) of $subscriptionCount" -ForegroundColor Gray

# Show failed subscriptions if any
if ($failedSubscriptions.Count -gt 0) {
    Write-Host "`nFAILED SUBSCRIPTIONS ($($failedSubscriptions.Count)):" -ForegroundColor Red
    Write-Host "------------------------------"
    foreach ($failed in $failedSubscriptions) {
        Write-Host "  - $($failed.Name): $($failed.Error)" -ForegroundColor Red
    }
}

$protected = ($allResults | Where-Object { $_.'DDoS Protected' -eq "Yes" }).Count
$notProtected = ($allResults | Where-Object { $_.'DDoS Protected' -eq "No" }).Count
$unknown = ($allResults | Where-Object { $_.'DDoS Protected' -notin @("Yes", "No") }).Count

$ipProtection = ($allResults | Where-Object { $_.'DDoS SKU' -eq "IP Protection" }).Count
$networkProtection = ($allResults | Where-Object { $_.'DDoS SKU' -eq "Network Protection" }).Count

$highRisk = ($allResults | Where-Object { $_.'Risk Level' -eq "High" }).Count
$mediumRisk = ($allResults | Where-Object { $_.'Risk Level' -eq "Medium" }).Count
$lowRisk = ($allResults | Where-Object { $_.'Risk Level' -eq "Low" }).Count

$diagConfigured = ($allResults | Where-Object { $_.'Diagnostic Logging' -eq "Enabled" }).Count
$diagPartial = ($allResults | Where-Object { $_.'Diagnostic Logging' -eq "Partial (No DDoS logs)" }).Count
$diagNotConfigured = ($allResults | Where-Object { $_.'DDoS Protected' -eq "Yes" -and $_.'Diagnostic Logging' -eq "Not Configured" }).Count

Write-Host "`nPROTECTION STATUS" -ForegroundColor White
Write-Host "-----------------"
Write-Host "Total Public IPs Scanned:    $($allResults.Count)"
Write-Host "Protected:                   $protected" -ForegroundColor Green
Write-Host "  - IP Protection:           $ipProtection"
Write-Host "  - Network Protection:      $networkProtection"
Write-Host "Not Protected:               $notProtected" -ForegroundColor $(if ($notProtected -gt 0) { "Red" } else { "Green" })
Write-Host "Unknown/Error:               $unknown" -ForegroundColor $(if ($unknown -gt 0) { "Yellow" } else { "Green" })

Write-Host "`nRISK ASSESSMENT" -ForegroundColor White
Write-Host "---------------"
Write-Host "High Risk:                   $highRisk" -ForegroundColor $(if ($highRisk -gt 0) { "Red" } else { "Green" })
Write-Host "Medium Risk:                 $mediumRisk" -ForegroundColor $(if ($mediumRisk -gt 0) { "Yellow" } else { "Green" })
Write-Host "Low Risk:                    $lowRisk" -ForegroundColor Green

Write-Host "`nDIAGNOSTIC LOGGING (Protected IPs)" -ForegroundColor White
Write-Host "----------------------------------"
Write-Host "DDoS Logging Enabled:        $diagConfigured" -ForegroundColor Green
Write-Host "Partial (No DDoS logs):      $diagPartial" -ForegroundColor $(if ($diagPartial -gt 0) { "Yellow" } else { "Green" })
Write-Host "Not Configured:              $diagNotConfigured" -ForegroundColor $(if ($diagNotConfigured -gt 0) { "Yellow" } else { "Green" })

# Show high-risk items
if ($highRisk -gt 0) {
    Write-Host "`nHIGH RISK PUBLIC IPs (Require Immediate Attention):" -ForegroundColor Red
    Write-Host "---------------------------------------------------"
    $allResults | Where-Object { $_.'Risk Level' -eq "High" } | Format-Table -Property 'Subscription', 'Public IP Name', 'Resource Type', 'Associated Resource', 'Recommendation' -AutoSize
}

# Show DDoS Plans in use
$ddosPlans = $allResults | Where-Object { $_.'DDoS Plan Name' -ne "N/A" -and $_.'DDoS Plan Name' -ne "N/A (IP Protection)" } | Select-Object -ExpandProperty 'DDoS Plan Name' -Unique
if ($ddosPlans.Count -gt 0) {
    Write-Host "`nDDOS PROTECTION PLANS IN USE:" -ForegroundColor White
    Write-Host "-----------------------------"
    $ddosPlans | ForEach-Object { Write-Host "  - $_" }
}

# Export option
if ($ExportPath) {
    $allResults | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "`nResults exported to: $ExportPath" -ForegroundColor Green
} else {
    Write-Host "`nTo export full results to CSV, run with -ExportPath parameter or use:" -ForegroundColor Yellow
    Write-Host '  $allResults | Export-Csv -Path "DDoS-Protection-Report.csv" -NoTypeInformation' -ForegroundColor Gray
}

# Return results for pipeline usage
return $allResults

