Throw "This is not a robust file"
$oldVerbose = $VerbosePreference
$VerbosePreference = "continue" 

#Region Values declaration
    Import-Module Az.DesktopVirtualization
    $resourceLocation = "NorthEurope"
    $vmResourceGroupName = 'rg-vms'
    $giResourceGroupName = 'rg-GoldenImage'
    $vmName = Read-host -Prompt "Please Provide VM Name"
    $date = Get-date -UFormat "%d_%m_%Y"
    $snapshotName = "snap-" + $vmName + "_" + $date
    $imageName = "img-" + $vmName + "_" + $date
#endregion

#Region Create Snapshot
    Write-Verbose "Looking for VM:'$vmName'"
    $vm = Get-AzVM -ResourceGroupName $vmResourceGroupName -Name $vmName 
    $diskID = $vm.StorageProfile.OsDisk.ManagedDisk.Id
    Write-Verbose "Creating Snapshoot config for '$vmName' OSDisk '$diskID'"
    $snapshot = New-AzSnapshotConfig -SourceUri $diskID -Location $resourceLocation -CreateOption copy
    $snapshotTest = Get-AzSnapshot -SnapshotName $snapshotName -ResourceGroupName $vmResourceGroupName -ErrorAction SilentlyContinue
    if ($null -eq $snapshotTest) {
        Write-Verbose "Creating new snapshot for VM: '$vmName', SnapshootName: '$snapshotName'"
        New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $vmResourceGroupName
    }
    else {
        Write-Verbose "Snapshot for VM: '$vmName', SnapshootName: '$snapshotName' already created."
    }
#endregion

#region Create Image from VM
    Write-Verbose "Looking for VM:'$vmName'"
    $vm = Get-AzVM -ResourceGroupName $vmResourceGroupName -Name $vmName 
    $vmStatus = (Get-AZVM -ResourceGroupName $vmResourceGroupName -Name $vmName -status).statuses[1].DisplayStatus
    if ($vmStatus -ne 'VM Deallocated') {
        Write-Verbose "Stopping vm:'$vmName'"
        Stop-AzVM -ResourceGroupName $vmResourceGroupName -Name $vmName -Force
    }
    else {
        Write-Verbose "VM:'$vmName' deallocated."
    }
    $diskID = $vm.StorageProfile.OsDisk.ManagedDisk.Id
    $imageTest = Get-AZimage -ResourceGroupName $giResourceGroupName -ImageName $imageName -ErrorAction SilentlyContinue
    if ($null -eq $imageTest) {
        Write-Verbose "Creating image config for vm: '$vmName', OSDisk '$diskID'"
        $imageConfig = New-AzImageConfig -Location $resourceLocation
        $imageConfig = Set-AzImageOsDisk -Image $imageConfig -OsState Generalized -OsType Windows -ManagedDiskId $diskID
        Write-Verbose "Creating new image for VM: '$vmName', imageName: '$imageName'"
        New-AzImage -ImageName $imageName -ResourceGroupName $giResourceGroupName -Image $imageConfig
    }
    else {
        Write-Verbose "Image from VM: '$vmName', ImageName: ''$imageName' already created."
    }
#endregion

#region Create Shared Image Gallery
    $galleryName = Read-host -Prompt "Please provide SharedImageGallery name"
    $galleryTest = Get-AZGallery -ResourceGroupName $giResourceGroupName -GalleryName $galleryName -ErrorAction SilentlyContinue
    if ($null -eq $galleryTest) {
        Write-Verbose "Creating image gallery: '$galleryName'"
        New-AzGallery -GalleryName $galleryName -ResourceGroupName $giResourceGroupName -Location $resourceLocation
    }
    else {
        Write-Verbose "Gallery '$galleryName' already created."
    }
#endregion

#region Upload Image to SIG
    Write-Verbose "Looking for SharedImageGallery: '$galleryName'"
    $gallery = Get-AzGallery -Name $galleryName -ResourceGroupName $giResourceGroupName
    $imageID = (Get-AzImage -ResourceGroupName $giResourceGroupName -ImageName $imageName).id

    Write-Verbose "Creating ImageDefinition"
    $imageDefinition = New-AzGalleryImageDefinition -GalleryName $gallery.Name -ResourceGroupName $giResourceGroupName -Location $resourceLocation -Name 'Windows10-MU-AcrobatDC' -OsState Generalized -OsType Windows -Publisher 'Azureblog' -Offer 'Azureblog' -Sku '1'

    $region1 = @{Name='northeurope';ReplicaCount=1}
    $targetRegions = @($region1)
    
    Write-Verbose "Creating ImageVersion"
    New-AzGalleryImageVersion -GalleryImageDefinitionName $imageDefinition.Name -GalleryImageVersionName '1.0.1' -GalleryName $gallery.Name -ResourceGroupName $giResourceGroupName -Location $resourceLocation -TargetRegion $targetRegions -SourceImageId $imageID -PublishingProfileEndOfLifeDate '2021-10-06' -asJob 

#endregion
$VerbosePreference = $oldVerbose
