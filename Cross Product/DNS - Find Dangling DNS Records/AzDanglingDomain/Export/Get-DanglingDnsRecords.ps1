# Function to compute the time
#
Function Get-TimeToProcess {
    param
    (
        $startTime
    )
    return [math]::Round(($(Get-Date) - $startTime).TotalMilliseconds)
}

#Function to return resource provider
#
Function Get-ResourceProvider {
    param
    (
        $resourceName
    )
    switch -regex ($resourceName) {
        'azure-api.net$' { $resourceProvider = 'azure-api.net'; break }
        'azurecontainer.io$' { $resourceProvider = 'azurecontainer.io'; break }
        'azurefd.net$' { $resourceProvider = 'azurefd.net'; break }
        'azureedge.net$' { $resourceProvider = 'azureedge.net'; break }
        'azurewebsites.net$' { $resourceProvider = 'azurewebsites.net'; break }
        'blob.core.windows.net$' { $resourceProvider = 'blob.core.windows.net'; break }
        'cloudapp.azure.com$' { $resourceProvider = 'cloudapp.azure.com'; break }
        'cloudapp.net$' { $resourceProvider = 'cloudapp.net'; break }
        'trafficmanager.net$' { $resourceProvider = 'trafficmanager.net'; break }
    }
    return $resourceProvider
}

# Function to add resource provider
#
Function Add-ResourceProvider {
    param
    (
        $resourceList
    )
    
    $resourceList | ForEach-Object `
    {       
        If (!$psitem.resourceProvider) {
            $psitem | Add-Member -NotePropertyName "resourceProvider" -NotePropertyValue $(Get-ResourceProvider $psitem.Fqdn) -Force
        }
    }
}


# Function to retrive the Azure DNS records
#
Function Get-DnsCNameRecords {
    param
    (
        $zone
    )

    $cNameToDnsMap = [System.Collections.ArrayList]::new()
        
    $cNameRecords = Get-AzDnsRecordSet -ResourceGroupName $zone.resourceGroup -ZoneName $zone.Name -RecordType CNAME
                        
    Foreach ($item in $cNameRecords) {
        foreach ($record in $item.records) {            
            [void]$cNameToDnsMap.add([psCustomObject]@{'CName' = $item.Name; 'Fqdn' = $record.CName; 'ZoneName' = $zone.Name;
                    'ResourceGroup' = $zone.ResourceGroup; 'resourceProvider' = $(Get-ResourceProvider $record)
                })
        }
    }
    return $CNameToDnsMap
}

# Function to iterate each DNS zone and fetch the Azure DNS records
#
Function Get-AzCNameToDnsMap {    
    param
    (
        $dnsZones
    )
    $cNameToDnsMapList = [System.Collections.ArrayList]::new()
    Foreach ($zone in $dnsZones) {
        $interestedRecords = Get-DnsCNameRecords $zone | Where-Object { $psitem.Fqdn -match $interestedAzureDnsZones }
        Foreach ($record in $interestedRecords) {
            $record | Add-Member -NotePropertyName 'subscriptionName' -NotePropertyValue $psitem.Name -Force
            $record | Add-Member -NotePropertyName 'subscriptionId' -NotePropertyValue $psitem.Id -Force
            [void]$cNameToDnsMapList.add($record)
        }
    }
    return $CNameToDnsMapList
}

# Function to retrieve the Azure resource records
#
Function Get-AZResources {
    param
    (    
        [int]$startId,

        [long]$endId,

        $query
    )

    If ($endId -gt 0) {
        $params = @{ 'First' = $startId; 'Skip' = $endId }
    }
    else {
        $params = @{ 'First' = $startId }
    }
    return $(Search-AzGraph -Query $query @params)    
}

# Fetch Azure resource as list
Function Get-AZResourcesList {
    param
    (
        $query
    )

    $AzResources = [System.Collections.ArrayList ]::new()

    $numberOfResources = (Search-AzGraph -Query $( -join ($query, ' |  summarize TotalResources=count()'))).TotalResources
    $maxRecords = 1000
    $skipRecords = 0
    Do {
        $AzResources += Get-AzResources -startId $maxRecords -endId $skipRecords -query $query
        $skipRecords += $maxRecords
    
    }Until($numberOfResources -le $skipRecords)
    
    return $AzResources
}

# Fetch Azure resource as dictionary
Function Get-AZResourcesHash {
    param
    (
        $query,
        $keyName
    )

    $AzResources = [System.Collections.Hashtable]::new()
    $ProgessActivity = "Fetching resources"
    $percentage = 0
    Write-Progress $ProgessActivity -Status "$percentage precentage Complete:" -PercentComplete $percentage
    $AzResourcesList = Search-AzGraph -Query $( -join ($query, ' |  summarize TotalResources=count()'))
    if(($null -ne $AzResourcesList) -and   ($null -ne $AzResourcesList.Data))
    {
            $AzResourcesList = $AzResourcesList.Data
    }
    $numberOfResources =  $AzResourcesList.TotalResources
    $maxRecords = 1000
    $skipRecords = 0
    Do {

        $percentage = $skipRecords / $numberOfResources
        Write-Progress $ProgessActivity -Status "$($percentage.ToString('P')) Complete ($skipRecords/$numberOfResources):" -PercentComplete ($percentage*100)

        $Resources = Get-AZResources -startId $maxRecords -endId $skipRecords -query $query
        if ($Resources.Data -is [System.Collections.Generic.IList[psobject]]) {$Resources = $Resources.Data}
    
        $Resources |  ForEach-Object `
        { 
            $key = $psitem.$keyName.trim(" ").tolower()
            If ($AzResources.ContainsKey($key)) {
                $recordList = $AzResources[$key]
                $recordList.add($psitem) | Out-Null
                $AzResources[$key] = $recordList
            }
            else {
                $recordList = [System.Collections.ArrayList]::new()
                [void]$recordList.add($psitem)
                $AzResources.add($key, $recordList)
            }
        }
        $skipRecords += $maxRecords
    
    }Until($numberOfResources -le $skipRecords)    
    
    Write-Progress $ProgessActivity -Completed
    return $AzResources
}

