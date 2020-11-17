$oldVerbose = $VerbosePreference
$VerbosePreference = "continue" 

#Region Values declaration

import-module Az.DesktopVirtualization
$ResourceLocation = "NorthEurope"
$WVDLocation = "eastUS"
$ResourceGroupName = 'WVD_test'
$prefix = 'WGUISW'
$maxLimit = 2
$WVDusersGroupName = 'WVD_Users'

$WVDConfig = @(
    $(New-Object PSObject -Property @{WorkspaceName = "$($prefix)_WSPACE_DESKTOP"; HostPoolName = "$($prefix)_HOST_POOL_DESKTOP"; AppGroupeName = "$($prefix)_APP_GROUP_DESKTOP"; PreferedAppGroupType = 'Desktop'; FriendlyName = "$($prefix)_DSK" }),
    $(New-Object PSObject -Property @{WorkspaceName = "$($prefix)_WSPACE_REMOTE"; HostPoolName = "$($prefix)_HOST_POOL_REMOTE"; AppGroupeName = "$($prefix)_APP_GROUP_REMOTE"; PreferedAppGroupType = 'RailApplications'; FriendlyName = "$($prefix)_RAP" })
)

Connect-AzureAD
$wvd_UsersGroup = Get-AzureADGroup -SearchString $WVDusersGroupName
#endregion


#Region RG Creation
New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceLocation -Force
#endregion

#Region WVD resources deployment

foreach ($entry in $WVDConfig) {
    $workspaceName = $entry.WorkspaceName
    $hostPoolName = $entry.HostPoolName
    $appGroupName = $entry.AppGroupeName
    $preferedAppGroupType = $entry.PreferedAppGroupType
    $friendlyName = $entry.FriendlyName

    if ($preferedAppGroupType -eq "Desktop") {
        $aplicationGroupType = "Desktop"
    }
    else {
        $aplicationGroupType = "RemoteApp"
    }

    $workspacetest = Get-AzWvdWorkspace -Name $workspaceName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if ($workspacetest.count -eq 0) {
        Write-Verbose "Creating new Workspace:'$workspaceName' in resourcegroup: '$ResourceGroupName', under location: '$WVDLocation'"
        New-AzWvdWorkspace -Name $workspaceName -ResourceGroupName $ResourceGroupName -Location $WVDLocation
    }
    else {
        Write-Verbose "Workspace:'$workspaceName' already exist."
    }
    $hostpooltest = Get-AzWvdHostPool -Name $hostPoolName -ResourceGroupName $ResourceGroupName  -ErrorAction SilentlyContinue
    if ($hostpooltest.count -eq 0) {
        Write-Verbose "Creating new HostPool :'$hostPoolName' in resourcegroup: '$ResourceGroupName', under location: '$WVDLocation'"
        New-AzWvdHostPool -Name $hostPoolName -ResourceGroupName $ResourceGroupName -Location $WVDLocation -HostPoolType Pooled -LoadBalancerType DepthFirst -PreferredAppGroupType $preferedAppGroupType -MaxSessionLimit $maxLimit
        New-AzWvdRegistrationInfo -ResourceGroupName $ResourceGroupName -HostPoolName $hostPoolName -ExpirationTime $((get-date).ToUniversalTime().AddDays(30).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))
    }
    else {
        Write-Verbose "HostPool:'$hostPoolName' already exist."
    }
    $applicationGroupTest = Get-AzWvdApplicationGroup -Name $appGroupName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if ($applicationGroupTest.count -eq 0) {
        Write-Verbose "Creating new ApplicationGroup:'$appGroupName' in resourcegroup: '$ResourceGroupName', under location: '$WVDLocation'"
        $hostPoolID = (Get-AzWvdHostPool -Name $hostPoolName -ResourceGroupName $ResourceGroupName).id
        New-AzWvdApplicationGroup -Name $appGroupName -ResourceGroupName $ResourceGroupName -Location $WVDLocation -FriendlyName $friendlyName -HostPoolArmPath $hostPoolID -ApplicationGroupType $aplicationGroupType
        $appGroupID = (Get-AzWvdApplicationGroup -Name $appGroupName -ResourceGroupName $ResourceGroupName).id
        Update-AzWvdWorkspace -Name $workspaceName -ResourceGroupName $ResourceGroupName -ApplicationGroupReference $appGroupID
    }
    else {
        Write-Verbose "ApplicationGroup:'$appGroupName' already exist."
    }
    Write-Verbose "Assigning group '$WVDusersGroupName' to the Application Group '$appGroupName'"
    New-AzRoleAssignment -ObjectId $wvd_UsersGroup.ObjectID -RoleDefinitionName "Desktop Virtualization User" -ResourceName $appGroupName -ResourceGroupName $resourceGroupName -ResourceType `Microsoft.DesktopVirtualization/applicationGroups'

}
#endregion


$VerbosePreference = $oldVerbose
