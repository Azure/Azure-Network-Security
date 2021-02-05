<#
    .SYNOPSIS
        This script will loop through all vnets for a list of subscriptions and determine which public IP addresses are protected or unprotected
    .Description
        Given a list of subscriptions this script will iterate all subscriptions and resources to find 
        whether or not resources are protected by DDOS 
    .PARAMETER SubscriptionIds
        String[]: Mandatory. 
        A list of subscription ids to search
    .PARAMETER CSVRootFileName
        String: Mandatory if OutToCsv is flagged. 
        A root file name for the output csv(s) of this function. Only enabled if OutToCsv is flagged. Files will be overwritten if they already exist

        For each subscription given to this command two CSV will output with name format:
        (current_directory)/$CSVRootFileName_SubscriptionID_ProtectionEnabled       and
        (current_directory)/$CSVRootFileName_SubscriptionID_ProtectionDisabled

        Contents of CSV will be:
        Name    ResourceGroup   Type    Location    PublicIpAddress (if it has one)     DdosProtected
    .PARAMETER OutToCsv
        String: Optional - If flagged, uses the CSVRootFileName to output the results of this search
    .PARAMETER SpecifyResourceGroups
        String[]: Optional - If present, only resource groups with this names will be searched
    .OUTPUTS
        Outputs a dictionary of the format
        {
            "SubscriptionId": 
            {
                "Enabled": 
                    {
                        "VnetId1": [
                            //Note these are the actual resource obtained by Get-Az<Resource>
                            "Resource1",
                            "Resource2"
                        ]
                    },
                "Disabled":
                    {
                        "VnedId2"[
                            "Resource3",
                            "Resource4"
                        ]
                    }
                ]
            }
        }
    .NOTES
        This script may run for a long time depending on how many resources you have in each subscription
    .EXAMPLE 
        $subDdosResources = (./Get-AllDdosProtectedIPs -SubscriptionIds 50d98c97-28f0-4034-88f6-fe47d3334d7c)

        Finds all DDOS enabled and disabled resources under the above subscription. Returns an object
        { "50d98c97-28f0-4034-88f6-fe47d3334d7c": { "Enabled": { "Vnets": [Resources ]}, "Disabled": { "Vnets": [Resources ]}}
    .EXAMPLE
        $subids = @("2a6f6cf4-092b-42f8-8f80-105dc153db2d", "164d0efe-e05c-4096-afbf-7b2648cb5b61")
        $subDdosResource = (./Get-AllDdosProtectedIPs -OutToCsv -SubscriptionIds $subids)

        Finds all DDOS enabled and disabled resources under the two subscriptions.
        Four CSV files will be generated using default $CSVRootFileName:
        (current_directory)/Azure_PublicIp_AndVnet_DdosAnalysis_2a6f6cf4-092b-42f8-8f80-105dc153db2d_ProtectionEnabled.csv
        (current_directory)/Azure_PublicIp_AndVnet_DdosAnalysis_2a6f6cf4-092b-42f8-8f80-105dc153db2d_ProtectionDisabled.csv
        (current_directory)/Azure_PublicIp_AndVnet_DdosAnalysis_164d0efe-e05c-4096-afbf-7b2648cb5b61_ProtectionEnabled.csv
        (current_directory)/Azure_PublicIp_AndVnet_DdosAnalysis_164d0efe-e05c-4096-afbf-7b2648cb5b61_ProtectionDisabled.csv


        Returns an object
        { 
            "2a6f6cf4-092b-42f8-8f80-105dc153db2d": 
                { "Enabled": { "Vnets": [Resources ]}, "Disabled": { "Vnets": [Resources]},
            "164d0efe-e05c-4096-afbf-7b2648cb5b61": 
                { "Enabled": { "Vnets": [Resources ]}, "Disabled": { "Vnets": [Resources]}
        }
    .EXAMPLE
        $subids = @("2a6f6cf4-092b-42f8-8f80-105dc153db2d", "164d0efe-e05c-4096-afbf-7b2648cb5b61")
        $subDdosResource = (./Get-AllDdosProtectedIPs -OutToCsv -CSVRootFileName "My_filename_root" -SubscriptionIds $subids)

        Outputs same as above example, except file names will be:
        (current_directory)/My_filename_root_<subid>_<ProtectionEnabled/ProtectionDisabled>csv

    .EXAMPLE
        $subids = @("2a6f6cf4-092b-42f8-8f80-105dc153db2d")
        $subDdosResource = (./Get-AllDdosProtectedIPs -SpecifyResourceGroups myResourceGroup, otherResourceGroup -SubscriptionIds $subids)

        No CSV will be output, but all resources under subscription "2a6f6cf4-092b-42f8-8f80-105dc153db2d" that are in resourceGroup 'myResourceGroup' or 'otherResourceGroup' will be checked
        
        Return object has same format
        { "2a6f6cf4-092b-42f8-8f80-105dc153db2d": { "Enabled": { "Vnets": [Resources]}, "Disabled": { "Vnets": [Resources]}}
    #>



param(
    [Parameter(Mandatory=$True)]
    [string[]] $SubscriptionIds = @(""),
    [string] $CSVRootFileName = "Azure_PublicIp_AndVnet_DdosAnalysis",
    [string[]] $SpecifyResourceGroups = $null,
    [switch] $OutToCsv
)

#Many resources are cyclically referenced - this hashset ensures we do not add a resource more than once
$DiscoveredResources = New-Object System.Collections.Generic.HashSet[string]

<#
    Helper, ensure we can write to CSV before iterating whole sub
#>
function Test-FileCanBeWritten {
    param (
      [parameter(Mandatory=$true)][string]$Path
    )
  
    $oFile = New-Object System.IO.FileInfo $Path

    #lack permissions
    Try {
        [io.file]::OpenWrite($Path).close()
    }
    Catch { 
        return $false
    }
  
    #next we check if file is open

    # file does not exist, can't be open, we can write to it
    if ((Test-Path -Path $Path) -eq $false) {
      return $true
    }

    # check if we can write to the file, if not it is open
    try {
      $oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
  
      if ($oStream) {
        $oStream.Close()
      }
      #will fail if it is locked
      return $true
    } catch {

      # file is locked
      return $false
    }
}

function Add-ResourceToVnetDict{
    param(
        [object] $EnabledDict,
        [object] $DisabledDict,
        [object] $Resource,
        [object] $Vnet
    )

    #this should not happen, but protects against the case that vnet failed to get resolved in one of the components
    if($null -eq $Vnet -or $null -eq $Vnet.Id){
        $Vnet = "UnknownVnet"
    }

    $curDict = $EnabledDict

    #assume an unknown Vnet does not have ddos protection to be safe
    if($Vnet -eq "UnknownVnet" -or !$Vnet.EnableDdosProtection){
        $curDict = $DisabledDict
    }

    if($null -ne $Resource){    
        if($DiscoveredResources.Contains($Resource.Id)){
            return
        }

        $DiscoveredResources.Add($Resource.Id) | Out-Null
        if(!$curDict.ContainsKey("$($Vnet.Id)")){
            #$vpn.IpConfigurations | ConvertTo-Json
            $curDict["$($Vnet.Id)"] = @($Resource)
        }else{
            $curDict["$($Vnet.Id)"] += @($Resource)
        }
    }
}

function Resolve-VirtualMachineScaleSetIpConfToVnet{
    param(
        [object] $EnabledDict,
        [object] $DisabledDict,
        [object] $Vnets,
        [object] $IpConfId
    )

    $vmssName = [regex]::match($IpConfId, '/virtualMachineScaleSets/([^/]*)/').Groups[1].Value 
    $rg = [regex]::match($IpConfId, '/resourceGroups/([^/]*)/').Groups[1].Value 
    $myVnet = "UnknownVnet"

    #try to match our ip config with one in one of the vnets 
    foreach($vnet in $Vnets){
        foreach($subnet in $vnet.Subnets){
            foreach($ipconf in $subnet.IpConfigurations){
                if($ipconf.Id -eq $IpConfId){
                    $myVnet = $vnet
                }
            }
        }
    }

    $vmss = Get-AzVmss -ResourceGroupName $rg -VMScaleSetName $vmssName
    Add-ResourceToVnetDict -EnabledDict $EnabledDict -DisabledDict $DisabledDict -Resource $vmss -Vnet $myVnet
}

function Resolve-NicIpsToVnet{
    param(
        [object] $EnabledDict,
        [object] $DisabledDict,
        [object] $Vnet,
        [object] $Nics
    )

    #get all public ips that have a public ip address
    foreach($nic in $Nics){
        $ipId = ($nic.PublicIPAddress.Id)
        if($ipId){
            $ipName = [regex]::match($ipId, '/publicIPAddresses/([^/]*)').Groups[1].Value
            $ipRg = [regex]::match($ipId, '/resourceGroups/([^/]*)').Groups[1].Value

            $ipR = Get-AzPublicIpAddress -Name $ipName -ResourceGroupName $ipRg
            if($ipR){
                $ips += @($ipR)
            }
        }
    }

    foreach($ip in $ips)
    {
        Add-ResourceToVnetDict -EnabledDict $EnabledDict -DisabledDict $DisabledDict -Resource $ip -Vnet $Vnet
    }
}


function Resolve-LoadBalancerIps{
    param(
        [object] $Vnets,
        [object] $EnabledDict,
        [object] $DisabledDict,
        [string] $SpecifyResourceGroups
    )

    Write-Host "Resolving Load Balancer IPs..." -ForegroundColor Yellow

    $slbs = (Get-AzLoadBalancer)

    if($SpecifyResourceGroups){
        $slbs = ($slbs | Where-Object{ $_.ResourceGroupName -in $SpecifyResourceGroups })
    }

    foreach($slb in $slbs){
        foreach($pool in $slb.BackendAddressPools){
            foreach($conf in $pool.BackendIpConfigurations){
                if($conf.Id.Contains("virtualMachineScaleSets")){
                    $id = $conf.Id
                    $vmssName = [regex]::match($id, '/virtualMachineScaleSets/([^/]*)/').Groups[1].Value 

                    $myVnet = "UnknownVnet"

                    #try to match our ip config with one in one of the vnets 
                    foreach($vnet in $Vnets){
                        foreach($subnet in $vnet.Subnets){
                            foreach($ipconf in $subnet.IpConfigurations){
                                if($ipconf.Id -eq $id){
                                    $myVnet = $vnet
                                }
                            }
                        }
                    }

                    $vmss = Get-AzVmss -ResourceGroupName $rg -VMScaleSetName $vmssName
                    Add-ResourceToVnetDict -EnabledDict $EnabledDict -DisabledDict $DisabledDict -Resource $vmss -Vnet $myVnet

                    $ipid = $slb.FrontendIpConfigurations.PublicIpAddress.Id
                    if($ipid){
                        $resourceGroup = [regex]::match($ipid, '/resourceGroups/([^/]*)/').Groups[1].Value
                        $ipName = [regex]::match($ipid, '/publicIPAddresses/([^/]*)').Groups[1].Value
                        $ipR = Get-AzPublicIpAddress -Name $ipName -ResourceGroupName $resourceGroup
                        Add-ResourceToVnetDict -EnabledDict $EnabledDict -DisabledDict $DisabledDict -Resource $ipR -Vnet $myVnet
                    }

                    #concept is whole vmscaleset shares the same vnet, therefore break out of this loop
                    break;

                }else{

                    # A generic VM behind a load balancer will get resolved when we iterate virtual networks 
                    # this is found later in the script. if you want to run this function as a standalone, uncomment below code and remove break
                    break;

                    # Write-Host "Resolving VM"
                    # $id = $conf.Id

                    # $nic = [regex]::match($id, '/networkInterfaces/([^/]*)/').Groups[1].Value 
                    # $rg =  [regex]::match($id, '/resourceGroups/([^/]*)/').Groups[1].Value 

                    # $nicResource = Get-AzNetworkInterface -ResourceGroupName $rg -Name $nic
                    # $subnetId = $nicResource.IpConfigurations[0].Subnet.Id
                    # $ipId =  $nicResource.IpConfigurations[0].PublicIpAddress.Id

                    # if(!$ipId){
                    #     #no public ip assigned to this resource, continue
                    #     continue;
                    # }

                    # $vnetName = [regex]::match($subnetId, '/virtualNetworks/([^/]*)/').Groups[1].Value
                    # $vnetRg =  [regex]::match($subnetId, '/resourceGroups/([^/]*)/').Groups[1].Value

                    # #note missing / after ip string
                    # $ipName = [regex]::match($ipId, '/publicIPAddresses/([^/]*)').Groups[1].Value
                    # $ipRg =  [regex]::match($ipId, '/resourceGroups/([^/]*)/').Groups[1].Value

                    # $vnet = $Vnets | Where-Object {$_.Name -eq $vnetName -and $_.ResourceGroupName -eq $vnetRg }
                    # $ip = Get-AzPublicIpAddress -Name $ipName -ResourceGroupName $ipRg

                    # Add-ResourceToVnetDict -EnabledDict $EnabledDict -DisabledDict $DisabledDict -Resource $ip -Vnet $vnet        
                }
            }
        }
    }
}

function Resolve-AppGatewayVnetToIps{
    param(
        [object] $Vnets,
        [object] $EnabledDict,
        [object] $DisabledDict,
        [object] $SpecifyResourceGroups
    )

    Write-Host "Resolving Application Gateway IPs..." -ForegroundColor Yellow

    $appGateways = Get-AzApplicationGateway

    if($SpecifyResourceGroups){
        $appGateways = ($appGateways | Where-Object{ $_.ResourceGroupName -in $SpecifyResourceGroups })
    }

    foreach($gateway in $appGateways){
        $id = $gateway.HttpListeners.FrontendIpConfiguration.Id
        $resourceGroup = [regex]::match($id, '/resourceGroups/([^/]*)/').Groups[1].Value
        $ipConfName = [regex]::match($id, '/frontendIPConfigurations/([^/]*)').Groups[1].Value

        $ipConf = Get-AzApplicationGatewayFrontendIPConfig -Name $ipConfName -ApplicationGateway $gateway 


        if($ipConf.PublicIPAddress){
            $subnetId = $gateway.GatewayIPConfigurations.Subnet.Id
            $vnetRg = [regex]::match($subnetId, '/resourceGroups/([^/]*)/').Groups[1].Value
            $vnetName = [regex]::match($subnetId, '/virtualNetworks/([^/]*)/').Groups[1].Value

            $myVnet = "UnknownVnet"
            foreach($vnet in $Vnets){
                if($vnet.ResourceGroupName -eq $vnetRg -and $vnet.Name -eq $vnetName){
                    $myVnet = $vnet
                }
            }

            $ipId = $ipConf.PublicIPAddress.Id
            $resourceGroup = [regex]::match($ipId, '/resourceGroups/([^/]*)/').Groups[1].Value
            $ipName = [regex]::match($ipId, '/publicIPAddresses/([^/]*)').Groups[1].Value

            $ip = Get-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name $ipName

            Add-ResourceToVnetDict -EnabledDict $EnabledDict -DisabledDict $DisabledDict -Resource $ip -Vnet $myVnet
        }
    }
}

function Format-DdosProtectionTable{
    param(
        [object] $DdosDictionary,
        [object] $Vnets,
        [bool] $Enabled
    )

    $color = if($Enabled) { "Green" } else { "Red" }
    $enabledString = if($Enabled) { "protected by DDOS"} else { "NOT protected by DDOS" }
    $formatHeader = "{0}{1}{2}{3}{4}{5}" -f "Name".PadRight(25), "ResourceGroup".PadRight(25), "Type".PadRight(60), "Location".PadRight(25), "PublicIpAddress".PadRight(25), "DdosProtected".PadRight(20)
    $dash = "{0}" -f "".PadRight(180,'-')
    $formatStr = "{0}{1}{2}{3}{4}{5}"

    $OutObjects = @()
    
    foreach($vnet in $DdosDictionary.Keys){
        foreach($resource in $DdosDictionary[$vnet]){
            $OutObjects += @(
                [PSCustomObject]@{
                Name = $resource.Name;
                ResourceGroupName = $resource.ResourceGroupName;
                Type = $resource.Type;
                Location = $resource.Location;
                DdosProtected = $Enabled;
                #will be null if resource is not an ip address
                PublicIpAddress = $resource.IpAddress;
                Id = $resource.Id;
                VirtualNetworkId = $vnet;
            })
        }
    }

    Write-Host "The following Vnets are $enabledString" -ForegroundColor Yellow
    $Vnets | Write-Host -ForegroundColor $color
    Write-Host " "
    Write-Host "These are the resources under those VNETs:" -ForegroundColor Yellow

    Write-Host $formatHeader -ForegroundColor $color
    Write-Host  $dash -ForegroundColor $color
    $OutObjects | Foreach-Object {
        $formatted =  $formatStr -f "$($_.Name)".PadRight(25), "$($_.ResourceGroupName)".PadRight(25), `
                "$($_.Type)".PadRight(60), "$($_.Location)".PadRight(25), "$($_.PublicIpAddress)".PadRight(25),"$($_.DdosProtected)".PadRight(20);
        Write-Host $formatted -ForegroundColor $color;
    }

    Write-Host " "

    return $OutObjects
}


if($OutToCsv -and !$CSVRootFileName){
    Write-Host "CSVRootFileName must be specified if OutToCsv is flagged" -ForegroundColor Red
    return
}

# Ensure that we can write to where the csvs will be written
if($OutToCsv){
    $cwd = Get-Location

    foreach($subId in $SubscriptionIds){
        $csvFile = "$($cwd)`\$($CSVRootFileName)_$($subscriptionId)_ProtectionEnabled.csv"
        if (!(Test-FileCanBeWritten $csvFile)){
            Write-Host "Unable to write to " -ForegroundColor Red -NoNewline; Write-Host $csvFile -ForegroundColor Cyan -NoNewline; Write-Host " which would be generated by this script." -ForegroundColor Red
            Write-Host "-> Please check if file is open or if you have access to this directory." -ForegroundColor Red
            return
        }

        $csvFile = "$($cwd)`\$($CSVRootFileName)_$($subscriptionId)_ProtectionDisabled.csv"
        if (!(Test-FileCanBeWritten $csvFile)){
            Write-Host "Unable to write to " -NoNewline; Write-Host $csvFile -ForegroundColor Cyan -NoNewline; Write-Host " which would be generated by this script." -ForegroundColor Red
            Write-Host "-> Please check if file is open or if you have access to this directory." -ForegroundColor Red
            return
        }
    }
}



$subIdToDicts = @{}

foreach($subscriptionId in $SubscriptionIds){
    $EnabledDict = @{}
    $DisabledDict = @{}

    $vnetsNotEnabled = @()
    $vnetsEnabled = @()

    Write-Host "Finding resources under subscription $subscriptionId"
    $context = Get-AzContext 

    #if we need to, log in
    if($null -eq $context.Account)
    {
        Connect-AzAccount -Subscription $subscriptionId | Out-Null
    }

    #in case we weren't logged in, context will have changed
    $context = Get-AzContext

    #check if connected to right subscription id
    if(-not ($context.name -like ("*" + $subscriptionId + "*"))){
        Write-Host "Acquiring subscription for this resource"
        Get-AzSubscription -subscriptionid $subscriptionId | Select-AzSubscription
    }

    Write-Host "Acquiring virtual networks..." -ForegroundColor Yellow
    $vnets = Get-AzVirtualNetwork

    if($SpecifyResourceGroups){
        $vnets = ($vnets | Where-Object{ $_.ResourceGroupName -in $SpecifyResourceGroups })
    }

    Resolve-AppGatewayVnetToIps -Vnets $vnets -EnabledDict $EnabledDict -DisabledDict $DisabledDict -SpecifyResourceGroups $SpecifyResourceGroups
    Resolve-LoadBalancerIps -Vnets $vnets -EnabledDict $EnabledDict -DisabledDict $DisabledDict -SpecifyResourceGroups $SpecifyResourceGroups

    $ipconfCount = $vnets.Subnets.IpConfigurations.Count
    $curConf = 0

    #resolve the rest
    foreach($vnet in $vnets){
        if($vnet.EnableDdosProtection){
            $curDict = $vnetToIpMapping
            $vnetsEnabled += @($vnet.Id)
        }else{
            $curDict = $vnetToIpMappingNoDdos
            $vnetsNotEnabled += @($vnet.Id)
        }

        Write-Host "Getting ips behind vnet $($vnet.Name)" -ForegroundColor Yellow
        $subnets = $vnet.Subnets
        Write-Host "$($subnets.Count) subnets behind this vnet"
        
        foreach($subnet in $subnets){
            $ipconfigs = $subnet.IpConfigurations

            if($ipconfigs.Count -eq 0){    
                #App gateway will have 0 ip configs            
                continue;
            }

            Write-Host "$($ipconfigs.Count) ip configurations behind this subnet: $($subnet.Name)"

            foreach($ipconf in $ipconfigs)
            {
                Write-Progress -Activity "Iterating VNET: $($vnet.Name)" -Status "Progress for Sub: $subscriptionId ->" `
                        -PercentComplete (($curConf * 100) / $ipconfCount)

                $resourceType = [regex]::match($ipconf.Id, '/Microsoft.Network/([^/]*)/').Groups[1].Value
                
                if($ipconf.Id.Contains("virtualMachineScaleSets")){
                    Resolve-VirtualMachineScaleSetIpConfToVnet -EnabledDict $EnabledDict -DisabledDict $DisabledDict -Vnets $vnets -IpConfId $ipconf.id
                }elseif($resourceType -eq "networkInterfaces"){
                    $resourceGroup = [regex]::match($ipconf.Id, '/resourceGroups/([^/]*)/').Groups[1].Value
                    $networkInterface = [regex]::match($ipconf.Id, '/networkInterfaces/([^/]*)/').Groups[1].Value
                    
                    $nics = (Get-AzNetworkInterface -Name $networkInterface -ResourceGroupName $resourceGroup).IpConfigurations
                    Resolve-NicIpsToVnet -EnabledDict $EnabledDict -DisabledDict $DisabledDict -Vnet $vnet -Nics $nics
                }elseif($resourceType -eq "azureFirewalls"){
                    $firewallName = [regex]::match($ipconf.Id, '/azureFirewalls/([^/]*)/').Groups[1].Value
                    $resourceGroup = [regex]::match($ipconf.Id, '/resourceGroups/([^/]*)/').Groups[1].Value
                    $nics = (Get-AzFirewall -ResourceGroupName $resourceGroup -Name $firewallName).IpConfigurations

                    Resolve-NicIpsToVnet -EnabledDict $EnabledDict -DisabledDict $DisabledDict -Vnet $vnet -Nics $nics

                }elseif($resourceType -eq "virtualNetworkGateways"){
                    $resourceName = [regex]::match($ipconf.Id, '/virtualNetworkGateways/([^/]*)/').Groups[1].Value
                    $resourceGroup = [regex]::match($ipconf.Id, '/resourceGroups/([^/]*)/').Groups[1].Value

                    $nics = (Get-AzVirtualNetworkGateway -Name $resourceName -ResourceGroupName $resourceGroup).IpConfigurations

                    Resolve-NicIpsToVnet -EnabledDict $EnabledDict -DisabledDict $DisabledDict -Vnet $vnet -Nics $nics
                }
                $curConf += 1           
            }
        }
    }
    $OutObjectsDisabled = Format-DdosProtectionTable -DdosDictionary $DisabledDict -Vnets $vnetsNotEnabled -Enabled $False
    $OutObjectsEnabled = Format-DdosProtectionTable -DdosDictionary $EnabledDict -Vnets $vnetsEnabled -Enabled $True

    if($OutToCsv){
        $cwd = Get-Location
        $csvFile = "$($cwd)`\$($CSVRootFileName)_$($subscriptionId)_ProtectionDisabled.csv"
        $OutObjectsDisabled | Export-Csv -Path $csvFile -NoTypeInformation
        $csvs += @($csvFile)

        $csvFile = "$($cwd)`\$($CSVRootFileName)_$($subscriptionId)_ProtectionEnabled.csv"
        $OutObjectsEnabled | Export-Csv -Path $csvFile -NoTypeInformation
        $csvs += @($csvFile)
    }

    $subIdToDicts[$subscriptionId] = @{}
    $subIdToDicts[$subscriptionId]["Enabled"] = $EnabledDict;
    $subIdToDicts[$subscriptionId]["Disabled"] = $DisabledDict;
}

if($OutToCsv){
    Write-Host " "
    Write-Host "The following files have been generated" -ForegroundColor Yellow
    $csvs | Write-Host -ForegroundColor Green
}

return $subIdToDicts