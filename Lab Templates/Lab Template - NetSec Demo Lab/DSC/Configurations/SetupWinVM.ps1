Configuration SetupWinVM
{
    Import-DscResource -ModuleName cChoco

    Node localhost
    {
		Script InstallEdge {
            GetScript = { @{ Result = '' } }
            SetScript = { 
				[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri 'https://c2rsetup.officeapps.live.com/c2r/downloadEdge.aspx?ProductreleaseID=Edge&platform=Default&version=Edge&source=EdgeStablePage&Channel=Stable&language=en-gb' -UseBasicParsing -OutFile 'D:\edge.exe'
                Start-Sleep 10
				Start-Process -FilePath 'D:\edge.exe' -PassThru 
            }
            TestScript = { 
                Test-Path "${Env:PROGRAMFILES(X86)}\Microsoft\Edge\Application\msedge.exe"
            }
        }

    }
}
