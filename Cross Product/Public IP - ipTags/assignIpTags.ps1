Connect-AzAccount -Identity

# Create the ipTag once
$ipTag = New-AzPublicIpTag -IpTagType "FirstPartyUsage" -Tag "/NonProd"

# Get all resource groups in the subscription
$resourceGroups = Get-AzResourceGroup

foreach ($rg in $resourceGroups) {
    Write-Output "Scanning resource group: $($rg.ResourceGroupName)"

    # Get all public IP addresses in the resource group
    $publicIps = Get-AzPublicIpAddress -ResourceGroupName $rg.ResourceGroupName

    foreach ($publicIp in $publicIps) {
        Write-Output "Processing Public IP: $($publicIp.Name)"

        # Assign the ipTag to the public IP
        $publicIp.IpTags = $ipTag

        # Update the public IP address
        Set-AzPublicIpAddress -PublicIpAddress $publicIp | Out-Null

        Write-Output "Updated IP Tags for: $($publicIp.Name)"
    }
}
