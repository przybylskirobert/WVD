<#
.EXAMPLE
.\Setup-StorageAccount -ToolsPath C:\Tools -AzFilesPath 'https://github.com/Azure-Samples/azure-files-samples/releases/download/v0.2.2/AzFilesHybrid.zip' -StorageAccountName fslxazureblog -StorageAccountResourceGroupName rg-WVD
#>

param (  
    [string] $ToolsPath,
    [string] $AzFilesPath,
    [string] $StorageAccountName,
    [string] $StorageAccountResourceGroupName
)

$moduleName = [System.IO.Path]::GetFileNameWithoutExtension("$AzFilesPath")
$azFilesZip = "$ToolsPath\$($moduleName).zip"
$azFilesFolderName = "$ToolsPath\$moduleName"

$toolsTest = Test-Path -Path $ToolsPath
if ($toolsTest -eq $false) {
    Write-Verbose "Creating '$ToolsPath' directory"
    New-Item -ItemType Directory -Path $ToolsPath | Out-Null
}
else {
    Write-Verbose "Directory '$ToolsPath' already exists."
}

Write-Verbose "Downloading '$AzFilesPath' into '$azFilesZip'"
Invoke-WebRequest -Uri $AzFilesPath -OutFile $azFilesZip
New-Item -ItemType Directory -Path "$azFilesFolderName"
Write-Verbose "Expanding Archive '$azFilesZip ' into '$azFilesFolderName'"
Expand-Archive -LiteralPath $azFilesZip -DestinationPath $azFilesFolderName

Connect-AzAccount
Set-Location $azFilesFolderName
.\CopyToPSPath.ps1

$moduleTest = Get-Module -Name 'AzFilesHybrid'
if ($moduleTest -eq $null) {
    Write-Verbose "Importing module 'AzFilesHybrid'"
    Import-Module -Name AzFilesHybrid
}

Write-Verbose "Joining storageaccount '$StorageAccountName' into the domain"
Join-AzStorageaccountForAuth -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -DomainAccountType "ComputerAccount" 

Write-Verbose "Remember to assign NTFS permissions on a network share."
Write-Verbose "User Account   Folder   Permissions"
Write-Verbose "Users   This Folder Only   Modify"
Write-Verbose "Creator / Owner   Subfolders and Files Only   Modify"
Write-Verbose "Administrator (optional)   This Folder, Subfolders, and Files   Full Control"
