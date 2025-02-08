# Install IIS and required management tools
Install-WindowsFeature -name Web-Server, Web-Mgmt-Tools -IncludeManagementTools
# Create the HTML content for the default website
$hostname = (Get-WmiObject -Class Win32_ComputerSystem).Name
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -eq "Ethernet" }).IPAddress
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Non-Routable Network Website</title>
    <style>
        body {
            background-color: darkblue;
            color: white;
            font-family: Arial, sans-serif;
        }
        h1 {
            font-size: 36px;
            font-weight: bold;
        }
        h2 {
            font-size: 28px;
            font-weight: normal;
        }
    </style>
</head>
<body>
    <h1>Welcome to the Non-Routable Network Website</h1>
    <h2>Hostname: $hostname</h2>
    <h2>IP Address: $ipAddress</h2>
</body>
</html>
"@
# Write the HTML content to the default website's index.html file
$defaultWebsitePath = "C:\inetpub\wwwroot\index.html"
Set-Content -Path $defaultWebsitePath -Value $htmlContent
# Restart IIS to apply changes
Restart-Service -Name "W3SVC"