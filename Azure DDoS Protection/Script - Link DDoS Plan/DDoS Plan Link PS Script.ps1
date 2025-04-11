# Variables

$resourceGroupName = "YourResourceGroupName"

$ddosProtectionPlanName = "YourDdosProtectionPlanName"

$publicIpNames = @("PublicIP1", "PublicIP2", "PublicIP3") # Add your public IP names here

 

# Get the DDoS protection plan

$ddosProtectionPlan = Get-AzDdosProtectionPlan -ResourceGroupName $resourceGroupName -Name $ddosProtectionPlanName

 

# Loop through each public IP and enable DDoS protection

foreach ($publicIpName in $publicIpNames) {

    # Get the public IP address

    $publicIp = Get-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $resourceGroupName

 

    # Check if the public IP is Standard SKU

    if ($publicIp.Sku.Name -ne "Standard") {

        Write-Output "Skipping ${publicIpName}: DDoS protection is only supported on Standard SKU public IPs."

        continue

    }

 

    # Enable DDoS protection and associate with the DDoS protection plan

    $publicIp.DdosSettings = @{

        ProtectionMode = "Enabled"

        DdosProtectionPlan = @{

            Id = $ddosProtectionPlan.Id

        }

    }

 

    # Update the public IP address

    Set-AzPublicIpAddress -PublicIpAddress $publicIp

 

    Write-Output "DDoS protection enabled for ${publicIpName} and associated with DDoS protection plan ${ddosProtectionPlanName}."

}