# For running the workflows in parellel by for each DNS zone
#
Function Get-DnsRecordsWorkFlow {
    param
    (
        $wfDnsZones,        
        $wfContext,
        $wfInterestedDnsZones
    )
    
    $wfdnsZones | ForEach-Object -parallel {
    
        $wfdnsZone = $PSItem

        inlinescript
        {
          
            $AZModules = ('Az.Accounts', 'Az.Dns')
            Foreach ($module in $AZModules) {
                If (Get-Module -Name $module) {
                    continue
                }
                elseif (Get-Module -ListAvailable -Name $module) {
                    Import-Module -name $module -Scope Local -Force -ErrorAction Ignore 
                }
                else {
                    Install-module -name $module -AllowClobber -Force -Scope CurrentUser -SkipPublisherCheck
                    Import-Module -name $module -Scope Local -Force
                }
            
                If (!$(Get-Module -Name $module)) {
                    Write-Error "Could not load dependant module: $module"
                    throw
                }
            }

            #Function to return resource provider
            Function Get-ResourceProvider {
                param
                (
                    $resourceName
                )
                switch -regex ($resourceName) {
                    'azure-api.net$' { $resourceProvider = 'azure-api.net'; break }
                    'azurecontainer.io$' { $resourceProvider = 'azurecontainer.io'; break }
                    'azurefd.net$' { $resourceProvider = 'azurefd.net'; break }
                    'azureedge.net$' { $resourceProvider = 'azureedge.net'; break }
                    'azurewebsites.net$' { $resourceProvider = 'azurewebsites.net'; break }
                    'blob.core.windows.net$' { $resourceProvider = 'blob.core.windows.net'; break }
                    'cloudapp.azure.com$' { $resourceProvider = 'cloudapp.azure.com'; break }
                    'cloudapp.net$' { $resourceProvider = 'cloudapp.net'; break }
                    'trafficmanager.net$' { $resourceProvider = 'trafficmanager.net'; break }
                }
                return $resourceProvider
            }
            
            # Function to add resource provider
            #
            Function Add-ResourceProvider {
                param
                (
                    $resourceList
                )
                
                $resourceList | ForEach-Object `
                {       
                    If (!$psitem.resourceProvider) {
                        $psitem | Add-Member -NotePropertyName "resourceProvider" -NotePropertyValue $(Get-ResourceProvider $psitem.FQDN) -Force
                    }
                }
            }

            # Function to retrive the Azure DNS records
            #
            Function Get-DnsCNameRecords {
                param
                (
                    $zone,
                    $interestedDnsZones
                )

                $cNameToDnsMap = [System.Collections.ArrayList]::new()
                                   
                $cNameRecords = Get-AzDnsRecordSet -ResourceGroupName $zone.ResourceGroup -ZoneName $zone.Name -RecordType CNAME
                                    
                Foreach ($item in $cNameRecords) {                    
                    foreach ($record in $item.records) {
                        If (![string]::IsNullOrEmpty($record) -and $record -match $interestedDnsZones) {                            
                            [void]$cNameToDnsMap.add([psCustomObject]@{'CName' = $item.Name; 'Fqdn' = $record.CName; 'ZoneName' = $zone.Name; 
                                    'ResourceGroup' = $zone.ResourceGroup; 'resourceProvider' = $(Get-ResourceProvider $record)
                                })
                        }
                    }
                }
                return $cNameToDnsMap
            }

            $dnszone = $using:wfDnsZone            
            $context = $using:wfContext
            $interestedDnsZones = $using:wfInterestedDnsZones            
            
            Select-AzContext -InputObject $context
            Get-DnsCNameRecords $dnsZone $interestedDnsZones
        }
    }
}

# Function to fetch Azure resource records
Function Get-AZResourcesListForWorkFlow {
    param
    (
        $query
    )

    # Function to retrive the Azure resources
    #
    Function Get-AZResources {
        param
        (    
            [int]$startId,
    
            [long]$endId,
    
            $query
        )
    
        If ($endId -gt 0) {
            $params = @{ 'First' = $startId; 'Skip' = $endId }
        }
        else {
            $params = @{ 'First' = $startId }
        }
        return $(Search-AzGraph -Query $query @params)    
    }
    $AzResourcesList = [System.Collections.ArrayList ]::new()
    
    $numberOfResources = (Search-AzGraph -Query $( -join ($query, ' |  summarize TotalResources=count()'))).TotalResources
    $maxRecords = 1000
    $skipRecords = 0
    Do {
        $AzResourcesList += Get-AzResources -startId $maxRecords -endId $skipRecords -query $query
        $skipRecords += $maxRecords
    
    }Until($numberOfResources -le $skipRecords)
    
    return $AzResourcesList
}

# For running the workflows in parellel by subscription
#
Function Run-BySubscription {
    param
    (
        $azSubscriptions,
        $dnszoneQuery,
        $inputDnsZoneNameRegexFilter,
        $inputInterestedDnsZones
    )

    #Get the Azure DNS Zones
    
    $dnsZones = Get-AzResourcesListForWorkFlow -query $dnszoneQuery

    $interestedZones = $dnsZones | Where-Object { $psitem.Name -match $inputDnsZoneNameRegexFilter }    

    $subsWithZones = ($interestedZones.subscriptionId | Group-Object).Name
    
    $wfNumberOfDnsZones = ($interestedZones | Group-Object type).count
   
    $wfNumberOfDnsRecordSets = 0

    Foreach ($item in $interestedZones) {
        $wfNumberOfDnsRecordSets += ($item.properties.numberOfRecordSets)
    }
    
    [pscustomObject]@{'Name' = 'ProcessSummaryData'; 'wfNumberOfDnsZones' = $wfNumberOfDnsZones; 'wfNumberOfDnsRecordSets' = $wfNumberOfDnsRecordSets } 

    Write-Warning "Please standby - processing $wfNumberOfDnsZones DnsZones and $wfNumberOfDnsRecordSets DnsRecordSets"
    
    $global:numberOfDnsZones += $wfNumberOfDnsZones
    
    $global:numberOfDnsRecordSets += $wfNumberOfDnsRecordSets            

    $i = 0
    $azSubscriptions | ForEach-Object `
    {
        $subscription = $PSItem        
        
        $status = $i / ($azSubscriptions|Measure-Object).count

        $ActivityMessage = "Building Azure CName records List"
        
        Write-Progress -Activity "$ActivityMessage" -Status "$($status.ToString('P')) Complete:" -PercentComplete ($status*100)

        #$interestedZones = $using:interestedZones
        #$inputInterestedDnsZones = $using:inputInterestedDnsZones

        Function Get-DnsRecordsWorkFlow {
            param
            (
                $wfdnsZones,        
                $wfcontext,
                $wfinterestedDnsZones
            )

            $wfdnsZones | ForEach-Object -Parallel {        
                $dnsZone = $PSItem
                $context = $using:wfcontext
                $interestedDnsZones = $using:wfinterestedDnsZones 
            
                $AZModules = ('Az.Accounts', 'Az.Dns')
                Foreach ($module in $AZModules) {
                    If (Get-Module -Name $module) {
                        continue
                    
                    }
                    elseif (Get-Module -ListAvailable -Name $module) {   
                        Import-Module -name $module -Scope Local -Force
                    }
                    else {
                        Install-module -name $module -AllowClobber -Force -Scope CurrentUser -SkipPublisherCheck
                        Import-Module -name $module -Scope Local -Force
                    }
            
                    If (!$(Get-Module -Name $module)) {                                        
                        Write-Error "Could not load dependant module: $module"
                        throw
                    }
                }

                #Function to return resource provider
                Function Get-ResourceProvider {
                    param
                    (
                        $recordName
                    )
                    switch -regex ($recordName) {
                        'azure-api.net$' { $resourceProvider = 'azure-api.net'; break }
                        'azurecontainer.io$' { $resourceProvider = 'azurecontainer.io'; break }
                        'azurefd.net$' { $resourceProvider = 'azurefd.net'; break }
                        'azureedge.net$' { $resourceProvider = 'azureedge.net'; break }
                        'azurewebsites.net$' { $resourceProvider = 'azurewebsites.net'; break }
                        'blob.core.windows.net$' { $resourceProvider = 'blob.core.windows.net'; break }
                        'cloudapp.azure.com$' { $resourceProvider = 'cloudapp.azure.com'; break }
                        'cloudapp.net$' { $resourceProvider = 'cloudapp.net'; break }
                        'trafficmanager.net$' { $resourceProvider = 'trafficmanager.net'; break }                    
                    }
                    return $resourceProvider
                }
            
                # Function to add resource provider
                #
                Function Add-ResourceProvider {
                    param
                    (
                        $resourceList
                    )
                
                    $resourceList | ForEach-Object `
                    {       
                        If (!$psitem.resourceProvider) {
                            $psitem | Add-Member -NotePropertyName "resourceProvider" -NotePropertyValue $(Get-ResourceProvider $psitem.Fqdn) -Force
                        }
                    }
                }

                # Function to retrive the Azure DNS records
                #
                Function Get-DnsCNameRecords {
                    param
                    (
                        $zone,
                        $interestedDnsZones
                    )

                    $CNameToDnsMap = [System.Collections.ArrayList]::new()
                    
                    $CNameRecords = Get-AzDnsRecordSet -ResourceGroupName $zone.ResourceGroup -ZoneName $zone.Name -RecordType CNAME
                                    
                    Foreach ($item in $cNameRecords) {                    
                        foreach ($record in $item.records) {
                            If (![string]::IsNullOrEmpty($record) -and $record -match $interestedDnsZones) {                            
                                [void]$cNameToDnsMap.add([psCustomObject]@{'CName' = $item.Name; 'Fqdn' = $record.CName; 'ZoneName' = $zone.Name;
                                        'ResourceGroup' = $zone.ResourceGroup; 'resourceProvider' = $(Get-ResourceProvider $record)
                                    })
                            }
                        }
                    }
                    return $cNameToDnsMap
                }           
                
                Select-AzContext -InputObject $context
                Get-DnsCNameRecords $dnsZone $interestedDnsZones            
            }
        }

        If ($subscription.subscriptionId -in $subsWithZones) {
            Select-AzSubscription -SubscriptionObject $subscription
            
            $azContext = Get-AzContext

            $interestedZones1 = $interestedZones | Where-Object { $psitem.subscriptionId -eq $subscription }

            Get-DnsRecordsWorkFlow -wfdnsZones $($interestedZones1) -wfcontext $azContext -wfinterestedDnsZones $interestedAzureDnsZones
        }
        $i++
    }
}


# Function to look up if CName list in Azure resource records
#
Function Process-CNameList {
    param
    (
        $cNameList,
        [string]$ActivityMessage
    )
    $i = 0
    foreach ($item in $cNameList) {
        $status = $i / ($cNameList |Measure-Object).Count
                
        Write-Progress -Activity "$ActivityMessage" -Status "$($status.ToString('P')) Complete:" -PercentComplete ($status*100)
          
        If ($item.FQDN) {
            $key = $item.Fqdn.trim(" ").TrimEnd('.').tolower()

            #Azurefd can have subdomains also which we cannot mark as dangled
            if ($item.FQDN -match "azurefd.net") {
                $count = (($AzResourcesHash.GetEnumerator() | Where { $item.FQDN -match  $_.key }) | Measure-Object).Count
                if ($count -gt 0) {
                    [void]$AzCNameMatchingResources.add($item)
                }
                else {
                    [void]$AzCNameMissingResources.add($Item)
                }

            }
            else {
            
                If ($AzResourcesHash.ContainsKey($key)) {
                    $item | Add-Member -NotePropertyName 'AzRecord' -NotePropertyValue $($AzResourcesHash[$key]) -Force
                    [void]$AzCNameMatchingResources.add($item)
                }
                else {
                    [void]$AzCNameMissingResources.add($Item)
                }
            }
        }
        $i++
    }
}



Function Get-DanglingDnsRecords {
    <# 
.SYNOPSIS 
    Generate dangling DNS records list from given CName list and using Azure resouce graphs

.DESCRIPTION 
   Prerequisites:
    - Azure subscription with read access to Azure Resource Graph
    - Azure PowerShell and Resource graph module
    - Need to run as administrator to be able install the required libraries
    – Runs in parallel mode only in PowerShell version 7 or higher, else script will run in serial mode

.PARAMETER  InputFileDNSRecords

    Input Csv/Json filename with (CName, FQDN mapping), default None

.PARAMETER FetchDnsRecordsFromAzureSubscription

    Switch to express the intent to query azure subscriptions, default off

.PARAMETER FileAndAzureSubscription

    Switch to express the intent to fetch DNS records from both input file and from Azure DNS records, default off

.PARAMETER InputSubscriptionIdRegexFilterForAzureDns

    Filter to constrain the scope of subscriptions for fetching the Azure DNS recordsets, default match all

.PARAMETER InputSubscriptionIdRegexFilterForAzureResourcesGraph

    Filter to constrain the scope of subscriptions for fetching the Azure resources from the Azure resource graph, default match all

.PARAMETER InputDnsZoneNameRegexFilter
    
    Filter to run the query against matching DNS zone names, default match all

.PARAMETER InputInterestedDnsZones OutputFileLocation

    Location of the output files produced; default current directory

.EXAMPLE
    To fetch DNS records from Azure subscription
   
    Get-DanglingDnsRecords -FetchDnsRecordsFromAzureSubscription

.EXAMPLE
    To fetch DNS records from Input file Csv/Json
   
    Get-DanglingDnsRecords -InputFileDnsRecords .\CNameToDNSMap.csv

    Headers CName, Fqdn    

       Csv file context example:
       
       CNAME,FQDN
       testwanperfdiag,testwanperfdiag.blob.core.windows.net

       Json file content example:

       [
         {
             "CNAME":  "testwanperfdiag",
             "FQDN":  "testwanperfdiag.blob.core.windows.net"
         }
       ]

.EXAMPLE
    To fetch DNS records from both input file and Azure subscription

    Get-DanglingDnsRecords -InputFileDnsRecords .\CNameToDNSMap.csv -FileAndAzureSubscription

.EXAMPLE
    To fetch DNS records from Azure subscription with subscription Id and DNS zone filters to reduce the scope of search.

    Get-DanglingDnsRecords -FetchDnsRecordsFromAzureSubscription -InputSubscriptionIdRegexFilterForAzureDns 533 -InputDnsZoneNameRegexFilter testdnszone-1.a     

.NOTES
    Copyright 2020 Microsoft Corp.
    Version 1.0.20200811
#>    
    [cmdletbinding(DefaultParameterSetName = 'Parameter Set 0')]
    param
    (   
        # To fetch the DNS records from both file and Azure subscription
        [parameter(Mandatory = $true, ParameterSetName = 'Parameter Set 4')]
        [switch] $FileAndAzureSubscription,

        # To fetch DNS records against Azure subscription
        #    
        [parameter(Mandatory = $true, ParameterSetName = 'Parameter Set 3')]
        [switch]$FetchDnsRecordsFromAzureSubscription,

        <#
        Name of csv/json file with CName to FQDN map file
        Headers CName, FQDN, ZoneName, ResourceGroup
        ZoneName, ResourceGroup - values for these headers are optional

           Csv file context example:
           
           CNAME,FQDN,Zone,ResourceGroup
           testwanperfdiag,testwanperfdiag.blob.core.windows.net,,

           Json file content example:

           [
             {
                 "CNAME":  "testwanperfdiag",
                 "FQDN":  "testwanperfdiag.blob.core.windows.net",
                 "Zone":  "",
                 "ResourceGroup":  ""
             }
           ]
    #>
        [parameter(Mandatory = $true, ParameterSetName = 'Parameter Set 2')]
        [parameter(Mandatory = $true, ParameterSetName = 'Parameter Set 4')]
        [string]$InputFileDnsRecords,

        # Azure DNS zone regex   
        [parameter(Mandatory = $false, ParameterSetName = 'Parameter Set 3')]
        [parameter(Mandatory = $false, ParameterSetName = 'Parameter Set 4')]
        [string]$InputDnsZoneNameRegexFilter,

        # Azure subscriptionId regex for Azure DNS queries
        [parameter(Mandatory = $false, ParameterSetName = 'Parameter Set 3')]
        [parameter(Mandatory = $false, ParameterSetName = 'Parameter Set 4')]
        [string]$InputSubscriptionIdRegexFilterForAzureDns,

        # Azure subscriptionId regex for Azure resource graphs
        [parameter(Mandatory = $false, ParameterSetName = 'Parameter Set 2')]
        [parameter(Mandatory = $false, ParameterSetName = 'Parameter Set 3')]
        [parameter(Mandatory = $false, ParameterSetName = 'Parameter Set 4')]
        [string]$InputSubscriptionIdRegexFilterForAzureResourcesGraph,

        # Location of output Files
        [parameter(Mandatory = $false, ParameterSetName = 'Parameter Set 2')]
        [parameter(Mandatory = $false, ParameterSetName = 'Parameter Set 3')]
        [parameter(Mandatory = $false, ParameterSetName = 'Parameter Set 4')]
        $OutputFileLocation = "$pwd"
    )

    # If no params are provider just print help
    #
    If ( $PSBoundParameters.Values.Count -eq 0 -and $args.count -eq 0 ) {
        Get-Help $MyInvocation.MyCommand
        return 
    }

    $ErrorActionPreference = "Stop"

    $scriptStartTime = Get-Date
    # Input param set customization
    If ($FileAndAzureSubscription) {
        $FetchDnsRecordsFromAzureSubscription = $true
    }

    # List of interested Azure DNS zone suffixes delimited by "|"
    $interestedAzureDnsZones = "azurefd.net|blob.core.windows.net|azureedge.net|cloudapp.azure.com|trafficmanager.net|azurecontainer.io|azure-api.net|azurewebsites.net|cloudapp.net"

    # Run in serial or parallel by subscription
    [switch]$runParallel = $true

    #outPutFiles
    #
    [string]$outputResourcesFile = "$outputFileLocation\AzureResources.csv"
    [string]$outputCNameMissingAzResourcesFile = "$outputFileLocation\AzureCNameMissingResources.csv"
    [string]$outputCNameMatchedAzResourcesFile = "$outputFileLocation\AzureCNameMatchingResources.csv"
    [string]$outputAzCNameRecordsFile = "$outputFileLocation\AzureDnsCNameRecordSets.csv"
    [int64]$numberOfAzResources = 0
    [int64]$global:numberOfDnsZones = 0
    [int64]$global:numberOfDnsRecordSets = 0

    #List of resource providers
    $resourceProviderList = @(
        [pscustomObject]@{'Service' = 'Azure API Management'; 'DomainSuffix' = 'azure-api.net' },
        [pscustomObject]@{'Service' = 'Azure Container Instance'; 'DomainSuffix' = 'azurecontainer.io' },
        [pscustomObject]@{'Service' = 'Azure CDN'; 'DomainSuffix' = 'azureedge.net' },
        [pscustomObject]@{'Service' = 'Azure Front Door'; 'DomainSuffix' = 'azurefd.net' },
        [pscustomObject]@{'Service' = 'Azure App Service'; 'DomainSuffix' = 'azurewebsites.net' },
        [pscustomObject]@{'Service' = 'Azure Blob Storage'; 'DomainSuffix' = 'blob.core.windows.net' },
        [pscustomObject]@{'Service' = 'Azure Public IP addresses'; 'DomainSuffix' = 'cloudapp.azure.com' },
        [pscustomObject]@{'Service' = 'Azure Classic Cloud'; 'DomainSuffix' = 'cloudapp.net' },
        [pscustomObject]@{'Service' = 'Azure Traffic Manager'; 'DomainSuffix' = 'trafficmanager.net' }
    )

    #Input processing
    #
    $inputFileProcessingStart = Get-Date
    If ($InputFileDnsRecords) {
        If (!$(Test-path $InputFileDnsRecords)) {
            Write-Error "File missing : $InputFileDnsRecords"
            throw
        }

        switch -regex ($InputFileDnsRecords) {
            ".csv$" {
                $inputCNameList = Import-Csv $((Get-Item $InputFileDnsRecords).FullName) -Header CName, Fqdn |
                Where-Object { $psitem.FQDN -match $interestedAzureDnsZones }
                break
            }

            ".json$" {
                $inputCNameList = Get-Content $((Get-Item $InputFileDnsRecords).FullName) | ConvertFrom-Json |
                Where-Object { $psitem.FQDN -match $interestedAzureDnsZones }
            
                # add additional properties, if input object does not contain it
                $inputCNameList | ForEach-Object `
                {
                    if (!$psitem.zoneName) {
                        $psitem | Add-Member -NotePropertyName "ZoneName" -NotePropertyValue $null -Force
                    }
                    if (!$psitem.ResourceGroup) {  
                        $psitem | Add-Member -NotePropertyName "ResourceGroup" -NotePropertyValue $null -Force 
                    }
                }
                break
            }
        }

        if ($null -eq $inputCNameList) {
            Write-Warning "No Records found in input file, please check the file.."
            return
        }
        else {
            Add-ResourceProvider $inputCNameList
        }
    }
    $inputFileProcessingTime = Get-TimeToProcess $inputFileProcessingStart

    #Check if the PowerShell version and script are compatable, Workflow is not supported in PS version 6+
    #
    If ($PSVersionTable.PSEdition -ne "Core" -or $PSVersionTable.PSVersion.Major -lt 7) {
        $runParallel = $false
        $workflowUnsupported = $true
        Write-Warning "Run parallel is unsupported in the current version of powershell: $($PSVersionTable.PSVersion), running in serial mode"
    }

    #Load or install libraries
    #
    $AZModules = @('Az.Accounts', 'Az.Dns', 'Az.ResourceGraph')
    $AzLibrariesLoadStart = Get-Date
    $progressItr = 1; 
    $ProgessActivity = "Loading required Modules";
    $StoreWarningPrefernce = $WarningPreference
    $WarningPreference = 'SilentlyContinue'
    Foreach ($module in $AZModules) {
        $progressValue = $progressItr / $AZModules.Length

        Write-Progress -Activity $ProgessActivity -Status "$module $($progressValue.ToString('P')) Complete:" -PercentComplete ($progressValue*100)
    

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
    $WarningPreference = $StoreWarningPrefernce
    Write-Progress -Activity $ProgessActivity -Completed
    $AzLibrariesLoadTime = Get-TimeToProcess $AzLibrariesLoadStart

    #Initialize
    #
    $AZAccountConnectStart = Get-Date
    try {
        Get-AzTenant  -ErrorAction Stop
    }
    catch {
        Write-warning "AzAccount not connected trying to connect to AzAccount"
        $connectionDoneFromScript = $true
        Connect-AzAccount
    }

    $AZAccountConnectTime = Get-TimeToProcess $AZAccountConnectStart

    $interestedResourcesQuery = "
    resources
    | where subscriptionId matches regex '(?i)$InputSubscriptionIdRegexFilterForAzureResourcesGraph'
    | where type in ('microsoft.network/frontdoors',
    'microsoft.storage/storageaccounts',
    'microsoft.cdn/profiles/endpoints',
    'microsoft.cdn/profiles/afdendpoints',
    'microsoft.network/publicipaddresses',
    'microsoft.network/trafficmanagerprofiles',
    'microsoft.containerinstance/containergroups',
    'microsoft.apimanagement/service',
    'microsoft.web/sites',
    'microsoft.web/sites/slots',
    'microsoft.classiccompute/domainnames',    
    'microsoft.classicstorage/storageaccounts')
    |mvexpand properties.hostnameConfigurations    
    | extend dnsEndpoint = case
    (
       type =~ 'microsoft.network/frontdoors', properties.cName,
       type =~ 'microsoft.storage/storageaccounts', iff(properties['primaryEndpoints']['blob'] matches regex '(?i)(http|https)://',
                parse_url(tostring(properties['primaryEndpoints']['blob'])).Host, tostring(properties['primaryEndpoints']['blob'])),
       type =~ 'microsoft.cdn/profiles/endpoints', properties.hostName,
       type =~ 'microsoft.cdn/profiles/afdendpoints', properties.hostName,
       type =~ 'microsoft.network/publicipaddresses', properties.dnsSettings.fqdn,
       type =~ 'microsoft.network/trafficmanagerprofiles', properties.dnsConfig.fqdn,
       type =~ 'microsoft.containerinstance/containergroups', properties.ipAddress.fqdn,
       type =~ 'microsoft.apimanagement/service', properties_hostnameConfigurations.hostName,
       type =~ 'microsoft.web/sites', properties.defaultHostName,
       type =~ 'microsoft.web/sites/slots', properties.defaultHostName,
       type =~ 'microsoft.classiccompute/domainnames',properties.hostName,
       ''
    )
    | extend dnsEndpoints = case
    (
        type =~ 'microsoft.apimanagement/service', 
           pack_array(dnsEndpoint, 
            parse_url(tostring(properties.gatewayRegionalUrl)).Host,
            parse_url(tostring(properties.developerPortalUrl)).Host, 
            parse_url(tostring(properties.managementApiUrl)).Host,
            parse_url(tostring(properties.portalUrl)).Host,
            parse_url(tostring(properties.scmUrl)).Host,
            parse_url(tostring(properties.gatewayUrl)).Host),
        type =~ 'microsoft.web/sites', properties.hostNames,
       	type =~ 'microsoft.web/sites/slots', properties.hostNames,
        type =~ 'microsoft.classicstorage/storageaccounts', properties.endpoints,
        pack_array(dnsEndpoint)
    )
    | where isnotempty(dnsEndpoint)
    | extend resourceProvider = case
    (
        dnsEndpoint endswith 'azure-api.net', 'azure-api.net',
        dnsEndpoint endswith 'azurecontainer.io', 'azurecontainer.io',
        dnsEndpoint endswith 'azureedge.net', 'azureedge.net',
        dnsEndpoint endswith 'azurefd.net', 'azurefd.net',
        dnsEndpoint endswith 'azurewebsites.net', 'azurewebsites.net',
        dnsEndpoint endswith 'blob.core.windows.net', 'blob.core.windows.net', 
        dnsEndpoint endswith 'cloudapp.azure.com', 'cloudapp.azure.com',
        dnsEndpoint endswith 'cloudapp.net', 'cloudapp.net',
        dnsEndpoint endswith 'trafficmanager.net', 'trafficmanager.net',
        '' 
    )
    | project id, tenantId, subscriptionId, type, resourceGroup, name, dnsEndpoint, dnsEndpoints, properties, resourceProvider
    | order by dnsEndpoint asc, name asc, id asc"

    $inputDnsZoneNameRegexFilterForSearch =   $inputDnsZoneNameRegexFilter.replace('\','\\')
    $InputSubscriptionIdRegexFilterForAzureResourcesGraphSearch = $InputSubscriptionIdRegexFilterForAzureResourcesGraph.replace('\','\\')
    $dnszoneQuery = ("resources | where type =~ 'microsoft.network/dnszones'" +
             " | where subscriptionId matches regex '(?i)$InputSubscriptionIdRegexFilterForAzureResourcesGraphSearch'"+
             " | where name matches regex '(?i)$inputDnsZoneNameRegexFilterForSearch'")

    # Main
    #
    $AzResourcesFetchStart = Get-Date

    # Confirm if DNS record exists in Azure resources
    #
    $AzCNameMissingResources = [System.Collections.ArrayList]::new()

    $AzCNameMatchingResources = [System.Collections.ArrayList]::new()

    $AzResourcesHash = Get-AzResourcesHash -query $interestedResourcesQuery -keyName 'dnsEndPoint'

    $numberOfAzResources = $AzResourcesHash.keys.count

    $AzResourcesFetchTime = Get-TimeToProcess $AzResourcesFetchStart

    Write-Host "Fetched $numberOfAzResources Azure resources: Total time took in milliseconds: $AzResourcesFetchTime" -ForegroundColor Yellow

    #
    $AZDnsRecordsFetchStart = Get-Date
    If ($FetchDnsRecordsFromAzureSubscription) {   
        #Build the Azure DNS interested CName records
        #   
        $azSubscriptionsForDns = Get-AzSubscription | Where-Object { $psitem.Id -match $InputSubscriptionIdRegexFilterForAzureDns }

        $numberOfSubscriptionsForDns += $azSubscriptionsForDns.Count
    
        Write-Warning "Please standby - processing $numberOfSubscriptionsForDns subscriptions"

        $AzDnsCNameRecordSets = [System.Collections.ArrayList]::new()

        If ($azSubscriptionsForDns -and $runParallel) {         
            $CNameToDnsMapList = Run-BySubscription $azSubscriptionsForDns $dnszoneQuery $inputDnsZoneNameRegexFilter $interestedAzureDnsZones
        
            $AzDnsCNameRecordSets += $CNameToDnsMapList | Where-Object { $psitem.Fqdn } | Sort-Object -Unique CName, Fqdn, ZoneName, ResourceGroup

        }
        elseif ($azSubscriptionsForDns) {
    
            $workflowscriptPath = (Join-Path $PSScriptRoot WorkflowFunctions.ps1)
            if (Test-path -Path $workflowscriptPath) {
    
                . (Join-Path $PSScriptRoot WorkflowFunctions.ps1)


                $CNameToDnsMapList = Run-BySubscriptionWorkflow $azSubscriptionsForDns $dnsZoneQuery $inputDnsZoneNameRegexFilter $interestedAzureDnsZones $InputSubscriptionIdRegexFilterForAzureDns
                $processSummary = $CNameToDnsMapList | Where-Object { $psitem -match 'ProcessSummaryData' }
                $numberOfDnsZones += $processSummary.wfNumberOfDnsZones
                $numberOfDnsRecordSets += $processSummary.wfNumberOfDnsRecordSets
        
                Write-Warning "Please standby - processing $numberOfDnsZones DnsZones and $numberOfDnsRecordSets DnsRecordSets"

                $AzDnsCNameRecordSets += $CNameToDnsMapList | Where-Object { $psitem.FQDN } | Sort-Object -Unique CName, Fqdn, ZoneName, ResourceGroup

            }
            else {



                #Get the Azure DNS Zones
        
                $dnsZones = Get-AZResourcesList -query $dnszoneQuery
        
                $interestedZones = $dnsZones | Where-Object { $psitem.Name -match $inputDnsZoneNameRegexFilter }
        
                $subsWithZones = ($interestedZones.subscriptionId | Group-Object).Name
        
                $numberOfDnsZonesCount = ($interestedZones | Group-Object type).count
        
                $global:numberOfDnsZones += $numberOfDnsZonesCount

                Foreach ($item in $interestedZones) {
                    $numberOfDnsRecordS += $item.properties.numberOfRecordSets    
                }
                $global:numberOfDnsRecordSets += $numberOfDnsRecordS
        
                Write-Warning "Please standby - processing $numberOfDnsZonesCount DnsZones and $numberOfDnsRecordS DnsRecordSets"

                $azSubscriptionsForDns | 
                ForEach-Object `
                {
                    $subscription = $psitem

                    If ($interestedZones) {
                        Select-AzSubscription -SubscriptionObject $subscription | Out-Null
                        $azContext = Get-AzContext

                        $interestedZones1 = $interestedZones | Where-Object { $psitem.subscriptionId -eq $subscription }

                        If ($interestedZones1 -and $subscription.subscriptionId -in $subsWithZones) {
                            $cNameRecords = Get-AzCNameToDnsMap $interestedZones1
                    
                            $i = 0
                            foreach ($record in $cNameRecords) {
                                $status = $($i / ($cNameRecords | Measure-Object).Count) * 100
                                $ActivityMessage = "Building Azure CName records List"
                        
                                Write-Progress -Activity "$ActivityMessage" -Status "$status Complete:" -PercentComplete $status

                                $record | Add-Member -NotePropertyName 'subscriptionName' -NotePropertyValue $psitem.Name -Force
                                $record | Add-Member -NotePropertyName 'subscriptionId' -NotePropertyValue $psitem.Id -Force
                                [void]$AzDnsCNameRecordSets.add($record)
                                $i++
                            }
                        }
                    }
                }    
            }
        }
        $AzDnsRecordsFetchTime = Get-TimeToProcess $AzDnsRecordsFetchStart
        Write-Host "Completed Azure DNS records fetch workflows: Total time took in milliseconds: $AzDnsRecordsFetchTime" -ForegroundColor Yellow
    }

    # Process input CName list from csv/json 
    #
    $inputCNameListStart = Get-Date

    Process-CNameList $inputCNameList "Processing input CName List"

    $inputCNameListProcessingTime = Get-TimeToProcess $inputCNameListStart

    # Process CName list from Azure DNS records
    #
    $AzDnsRecordSetsStart = Get-Date

    Process-CNameList $AzDnsCNameRecordSets "Processing Azure CName List"

    $AzDnsRecordSetProcessingTime = Get-TimeToProcess $AzDnsRecordSetsStart

    # write result to screen and files
    #
    If ($AzCNameMissingResources.count -gt 0) {
        If ($AzCNameMissingResources.count -lt 20) {
            Write-Warning "Following CName records missing in Azure resources"
            $AzCNameMissingResources | Format-Table
        }
        $AzCNameMissingResources | Export-Csv $outputCNameMissingAzResourcesFile -NoTypeInformation -Force
        Write-Host "Found $($AzCNameMissingResources.count) CName records missing Azure resources; saved the file as: $outputCNameMissingAzResourcesFile" -ForegroundColor Red
    }
    else {
        Write-Host "No CName records missing Azure DNS records found" -ForegroundColor Green
    }

    If ($AzResourcesHash.count -gt 0) {
        $AzResourcesList = $AzResourcesHash.Values.toarray()

        $AzResourcesList | Export-Csv $outputResourcesFile -NoTypeInformation -Force
        Write-Host "Fetched $($AzResourcesHash.values.count) Azure resources; Saved the file as: $outputResourcesFile" -ForegroundColor Green
    }
    else {
        Write-Warning "No Azure resource records fetched"
    }


    If ($AzDnsCNameRecordSets.count -gt 0) {
        $AzDnsCNameRecordSets | Export-Csv $outputAzCNameRecordsFile -NoTypeInformation -Force
        Write-Host "Fetched $($AzDnsCNameRecordSets.count) Azure CName records; Saved the file as: $outputAzCNameRecordsFile" -ForegroundColor Green

    }
    elseif ($FetchDnsRecordsFromAzureSubscription) {
        Write-Warning "No Azure DNS CName records fetched"
    }

    If ($inputCNameList.count -gt 0) {
        Write-Host "Processed $($inputCNameList.count) CName records from input file: $InputFileDnsRecords" -ForegroundColor Green
    }

    If ($AzCNameMatchingResources.count -gt 0) {
        $AzCNameMatchingResources | Export-Csv $outputCNameMatchedAzResourcesFile -NoTypeInformation -Force
        Write-Host "Found $($AzCNameMatchingResources.count) CName records matching in Azure resources;  saved the file as: $outputCNameMatchedAzResourcesFile" -ForegroundColor Green
    }

    $summaryStart = Get-Date

    $summaryResourceList = [system.collections.ArrayList]::new()

    $CNameMatchingAzRecordsSummary = $AzCNameMatchingResources | Group-Object  resourceProvider | Select-Object Name, Count
    $CNameMissingAzRecordsSummary = $AzCNameMissingResources | Group-Object  resourceProvider | Select-Object Name, Count
    $resourceGroupSummary = $AzResourcesList | Group-Object  resourceProvider | Select-Object Name, Count

    $resourceProviderList | ForEach-Object `
    {
        $resource = $psitem
        $item = [psCustomObject] @{
            'AzureResourceProviderName'   = $resource.Service
            'AzureResourceCount'          = ($resourceGroupSummary | Where-Object { $psitem.Name -eq $resource.DomainSuffix }).count
            'AzureCNameMatchingResources' = ($CNameMatchingAzRecordsSummary | Where-Object { $psitem.Name -eq $resource.DomainSuffix }).count
            'AzureCNameMissingResources'  = ($CNameMissingAzRecordsSummary | Where-Object { $psitem.Name -eq $resource.DomainSuffix }).count
        }
        [void] $summaryResourceList.add($item)
    }
    $summaryTime = Get-TimeToProcess $summaryStart

    #Disconnecte Azure account
    #
    if ($connectionDoneFromScript -eq $true) {
        Disconnect-AzAccount | Out-Null
        $connectionDoneFromScript = $false
    }

    #Write Summary:
    #
    If ($runParallel) {
        $processType = "Parallel"
    }
    else {
        $processType = "Serial"
    }
    $scriptTime = Get-TimeToProcess $scriptStartTime

    [pscustomObject] @{
        'NameOfProcessSection'            = "Time in Milliseconds"
        'InputFileProcessingTime'         = $inputFileProcessingTime
        'AzureLibrariesLoadTime'          = $inputCNameListProcessingTime
        'AzureResourcesFetchTime'         = $AzResourcesFetchTime
        'AzureDnsRecordsFetchTime'        = $AzDnsRecordsFetchTime
        'InputDnsCNameListProcessingTime' = $inputCNameListProcessingTime
        'AzureCNameListProcessingTime'    = $AzDnsRecordSetProcessingTime
        'SummarizeTime'                   = $summaryTime
        'ScriptExectionTime'              = $scriptTime
    }

    [pscustomObject] @{
        'TypeOfRecords'               = "Details"
        'ProcessedType'               = $processType
        'AzureSubscriptions'          = $numberOfSubscriptionsForDns
        'AzureResources'              = $numberOfAzResources
        'AzureDnsZones'               = $numberOfDnsZones
        'AzureDnsRecordSets'          = $numberOfDnsRecordSets
        'InputDnsCNameList'           = $inputCNameList.count
        'AzureDnsCNameRecordSets'     = $AzDnsCNameRecordSets.count
        'AzureCNameMatchingResources' = $AzCNameMatchingResources.count
        'AzureCNameMissingResources'  = $AzCNameMissingResources.Count    
    }

    $summaryResourceList | Format-Table
}

Export-ModuleMember -Function  Get-DanglingDnsRecords
