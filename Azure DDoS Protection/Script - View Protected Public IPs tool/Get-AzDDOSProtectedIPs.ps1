<#
.SYNOPSIS
    Identify Azure Public IP addresses and and associated VNet for DDOS protection 
.DESCRIPTION
    The script collects information on PIP and VNet resources and utilizes the information to determine associated resources and DDOS protection. 
.LINK
    https://github.com/Azure/Azure-Network-Security/tree/master/Azure%20DDoS%20Protection/Script%20-%20View%20Protected%20Public%20IPs%20tool
.NOTES
    v1.0 - Initial version
#>

#region variables
$filepathp = ".\pipresources.json"
$filepathv = ".\vnetresources.json"
$filepathr = ".\Az_PIP_DDOS_Report-$(get-date -Format yyyyMMdd-HHmm).csv"
$pipinfo = @()
$vnetinfo = @()
#endregion variables
#-----------------------------------------------------------------------------------------------------------------------
#region functions
function Get-PIPResources {
    if ($context) {
        $pipResource = @()
        $vnetResource = @()
        $allSub = Get-AzSubscription
        Write-Host -ForegroundColor Yellow "Collecting information on Public IP and Virtual Network resources for all subscriptions..."
        $allSub | foreach {
            Set-AzContext -SubscriptionId $_.Id
            $pipResource += Get-AzPublicIpAddress
            $vnetResource += Get-AzVirtualNetwork
        }
        $pipResource | ConvertTo-Json | Out-File pipresources.json
        $vnetResource | ConvertTo-Json | Out-File vnetresources.json
        Write-Host -ForegroundColor Green "Finished collecting Public IP and Virtual Network information" 
    }
    else {
        Write-Host -ForegroundColor Red "Please Login first in order to continue" 
    }
}
function Get-IPConfigDetails {
    param (
        [Parameter(Mandatory)]
        [String]$ipconfigtext,
        [Parameter(Mandatory)]
        [String]$pipName,
        [Parameter(Mandatory)]
        [String]$pipAddr,
        [Parameter(Mandatory)]
        [String]$pipID
    )
    $piphtable = @{}
    $array = $ipconfigtext.Split('/') 
    $pipID = Split-StringandReturn -stringinput $pipID -returnpart 2 # Get Azure Subscription ID from the PIP ID | Position 2 in ID String
    $piphtable = @{RG = $array[4]; RType = $array[7]; RName = $array[8]; PIPn = $pipName; PIPa = $pipAddr; PIPsub = $pipID }
    $objectp = New-Object psobject -Property $piphtable
    return $objectp
}
function Get-ConfigDetailsFromBEID {
    param (
        [Parameter(Mandatory)]
        [String]$BEnicconfigID
    )
    $lbhtable = @{}
    $array = $BEnicconfigID.Split('/')
    $lbhtable = @{RG = $array[4]; RType = $array[7]; RName = $array[8] }
    $object = New-Object psobject -Property $lbhtable
    return $object
}
function Get-VnetDetails {
    param (
        [Parameter(Mandatory)]
        [String]$vName,
        [Parameter(Mandatory)]
        [String]$vDDOSe,
        [Parameter(Mandatory)]
        [String]$vDDOSp,
        [Parameter(Mandatory)]
        [String]$uRG
    )
    $vnethtable = @{}
    $vnethtable = @{VNetName = $vName; DDOSEnabled = $vDDOSe; DDOSPlan = $vDDOSp; uRG = $uRG } 
    $objectv = New-Object psobject -Property $vnethtable
    return $objectv
}
function Split-StringandReturn {
    param(
        [Parameter(Mandatory)]
        [String]$stringinput,
        [Parameter(Mandatory)]
        [Int]$returnpart
    )
    $s = $stringinput.Split('/')
    return $s[$returnpart]
}
function Get-AzVNetFromSubnetID {
    param (
        [Parameter(Mandatory)]
        [String]$subnetid
    )
    $vnet = $subnetid.Split('/')
    return $vnet[8]
}
function Get-AzDDOSProtectPlan {
    param (
        [Parameter(Mandatory)]
        [String]$ddosplanID
    )
    $ddosplan = $ddosplanID.Split('/')
    return $ddosplan[8]
}
function New-CSVReportFile {
    param (
        [Parameter(Mandatory)]
        [String]$filepath
    )
    New-Item $filepath -type file -force
    Set-Content $filepath 'PIP_Name,PIP_Address,PIP_Subscription,Resource_Group,Associated_Resource,Resource_Type,Associated_Resource_RG,VNet,DDOS_Enabled,DDOS_Plan'
    Write-Host -ForegroundColor Green "Created $($filepathr)" 
}
function Clear-CreatedJSONFiles {
    param (
        [Parameter(Mandatory)]
        [String]$filepathp,
        [Parameter(Mandatory)]
        [String]$filepathv
    )
    Write-Host -ForegroundColor Yellow "Removing created JSON files..." 
    Remove-Item $filepathp -force
    Remove-Item $filepathv -force
    Write-Host -ForegroundColor Green "Removed JSON files $($filepathp) and $($filepathv)" 
}
#endregion functions
#--------------------------------------------------------------------------------------------
#region main
# Check if the user is logged in
Write-Host -ForegroundColor Yellow "Checking if there is an active Azure Context..." 
$context = Get-AzContext
if (!$context) {
    Connect-AzAccount
    $context = Get-AzContext
}
Write-Host -ForegroundColor Green "Context Retrieved Successfully." 
Write-Host $context.Name
# Get the PIP and VNet resources from all available Azure Subscriptions
Get-PIPResources

