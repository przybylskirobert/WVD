# WVD repository
Hi there!
This is my place where I'm putting all the scripts and config files regarding Windows Virtual Desktop.

If you want to start from scratch use those links:
- [Windows Virtual Desktop: Initial deployment](https://www.azureblog.pl/2020/09/19/windows-virtual-desktop-deployment-1-5/)
- [1_WVD_environment_initial_steps.ps1](https://github.com/przybylskirobert/WVD/blob/master/1_WVD_environment_initial_steps.ps1) 

If you want to work on your GoldenImage for WVD please use those links:
- [Windows Virtual Desktop: GoldenImage from VHD
](https://www.azureblog.pl/2020/10/07/windows-virtual-desktop-deployment-2-5/) 
- [Windows Virtual Desktop: GoldenImage from SharedImage Gallery
](https://www.azureblog.pl/2020/10/09/windows-virtual-desktop-deployment-3-5/)
- [2_GoldenImage_creation_steps.ps1](https://github.com/przybylskirobert/WVD/blob/master/2_GoldenImage_creation_steps.ps1) 

If you want to use FSLogix in your environment this could be handy: 
- [Windows Virtual Desktop: Golden Image Optimization
](https://www.azureblog.pl/2020/11/15/windows-virtual-desktop-deployment-4-5/)
- [Setup-StorageAccount.ps1](https://github.com/przybylskirobert/WVD/blob/master/Setup-StorageAccount.ps1)
- [3_ConfigureOS_steps.ps1](https://github.com/przybylskirobert/WVD/blob/master/3_ConfigureOS_steps.ps1)

For VMSS usage take a look at here:
- [Windows Virtual Desktop: VMSS usage
](https://www.azureblog.pl/2020/12/17/windows-virtual-desktop-deployment-5-5/)
- [4_VMSS_GoldenImage_configuration_steps.ps1](https://github.com/przybylskirobert/WVD/blob/master/4_VMSS_GoldenImage_configuration_steps.ps1)
- [VMSS_deployment_template.json](https://github.com/przybylskirobert/WVD/blob/master/VMSS_deployment_template.json)
- [VMSS_deployment_parameters.json](https://github.com/przybylskirobert/WVD/blob/master/VMSS_deployment_parameters.json)

For all in one deployment use the following json files:
- [WVD_core_components.json](https://github.com/przybylskirobert/WVD/blob/master/WVD_core_components.json)
- [WVD_core_components_parameters.json](https://github.com/przybylskirobert/WVD/blob/master/WVD_core_components_parameters.json)

Before the deployemnt please create the following resource groups:
- **ResourceGroupPrefix**-mgmt-**RegionSuffix** -> test_rg-mgmt-neu
- **ResourceGroupPrefix**-network-**RegionSuffix** -> test_rg-network-neu
- **ResourceGroupPrefix**-wvd-**RegionSuffix** -> test_rg-wvd-neu

After resource groups creation during the deployment update the following parameters:
- ResourceGroupPrefix
- RegionSuffix

