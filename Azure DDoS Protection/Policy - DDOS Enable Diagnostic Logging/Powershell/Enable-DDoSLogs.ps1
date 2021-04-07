# Set Variables

$workspace = "cybersecuritydemo"
$workspaceRG = "SOC"

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
    }
    Else{
        # Admin, install to all users
        Install-Module Az -Force
    }

}

# Check/Set Execution Policy
if ((Get-ExecutionPolicy).value__ -eq '3') {
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
}

# Import Modules
Import-Module Az

# Login to Azure
Login-AzAccount

# Get All Subs
$Subscriptions = Get-AzSubscription 

# Create Diag Settings

$wsid = (Get-AzOperationalInsightsWorkspace -Name $workspace -ResourceGroupName $workspaceRG).ResourceId

foreach ($Subscription in $Subscriptions) {

    Select-AzSubscription -Subscription $Subscription

    $pips = Get-AzPublicIpAddress -Name ContosoVM1-ip

    foreach ($pip in $pips) {

        $pipname = $pip.Name

        Set-AzDiagnosticSetting -Name "${pipname}-Diag" -ResourceId $pip.Id -WorkspaceId $wsid -Category DDoSProtectionNotifications,DDoSMitigationFlowLogs,DDoSMitigationReports -MetricCategory AllMetrics -Enabled $true -RetentionEnabled $False -RetentionInDays 0 -ErrorAction SilentlyContinue

    }

}