New-CSVReportFile -filepath $filepathr
# Parse the PIP resrouces from the pipresources JSON file
Write-Host -ForegroundColor Yellow "Parsing Public IP resources..." 
Get-Content -Path $filepathp | ConvertFrom-Json | foreach {
    $pipinfo += Get-IPConfigDetails -ipconfigtext $_.IpConfigurationText -pipName $_.Name -pipAddr $_.IpAddress -pipID $_.Id
}
# Parse the VNet resources from the vnetresources JSON file
Write-Host -ForegroundColor Yellow "Parsing Virtual Network resources..." 
Get-Content -Path $filepathv | ConvertFrom-Json | foreach {
    if ($_.DdosProtectionPlan.Id -ne $null) { $dplan = Get-AzDDOSProtectPlan -ddosplanID $_.DdosProtectionPlan.Id } else { $dplan = "Not Enabled" }
    $vnetinfo += Get-VnetDetails -vName $_.Name -vDDOSe $_.EnableDdosProtectionText -vDDOSp $dplan -uRG $_.ResourceGroupName
}
Write-Host -ForegroundColor Green "Finished parsing Public IP and Virtual Network resources" 
# Loop through the PIP resources sorted by PIP subscription to build the report csv file
Write-Host -ForegroundColor Yellow "Building report CSV file..." 
$pipinfo = $pipinfo | sort-object -Property PIPsub 
foreach ($p in $pipinfo) {
    # Check if the current Azure Subscription matches the PIP Subscription, if not Change the Azure Subscription
    $currentsub = (Get-AzContext).Subscription.id
    if ($p.PIPsub -ne $currentsub) {
        Write-Host "Current Subscription: " $currentsub " Changing to: " $p.PIPsub
        $si = $p.PIPsub
        Select-Azsubscription -Subscription $si
    }
    elseif ($p.PIPsub -eq $currentsub) {
        # Do nothing and continue on if the current subscription is the same as the PIP Subscription
    }
    else {
        Write-Host "There is a subscription issue"
    }
    #Filter based on resource type to perform proper get command on the azure resource for VNet information
    $v = $null
    $err = $null
    if ($p.RType -eq "azureFirewalls" -or $p.RType -eq "virtualNetworkGateways" -or $p.RType -eq "networkInterfaces" -or $p.RType -eq "bastionHosts") {
        if ($p.RType -eq 'azureFirewalls') {
            $fw = Get-AzFirewall -ResourceGroupName $p.RG -Name $p.RName
            $v = Get-AzVnetFromSubnetID -subnetid $fw.IpConfigurations.Subnet.Id
            $vurg = Split-StringandReturn -stringinput $fw.IpConfigurations.Subnet.Id -returnpart 4 # Get Vnet RG from the Subnet ID | Position 4 in Subnet ID String
            $rrg = Split-StringandReturn -stringinput $fw.Id -returnpart 4 # Get Resource RG from the Firewall ID | Position 4 in Firewall ID String
        }
        elseif ($p.RType -eq 'virtualNetworkGateways') {
            $gw = Get-AzVirtualNetworkGateway -ResourceGroupName $p.RG -Name $p.RName
            $v = Get-AzVnetFromSubnetID -subnetid $gw.IpConfigurations.Subnet.Id
            $vurg = Split-StringandReturn -stringinput $gw.IpConfigurations.Subnet.Id -returnpart 4 # Get Vnet RG from the Subnet ID | Position 4 in Subnet ID String
            $rrg = Split-StringandReturn -stringinput $gw.Id -returnpart 4 # Get Resource RG from the Gateway ID | Position 4 in Firewall ID String
        }
        elseif ($p.RType -eq 'networkInterfaces') {
            $ni = Get-AzNetworkInterface -ResourceGroupName $p.RG -Name $p.RName
            $v = Get-AzVnetFromSubnetID -subnetid $ni.IpConfigurations.Subnet.Id
            $vurg = Split-StringandReturn -stringinput $ni.IpConfigurations.Subnet.Id -returnpart 4 # Get Vnet RG from the Subnet ID | Position 4 in Subnet ID String
            $rrg = Split-StringandReturn -stringinput $ni.Id -returnpart 4 # Get Resource RG from the Network Interface ID | Position 4 in Network Interface ID String
        }
        elseif ($p.RType -eq 'bastionHosts') {
            $ba = Get-AzBastion -ResourceGroupName $p.RG -Name $p.RName
            $v = Get-AzVnetFromSubnetID -subnetid $ba.IpConfigurations.Subnet.Id
            $vurg = Split-StringandReturn -stringinput $ba.IpConfigurations.Subnet.Id -returnpart 4 # Get Vnet RG from the Subnet ID | Position 4 in Subnet ID String
            $rrg = Split-StringandReturn -stringinput $ba.Id -returnpart 4 # Get Resource RG from the Bastion ID | Position 4 in Bastion ID String
        }
        #$vr = $vnetinfo | where { $_.VNetName -eq $v } 
        $vr = Get-AzVirtualNetwork -ResourceGroupName $vurg -Name $v
        "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9}" -f $p.PIPn, $p.PIPa, $p.PIPsub, $p.RG, $p.RName, $p.RType, $rrg, $v, $vr.EnableDdosProtection, $vr.DdosProtectionPlan.Id  | add-content -path $filepathr
    }
    elseif ($p.RType -eq "applicationGateways") {
        $ag = Get-AzApplicationGateway -ResourceGroupName $p.RG -Name $p.RName
        if ($ag.BackendAddressPools.BackendAddresses.Count -gt 0) {
            $ag.BackendAddressPools.BackendAddresses | foreach {
                if ($_.IpAddress -eq $null) { $IPA = "Non VNet Resource" } else { $IPA = $_.IpAddress }
                "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9}" -f $p.PIPn, $p.PIPa, $p.PIPsub, $p.RG, $p.RName, $p.RType, $IPA, "Manual IP", "N/A", "N/A"  | add-content -path $filepathr
            }
        }
        if ($ag.BackendAddressPools.BackendIpConfigurations.Count -gt 0) {
            $ag.BackendAddressPools.BackendIpConfigurations | foreach {
                $apgwi = Get-ConfigDetailsFromBEID -BEnicconfigID $_.Id
                $appgwni = Get-AzNetworkInterface -ResourceGroupName $apgwi.RG -Name $apgwi.RName
                $appgwv = Get-AzVnetFromSubnetID -subnetid $appgwni.IpConfigurations.Subnet.Id
                $rrg = Split-StringandReturn -stringinput $appgwni.Id -returnpart 4 # Get Resource RG from the Network Interface ID | Position 4 in Network Interface ID String
                $vr = $vnetinfo | where { $_.VNetName -eq $appgwv }   
                "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9}" -f $p.PIPn, $p.PIPa, $p.PIPsub, $p.RG, $apgwi.RName, $apgwi.RType, $rrg, $appgwv, $vr.DDOSEnabled, $vr.DDOSPlan  | add-content -path $filepathr
            }
        }          
    }
    elseif ($p.RType -eq "loadBalancers") {
        $lb = Get-AzLoadBalancer -ResourceGroupName $p.RG -Name $p.RName
        $lb.BackendAddressPools.BackendIpConfigurations | foreach {
            $lbi = Get-ConfigDetailsFromBEID -BEnicconfigID $_.Id
            $ni = Get-AzNetworkInterface -ResourceGroupName $lbi.RG -Name $lbi.RName
            $v = Get-AzVnetFromSubnetID -subnetid $ni.IpConfigurations.Subnet.Id
            $vr = $vnetinfo | where { $_.VNetName -eq $v }   
            "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9}" -f $p.PIPn, $p.PIPa, $p.PIPsub, $p.RG, $lbi.RName, $lbi.RType, $lbi.RG, $v, $vr.DDOSEnabled, $vr.DDOSPlan  | add-content -path $filepathr 
        }
    }
    else {
        Write-Host -ForegroundColor Red "Associated resource type not found for $($p.PIPn)" 
        $err = 'Unable_To_Determine'
        $vr = $vnetinfo | where { $_.VNetName -eq $v } 
        "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9}" -f $p.PIPn, $p.PIPa, $p.PIPsub, $err, $err, $err, $rrg , $err, $err, $err  | add-content -path $filepathr
    }
}
Write-Host -ForegroundColor Green "Finished building report CSV file" 
Clear-CreatedJSONFiles -filepathp $filepathp -filepathv $filepathv
Write-Host -ForegroundColor Green "Generated report CSV file: $($filepathr)" 
Write-Host -ForegroundColor Green "Generated report is located at: $((Get-ChildItem $filepathr).FullName)"
#endregion main