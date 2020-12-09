Throw "This is not a robust file"

#region Variables

$verboseSettings = $VerbosePreference
$VerbosePreference = 'Continue'
$toolsPath = "C:\Tools"
$fsLogixURL = "https://aka.ms/fslogix_download"
$fslogixZip = "$toolsPath\FSLogix.zip"
$fslogixFolderName = "$toolsPath\" + [System.IO.Path]::GetFileNameWithoutExtension("$fslogixZip")
$optimalizationScriptURL = 'https://github.com/przybylskirobert/Virtual-Desktop-Optimization-Tool/archive/master.zip'
$optimalizationScriptZIP = "$toolsPath\WVDOptimalization.zip"
$OptimalizationFolderName = "$toolsPath\" + [System.IO.Path]::GetFileNameWithoutExtension("$optimalizationScriptZIP")

#endregion

#region update Hosts file
$IP = Read-Host "Please provide storage account private endpoint IP"
$storageAccountName = Read-Host "Please provide storage account name"
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "$IP`$($storageAccountName)file.core.windows.net" -Force
notepad C:\Windows\System32\drivers\etc\hosts
#endregion

#region FSLogix

$toolsTest = Test-Path -Path $toolsPath
if ($toolsTest -eq $false){
    Write-Verbose "Creating '$toolsPath' directory"
    New-Item -ItemType Directory -Path $toolsPath | Out-Null
}
else {
    Write-Verbose "Directory '$toolsPath' already exists."
}
Write-Verbose "Downloading '$fsLogixURL' into '$fslogixZip'"
Invoke-WebRequest -Uri $fsLogixURL -OutFile $fslogixZip
New-Item -ItemType Directory -Path "$fslogixFolderName"
Write-Verbose "Expanding Archive '$fslogixZip ' into '$fslogixFolderName'"
Expand-Archive -LiteralPath $fslogixZip -DestinationPath $fslogixFolderName
Set-Location "$fslogixFolderName\x64\Release"
Write-Verbose "Installing FSLogix software"
.\FSLogixAppsSetup.exe /quiet /norestart /install

#endregion

#region FSLogix Config

$regPath = "HKLM:\SOFTWARE\FSLogix\Profiles"
New-Item -Path $regPath -Force | Out-Null
New-ItemProperty -Path $regPath -name "Enabled" -PropertyType "DWord" -Value "1" -Force | Out-Null
New-ItemProperty -Path $regPath -name "VHDLocations" -PropertyType "String" -Value "\\$($storageAccountName).file.core.windows.net\fslogixprofiles" -Force | Out-Null
New-ItemProperty -Path $regPath -name "VolumeType" -PropertyType "String" -Value "VHDX" -Force | Out-Null
New-ItemProperty -Path $regPath -name "SizeInMBs" -PropertyType "DWord" -Value "2000" -Force | Out-Null
New-ItemProperty -Path $regPath -name "IsDynamic" -PropertyType "DWord" -Value "00000001" -Force | Out-Null
New-ItemProperty -Path $regPath -name "LockedRetryCount" -PropertyType "DWord" -Value "00000003" -Force | Out-Null
New-ItemProperty -Path $regPath -name "LockedRetryInterval" -PropertyType "DWord" -Value "00000005" -Force | Out-Null
New-ItemProperty -Path $regPath -name "FlipFlopProfileDirectoryName" -PropertyType "DWord" -Value "00000001" -Force | Out-Null
New-ItemProperty -Path $regPath -name "DeleteLocalProfileWhenVHDShouldApply" -PropertyType "DWord" -Value "00000001" -Force | Out-Null
New-ItemProperty -Path $regPath -name "PreventLoginWithTempProfile" -PropertyType "DWord" -Value "00000000" -Force | Out-Null
New-ItemProperty -Path $regPath -name "PreventLoginWithFailure" -PropertyType "DWord" -Value "00000001" -Force | Out-Null
$sid_LocalAdministrators = 'S-1-5-32-544'
$sid_DomainUsers = (Get-ADGroup -identity 'Domain Users' -Properties *).SID.value
Remove-LocalGroupMember -Group 'FSLogix Profile Include List' -Member 'Everyone' | Out-Null
Add-LocalGroupMember -Group 'FSLogix Profile Include List' -Member $sid_DomainUsers | Out-Null
Add-LocalGroupMember -Group 'FSLogix Profile Exclude List' -Member $sid_LocalAdministrators | Out-Null

#endRegion

#region Optimalization

Write-Verbose "Downloading '$optimalizationScriptURL' into '$optimalizationScriptZIP'"
Invoke-WebRequest -Uri $optimalizationScriptURL -OutFile $optimalizationScriptZIP
New-Item -ItemType Directory -Path "$OptimalizationFolderName"
Write-Verbose "Expanding Archive '$optimalizationScriptZIP ' into '$OptimalizationFolderName'"
Expand-Archive -LiteralPath $optimalizationScriptZIP -DestinationPath $OptimalizationFolderName
Set-Location "$OptimalizationFolderName\Virtual-Desktop-Optimization-Tool-master"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
.\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion 2004 -Verbose

#endregion

#region Customize OS

Write-Verbose "Disabling Windows updates"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f
Write-Verbose "Configuring Time zone redirection"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fEnableTimeZoneRedirection /t REG_DWORD /d 1 /f
Write-Verbose "Disabling Storage Sense"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 01 /t REG_DWORD /d 0 /f

#endregion

#region Finalization
Set-Location c:\
Remove-Item -Path $toolsPath -Force
Write-Verbose "Removing Computer from domain"
Remove-Computer -credential (Get-Credential) -passthru -WorkgroupName "GoldenImage" -Force -Restart
Write-Verbose "Starting Sysprep"
. $env:SystemRoot\system32\sysprep\sysprep.exe

#end region
$VerbosePreference = $verboseSettings
