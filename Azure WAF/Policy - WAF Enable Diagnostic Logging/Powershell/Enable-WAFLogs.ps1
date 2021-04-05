# Manually Set Variables

$workspace = "YourWorkspace"
$workspaceRG = "YourRG"

# Prepare Modules

Write-Verbose "Checking for Azure module..."
$AzModule = Get-Module -Name "Az.*" -ListAvailable
if ($AzModule -eq $null) {
    Write-Verbose "Azure PowerShell module not found"
    # Check for Admin Privileges
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isadmin = ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    if($isadmin -eq $False){
        # No Admin, install to current user
        Write-Warning -Message "Can not install Az Module.  You are not running as Administrator"
        Write-Warning -Message "Installing Az Module to Current User Scope"
        Install-Module Az -Scope CurrentUser -Force
        Install-Module Az.Security -Scope CurrentUser -Force
    }
    Else{
        # Admin, install to all users
        Install-Module Az -Force
        Install-Module Az.Security -Force
    }
else {
    if ($AzModule.Name -notcontains "Az.FrontDoor") {
    Write-Verbose "Azure FrontDoor PowerShell module not found"
        if($isadmin -eq $False){
        Write-Warning -Message "Can not install Az FrontDoor Module.  You are not running as Administrator"
        Write-Warning -Message "Installing Az FrontDoor Module to Current User Scope"
        Install-Module Az.FrontDoor -Scope CurrentUser -Force

    }
        Else{
        # Admin, install to all users
        Install-Module Az.FrontDoor -Force
    }
}
}
}

# Check/Set Execution Policy
if ((Get-ExecutionPolicy).value__ -eq '3') {
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
}

# Import Modules
Import-Module Az
Import-Module Az.FrontDoor

# Login to Azure
Login-AzAccount

# Get All Subs
$Subscriptions = Get-AzSubscription

# Create Diagnostic Settings

$wsid = (Get-AzOperationalInsightsWorkspace -Name $workspace -ResourceGroupName $workspaceRG).ResourceId

foreach ($Subscription in $Subscriptions) {

    Select-AzSubscription -Subscription $Subscription

    $agws = Get-AzApplicationGateway | Where-Object ($_.WebApplicationFirewallConfiguration.Enabled -eq $true)

    foreach ($agw in $agws){

        $agwname = $agw.Name

        if ($agw.WebApplicationFirewallConfiguration.Enabled -eq $true){

            Set-AzDiagnosticSetting -Name "${agwname}-Diag" -ResourceId $agw.Id -WorkspaceId $wsid -Category ApplicationGatewayAccessLog,ApplicationGatewayPerformanceLog,ApplicationGatewayFirewallLog -MetricCategory AllMetrics -Enabled $true -RetentionEnabled $False -RetentionInDays 0 -ErrorAction SilentlyContinue
        
        }
    }

    $fds = Get-AzFrontDoor

    foreach ($fd in $fds){

        $fdname = $fd.Name

        if ($fd.FrontendEndpoints.WebApplicationFirewallPolicyLink -ne $null){

            Set-AzDiagnosticSetting -Name "${fdname}-Diag" -ResourceId $fd.Id -WorkspaceId $wsid -Category FrontdoorAccessLog,FrontdoorWebApplicationFirewallLog -MetricCategory AllMetrics -Enabled $true -RetentionEnabled $False -RetentionInDays 0 -ErrorAction SilentlyContinue
        
        }
    }

}




