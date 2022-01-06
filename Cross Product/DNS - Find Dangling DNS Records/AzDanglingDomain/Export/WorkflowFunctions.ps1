# Workflow to fetch Azure resource records
Function Get-AZResourcesListForWorkFlow
{
    param
    (
        $query
    )

    # Function to retrive the Azure resources
    #
    Function Get-AZResources
    {
        param
        (    
            [int]$startId,
    
            [long]$endId,
    
            $query
        )
    
        If($endId -gt 0)
        {
            $params = @{ 'First' = $startId; 'Skip' = $endId }
        }else
        {
            $params = @{ 'First' = $startId }
        }
        return $(Search-AzGraph -Query $query @params)    
    }
    $AzResourcesList = [System.Collections.ArrayList ]::new()
    
    $AzResourcesList = Search-AzGraph -Query $( -join ($query, ' |  summarize TotalResources=count()'))
    if(($null -ne $AzResourcesList) -and   ($null -ne $AzResourcesList.Data))
    {
            $AzResourcesList = $AzResourcesList.Data
    }
    $numberOfResources =  $AzResourcesList.TotalResources
    $maxRecords = 1000
    $skipRecords = 0
    Do
    {
        $AzResourcesList += Get-AzResources -startId $maxRecords -endId $skipRecords -query $query
        if(($null -ne $AzResourcesList) -and   ($null -ne $AzResourcesList.Data))
        {
                $AzResourcesList = $AzResourcesList.Data
        }
        $skipRecords += $maxRecords
    
    }Until($numberOfResources -le $skipRecords)
    
    return $AzResourcesList
}

# For running the workflows in parellel by subscription
#
Function Run-BySubscriptionWorkflow
{
    param
    (
        $azSubscriptions,
        $dnsZoneQuery,
        $inputDnsZoneNameRegexFilter,
        $interestedAzureDnsZones,
        $InputSubscriptionIdRegexFilterForAzureDns
    )

    #Get the Azure DNS Zones
    
    $dnsZones = Get-AzResourcesListForWorkFlow -query $dnsZoneQuery

    $interestedZones = $dnsZones| Where-Object { $psitem.Name -match $inputDnsZoneNameRegexFilter -and $psitem.SubscriptionId -match $InputSubscriptionIdRegexFilterForAzureDns}    

    $subsWithZones = ($interestedZones.subscriptionId | Group-Object).Name
    
    $wfNumberOfDnsZones = ($interestedZones | Group-Object type).count

    $wfNumberOfDnsRecordSets = 0

    Foreach($item in $interestedZones)
    {
        $wfNumberOfDnsRecordSets += ($item.Properties.NumberOfRecordSets)
    }
    
    [pscustomObject]@{'Name' = 'ProcessSummaryData'; 'wfNumberOfDnsZones' = $wfNumberOfDnsZones; 'wfNumberOfDnsRecordSets' = $wfNumberOfDnsRecordSets } 

    Foreach ($subscription in $azSubscriptions)
    {

        If($subscription.subscriptionId -in $subsWithZones)
        {
            Select-AzSubscription -SubscriptionObject $subscription
            
            $azContext = Get-AzContext

            $interestedZones1 = $interestedZones | Where-Object{$psitem.subscriptionId -eq $subscription.subscriptionId}

            Get-DnsRecordsWorkFlow -wfDnsZones $($interestedZones1) -wfContext $azContext -wfInterestedDnsZones $interestedAzureDnsZones -wfSubscription $subscription
        }
    }
}

# For running the workflows in parellel by for each DNS zone
#
workflow Get-DnsRecordsWorkFlow
{
    param
    (
        $wfDnsZones,        
        $wfContext,
        $wfInterestedDnsZones,
        $wfSubscription
    )

    Foreach -parallel ($wfDnsZone in $wfDnsZones)
    {
        inlinescript
        {
          
            $AZModules = ('Az.Accounts', 'Az.Dns')
            Foreach($module in $AZModules)
            {
                If(Get-Module -Name $module)
                {
                    continue
                }elseif(Get-Module -ListAvailable -Name $module)
                {
                    Import-Module -name $module -Scope Local -Force
                }else
                {
                    Install-module -name $module -AllowClobber -Force -Scope CurrentUser -SkipPublisherCheck
                    Import-Module -name $module -Scope Local -Force
                }
            
                If(!$(Get-Module -Name $module))
                {
                    Write-Error "Could not load dependant module: $module"
                    throw
                }
            }

            #Function to return resource provider
            Function Get-ResourceProvider
            {
                param
                (
                    $resourceName
                )
                switch -regex ($resourceName)
                {
                    'azure-api.net$' { $resourceProvider = 'azure-api.net'; break}
                    'azurecontainer.io$' { $resourceProvider = 'azurecontainer.io'; break}
                    'azurefd.net$' { $resourceProvider = 'azurefd.net'; break}
                    'azureedge.net$' { $resourceProvider = 'azureedge.net'; break}
                    'azurewebsites.net$' { $resourceProvider = 'azurewebsites.net'; break}
                    'blob.core.windows.net$' { $resourceProvider = 'blob.core.windows.net'; break}
                    'cloudapp.azure.com$' { $resourceProvider = 'cloudapp.azure.com'; break}
                    'cloudapp.net$' { $resourceProvider = 'cloudapp.net'; break}
                    'trafficmanager.net$' { $resourceProvider = 'trafficmanager.net'; break}
                }
                return $resourceProvider
            }
            
            # Function to add resource provider
            #
            Function Add-ResourceProvider
            {
                param
                (
                    $resourceList
                )
                
                $resourceList | ForEach-Object `
                {       
                    If(!$psitem.resourceProvider)
                    {
                        $psitem | Add-Member -NotePropertyName "resourceProvider" -NotePropertyValue $(Get-ResourceProvider $psitem.Fqdn) -Force
                    }
                }
            }

            # Function to retrive the Azure DNS records
            #
            Function Get-DnsCNameRecords
            {
                param
                (
                    $zone,
                    $interestedDnsZones
                )

                $cNameToDnsMap = [System.Collections.ArrayList]::new()
                    
                $cNameRecords = Get-AzDnsRecordSet -ResourceGroupName $zone.ResourceGroup -ZoneName $zone.Name -RecordType CNAME
                                    
                Foreach($item in $cNameRecords)
                {                    
                    foreach($record in $item.records)
                    {
                        If(![string]::IsNullOrEmpty($record) -and $record -match $interestedDnsZones)
                        {                            
                            [void]$cNameToDnsMap.add([psCustomObject]@{'CName' = $item.Name; 'Fqdn' = $record.CName; 'ZoneName' = $zone.Name; 
                                                    'ResourceGroup' = $zone.ResourceGroup; 'resourceProvider' = $(Get-ResourceProvider $record)})
                        }
                    }
                }
                return $cNameToDnsMap
            }

            $dnszone = $using:wfDnsZone            
            $context = $using:wfContext
            $interestedDnsZones = $using:wfInterestedDnsZones            
            $subscription = $using:wfSubscription

            Select-AzSubscription -SubscriptionObject $subscription

            Select-AzContext -InputObject $context
                        
            Get-DnsCNameRecords $dnsZone $interestedDnsZones
        }
    }
}