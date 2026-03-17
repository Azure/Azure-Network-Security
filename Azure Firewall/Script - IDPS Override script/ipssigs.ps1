# Script:   ipssigs.ps1
# Date:     6/24/2025
# Author:   Kevin Tigges
<#

Needs the following Modules:

Az.Accounts
Az.Network

Makes use of ipsconfig.json to set the target subscription, Route Group, Firewall, Policy, Location and Rule Collection Group
Format Below

{
    "subs": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" ,
    "rg": "TEST-RG",
    "fw": "fw",
    "fwp": "fw-policy",
    "location" : "CentralUS",
    "rcg" : "DefaultNetworkRuleCollectionGroup"
    
}

Run the script, it will prompt for the filter fields, which is one of the below values, then the value
It is outputed to either the default file name, or the file that is entered in the prompot

#>

$direction = @{    
    "0" = "OutBound"
    "1"  = "Inbound"
    "2"  = "Any"
    "3"  = "Internal"
    "4"  = "InternalOutbound"
    "5"  = "InternalInbound"
}

$mode = @{
    "0" = "Disabled"
    "1" = "Alert"
    "2" = "Deny"
}

$sev = @{
    "1" = "High"
    "2" = "Medium"
    "3" = "Low"
}

$modedefinedby = @{
    "0" = "Policy Mode"
    "1" = "Default"
    "2" = "Parent"
    "3" = "Overidden"
 }

# Display Usage Instructions
Write-Host "`n=== IPS Signature Query Options ===`n" -ForegroundColor Yellow

# FIELD: direction
Write-Host "FIELD:" -ForegroundColor Yellow -NoNewline
Write-Host " direction" -ForegroundColor White
Write-Host "       VALUES:" -ForegroundColor Yellow
Write-Host "               OutBound" -ForegroundColor White
Write-Host "               InBound" -ForegroundColor White
Write-Host "               Any" -ForegroundColor White
Write-Host "               Internal" -ForegroundColor White
Write-Host "               InternalOutbound" -ForegroundColor White
Write-Host "               InternalInbound" -ForegroundColor White
Write-Host ""

# FIELD: mode
Write-Host "FIELD:" -ForegroundColor Yellow -NoNewline
Write-Host " mode" -ForegroundColor White
Write-Host "       VALUES:" -ForegroundColor Yellow
Write-Host "               Off" -ForegroundColor White
Write-Host "               Alert" -ForegroundColor White
Write-Host "               Deny" -ForegroundColor White
Write-Host ""

# FIELD: severity
Write-Host "FIELD:" -ForegroundColor Yellow -NoNewline
Write-Host " severity" -ForegroundColor White
Write-Host "       VALUES:" -ForegroundColor Yellow
Write-Host "               High" -ForegroundColor White
Write-Host "               Medium" -ForegroundColor White
Write-Host "               Low" -ForegroundColor White
Write-Host ""
Write-Host " Leave blank for no filter.....`n" -ForegroundColor White

# Accept multiple filters from the user
$filter = @()
do {
    $field = Read-Host "Enter Filter Field (e.g., direction, mode, severity)"

    if ([string]::IsNullOrWhiteSpace($field)) {
        break  # Exit the loop immediately
    }

    # Accept multiple values separated by space, then split into an array
    $rawValues = Read-Host "Enter one or more values for '$field' (space-separated)"
    $values = $rawValues -split '\s+'  # Split on one or more spaces

    # Add the filter entry
    $filter += @{ field = $field; values = $values }
    $another = Read-Host "Do you want to add another filter? (y/n)"
} while ($another -match '^(y|yes)$')

# CSV output
$filename = Read-Host "Enter CSV file name for export (leave blank for default)"
if ([string]::IsNullOrWhiteSpace($filename)) {
    $filename = ".\ipssignatures_results.csv"
}

$max = 1000
$skip = 0
$allResults = @()

# Load config
$json = Get-Content -Path "ipsconfig.json" -Raw
$config = $json | ConvertFrom-Json
$subs = $config.subs
$rg = $config.rg
$fwp = $config.fwp

# Auth
$token = get-azaccessToken -AsSecureString -ResourceURL "https://management.azure.com"
$token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token.Token)
)
$uri = "https://management.azure.com/subscriptions/$subs/resourceGroups/$rg/providers/Microsoft.Network/firewallPolicies/$fwp/listIdpsSignatures?api-version=2024-05-01"
$h = @{ "Authorization" = "Bearer $token" }

# If filters are blank - then set the filter value to null, otherwise populate the filter value
# If filters are blank - then set the filter value to null, otherwise populate the filter value
# If at least one filter entry is valid, use it. Otherwise, send an empty filter array.

if ($filter.Count -gt 0 -and $filter[0].ContainsKey('field') -and $filter[0].ContainsKey('values')) {
    $filters = $filter
} else {
    $filters = @()
}

# Query Loop
$ctr = 1
do {
    Write-Host "`rProcessing group $ctr" -NoNewline

    # Build request body dynamically
    $b = @{
        filters = $filters
        search = ""
        orderBy = @{
            field = "signatureId"
            order = "Ascending"
        }
        resultsPerPage = $max
        skip = $skip
        
    }

    $b = $b | ConvertTo-Json -Depth 10    
    try {
        $resp = Invoke-RestMethod -Uri $uri -Headers $h -Method Post -Body $b -ContentType "application/json"
    }
    catch {
        Write-Host "Error Making the Request: $($_.Exception.Message)"
        break
    }

    $allResults += $resp.signatures
    $skip += $max

    if ($resp.signatures.Count -lt $max) { break }
    $ctr++
} while ($resp.signatures.Count -eq $max)

# Export



Write-Host "`nExporting to CSV"
do {
    $exportFailed = $false
    try {
        $allResults | ForEach-Object {
            $_ | Select-Object `
                @{Name='signatureId'; Expression={$_.signatureId}}, `
                @{Name='mode'; Expression={ $mode[$_.mode.ToString()] }}, `
                @{Name='severity'; Expression={ $sev[$_.severity.ToString()] }}, `
                @{Name='direction'; Expression={ $direction[$_.direction.ToString()] }}, `
                @{Name='group'; Expression={ $_.group }}, `
                @{Name='description'; Expression={ $_.description }}, `
                @{Name='destination ports'; Expression={ ($_.destinationPorts -join ", ") }}, `
                @{Name='protocol'; Expression={ $_.protocol }}, `
                @{Name='alertonly'; Expression={ $_.alertOnly }}, `
                @{Name='lastUpdated'; Expression={ $_.lastUpdated.ToString() }}, `
                @{Name='modedefinedby'; Expression={ $modedefinedby[$_.modedefinedby.ToString()] }}
        } | Export-Csv -Path $filename -NoTypeInformation -Force
    }
    catch {
        Write-Host "`n`nFailed to export file '$filename'. It may be open or locked." -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
        $response = Read-Host "Press Y to try again, or anything else to exit"
        if ($response -notmatch '^(y|yes)$') {
            Write-Host "`nExiting without exporting."
            return
        }
        $exportFailed = $true
    }
} while ($exportFailed)

Write-Host "Exported $($allResults.Count) results to $filename"
Write-Host "Matching Record Count from API: $($resp.matchingRecordsCount)"