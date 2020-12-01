Throw "This is not a robust file"

#region Variables
$verboseSettings = $VerbosePreference
$VerbosePreference = 'Continue'
$toolsPath = "C:\Tools"
$agentURL = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv"
$agentMSI = "Microsoft.RDInfra.RDAgent.Installer-x64-1.0.2548.6500.msi"
$agentMSIPath = "$toolsPath\$agentMSI"
$bootLoaderURL = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH"
$bootLoaderMSI = "Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi"
$bootLoaderMSIPath = "$toolsPath\$bootLoaderMSI"

#endregion

#region agents installation

$toolsTest = Test-Path -Path $toolsPath
if ($toolsTest -eq $false){
    Write-Verbose "Creating '$toolsPath' directory"
    New-Item -ItemType Directory -Path $toolsPath | Out-Null
}
else {
    Write-Verbose "Directory '$toolsPath' already exists."
}
Write-Verbose "Downloading '$agentURL' into '$agentMSIPath '"
Invoke-WebRequest -Uri $agentURL -OutFile $agentMSIPath 
Write-Verbose "Downloading '$bootLoaderURL' into '$bootLoaderMSIPath'"
Invoke-WebRequest -Uri $bootLoaderURL -OutFile $bootLoaderMSIPath

Set-Location "$toolsPath"
. .\$agentMSI
Start-Sleep -Seconds 60
. .\$bootLoaderMSI

#endregion

#region sysprep
Remove-Item C:\tools -Recurse -Force

. $env:SystemRoot\system32\sysprep\sysprep.exe

#endregion
$VerbosePreference = $verboseSettings 
