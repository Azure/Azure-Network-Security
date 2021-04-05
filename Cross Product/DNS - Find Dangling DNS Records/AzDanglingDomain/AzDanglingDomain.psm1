$script:moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path
# Dot source functions
"$script:moduleRoot\Export\*.ps1" | Resolve-Path | Where-Object { $_.ProviderPath -notlike "*Workflow*"} | ForEach-Object{. $_.ProviderPath}

"$script:moduleRoot\Export\*.ps1" | Resolve-Path | Where-Object { $_.BaseName -notlike "*Workflow*"} | ForEach-Object{ Export-ModuleMember -Function $_.BaseName -Verbose}

