<#
    1.	Install Pre requisites Az PowerShell modules  (https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-5.7.0)
    2.	From PowerShell prompt navigate to folder where the script is saved and run the following command
        .\Get-AzDNSDanglingNsRecords.ps1 -SubscriptionId <subscription id> -ZoneName <zonename>
        Replace subscription id with subscription id of interest.
        ZoneName with actual zone name.
#>
param(
    # subscription if to fetch dns records from
    [String]$SubscriptionId = "All",

    #filtering zone name
    [String]$ZoneName = "All"
) 

if ($SubscriptionId -eq "All") {
    Write-Host -ForegroundColor Yellow "No subscription Id passed will process all subscriptions"
}

if ($ZoneName -eq "All") {
    Write-Host -ForegroundColor Yellow "No Zone name passed will process all zones in subscription"
}


$ErrorActionPreference = "Stop"

$AZModules = @('Az.Accounts', 'Az.Dns')
$AzLibrariesLoadStart = Get-Date
$progressItr = 1; 
$ProgessActivity = "Loading required Modules";
$StoreWarningPreference = $WarningPreference
$WarningPreference = 'SilentlyContinue'
Foreach ($module in $AZModules) {
    $progressValue = $progressItr / $AZModules.Length
    Write-Progress -Activity $ProgessActivity -Status "$module $($progressValue.ToString('P')) Complete:" -PercentComplete ($progressValue * 100)

    If (Get-Module -Name $module) {
        continue
    }
    elseif (Get-Module -ListAvailable -Name $module) {
        Import-Module -name $module -Scope Local -Force
    }
    else {
        Install-module -name $module -AllowClobber -Force -Scope CurrentUser
        Import-Module -name $module -Scope Local -Force
    }

    $progressItr = $progressItr + 1;
    If (!$(Get-Module -Name $module)) {
        Write-Error "Could not load dependant module: $module"
        throw
    }
}
$WarningPreference = $StoreWarningPreference
Write-Progress -Activity $ProgessActivity -Completed

$context = Get-AzContext;
# if ($context.TokenCache -eq $null) {
#     Write-host -ForegroundColor Yellow "Please Login to Azure Account using Login-AzAccount and run the script."
#     exit
# } 
$subscriptions = Get-AzSubscription

if ($SubscriptionId -ne "All") {
    $subscriptions = $subscriptions | Where-Object { $_.Id -eq $SubscriptionId }
    if ($subscriptions.Count -eq 0) {
        Write-host -ForegroundColor Yellow "Provided Subscription Id not found exiting."
        exit
    }
}

$scount = $subscriptions | Measure-Object
Write-Host "Subscriptions found $($scount.Count)"
if ($scount.Count -lt 1) {
    exit
}
$InvalidItems = @()
$TotalRecCount = 0;
$ProgessActivity = "Processing Subscriptions";
$progressItr = 1; 

$nsRecordsToProcess = @()
$allNsRecords = @()
$allDnsZones = @()
$subscriptions | ForEach-Object {
    $progressValue = $progressItr / $scount.Count
    Select-AzSubscription -Subscription $_  | Out-Null
    Write-Progress -Activity $ProgessActivity -Status "current subscription $_  $($progressValue.ToString('P')) Complete:" -PercentComplete ($progressValue * 100)
    $progressItr = $progressItr + 1;
    try {
        $dnsZones = Get-AzDnsZone -ErrorAction Continue
        $allDnsZones += $dnsZones
        $dnsZones | ForEach-Object {
            $zonesNsRecords = Get-AzDnsRecordSet -Zone $_ -RecordType NS | Where-Object { $_.Name -ne '@' }
            $allNsRecords += $zonesNsRecords
            if ($ZoneName -eq 'All' -or $_.Name -eq $ZoneName) {
                $nsRecordsToProcess += $zonesNsRecords
            }
        }
    }
    catch {
        Write-Host "Error retrieving DNS Zones for subscription $_"
        return;
    }
}


$nsRecordsToProcess | ForEach-Object {    
    $rec = $_
    $dnsZoneForNsRecord = $allDnsZones | Where-Object { $_.Name -eq "$($rec.Name).$($sZoneName)" }
    $dangling = $null -eq $dnsZoneForNsRecord
    $missingNameServersInDnsZone = @()
    if (-not $dangling) {
        $missingNameServersInDnsZone = $rec.Records.Where({ !$dnsZoneForNsRecord.NameServers.Contains($_) })
    }
    $TotalRecCount++
    if ($dangling -or ($missingNameServersInDnsZone.Length -gt 0)) {
        Write-Host -ForegroundColor Yellow "NS record: $($rec.Name). ZoneName $sZoneName. Subscription $subscription" 
        $hash = @{
            Name                                = $rec.Name
            RecordType                          = $rec.RecordType
            ZoneName                            = $sZoneName
            Dangling                            = $dangling
            NsRecordNameServersMissingInSubZone = $missingNameServersInDnsZone
            subscriptionId                      = $subscription
        }
        $item = New-Object PSObject -Property $hash    
        $InvalidItems += $item
    }
    else {
        # Write-Host -ForegroundColor Green "$($rec.Name) recordType $($rec.RecordType)  zoneName $ZoneName  subscription $subscription " 
    }
}

Write-Progress -Activity $ProgessActivity -Completed

Write-Host "Total records processed $TotalRecCount"
$invalidMeasure = $InvalidItems | Measure-Object
Write-Host "Suspicious Count  $($invalidMeasure.Count)"

Write-Host "Suspicious Records "
Write-Host "==============="

$InvalidItems | Format-Table