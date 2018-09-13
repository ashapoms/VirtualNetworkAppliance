# Define parameters 
Param(
	[string] $AzureLocation = "northeurope",
	[string] $DeployIndex = "02",
	[string] $ResourceGroupPrefix = "BAT-ROUTER-SRV",
    [string] $VmPrefix = "router-srv",
    [string] $SubnetName01 = "bat-vnet-vms1",
    [string] $SubnetName02 = "bat-vnet-vms2",
    [string] $VmUserName = "<vmusername>",
	[string] $VmUserPassword = "<vmuserpassword>",
    [string] $VmSize = "Standard_D2s_v3",
    [string] $AzureUserName = "adminusername@<domainname>.onmicrosoft.com",
	[string] $AzureUserPassword = "<adminpassword>"


)


# Initialize variables 
$rgName = $ResourceGroupPrefix + $DeployIndex + "-RG" 
$vmName = $VmPrefix + $DeployIndex
$nsgName = $VmPrefix + $DeployIndex + "-nsg"
$publicIpName = $VmPrefix + $DeployIndex + "-pip"
$nicName01 = $VmPrefix + $DeployIndex + "-nic01"
$nicName02 = $VmPrefix + $DeployIndex + "-nic02"
$vnetName = "bat-vnet"
$vnetRgName = "BAT-VNET-RG"


# Prepare credentials to loging to Azure subscription  
$azurePass = ConvertTo-SecureString $AzureUserPassword -AsPlainText -Force
$azureCred = New-Object System.Management.Automation.PSCredential ($AzureUserName, $azurePass)


# Login to an Azure subscription
Connect-AzureRmAccount -Credential $azureCred 


# Create a resource group in North Europe region 
$rg = New-AzureRmResourceGroup -Name $rgName -Location $AzureLocation -Verbose


# Create a network security group with RDP allowed 
$rdp = New-AzureRmNetworkSecurityRuleConfig `
    -Name 'Allow-RDP-All' `
    -Description 'Allow RDP' `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1010 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 3389 `
    -Verbose 

$nsg = New-AzureRmNetworkSecurityGroup `
    -ResourceGroupName $rg.ResourceGroupName `
    -Location $AzureLocation `
    -Name $nsgName `
    -SecurityRules $rdp `
    -Verbose 


<#
# Create a Public IP to access VM from Internet 
$publicIp = New-AzureRmPublicIpAddress `
    -ResourceGroupName $rg.ResourceGroupName `
    -Name $publicIpName `
    -location $AzureLocation `
    -AllocationMethod Dynamic `
    -Verbose
#> 


# Get information about virtual network and subnets
$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRgName -Verbose
$subnetId01 = (Get-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName01 -VirtualNetwork $vnet).Id
$subnetId02 = (Get-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName02 -VirtualNetwork $vnet).Id
 


# Create the first network interface for VM 
$nic01 = New-AzureRmNetworkInterface `
    -ResourceGroupName $rg.ResourceGroupName `
    -Name $nicName01 `
    -Location $AzureLocation `
    -SubnetId $SubnetId01 `
    -NetworkSecurityGroupId $nsg.Id `
    -Verbose 

# Create the second network interface for VM 
$nic02 = New-AzureRmNetworkInterface `
    -ResourceGroupName $rg.ResourceGroupName `
    -Name $nicName02 `
    -Location $AzureLocation `
    -SubnetId $SubnetId02 `
    -NetworkSecurityGroupId $nsg.Id `
    -Verbose 




# Prepare credentials for VM administrator account  
$vmuserPass = ConvertTo-SecureString $VmUserPassword -AsPlainText -Force
$vmuserCred = New-Object System.Management.Automation.PSCredential ($VmUserName, $vmuserPass)


# Create and configure VM

# Create VM configuration
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $VmSize -Verbose
$vmConfig = Set-AzureRmVMOperatingSystem -VM $vmConfig `
    -Windows `
    -ComputerName $vmName `
    -Credential $vmuserCred `
    -ProvisionVMAgent `
    -EnableAutoUpdate `
    -Verbose
$vmConfig = Set-AzureRmVMSourceImage -VM $vmConfig `
    -PublisherName "MicrosoftWindowsServer" `
    -Offer "WindowsServer" `
    -Skus "2016-Datacenter" `
    -Version "latest" `
    -Verbose

# Attach network interfaces 
$vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic01.Id -Primary -Verbose
$vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic02.Id -Verbose


# Create VM
New-AzureRmVM -VM $vmConfig -ResourceGroupName $rg.ResourceGroupName -Location $AzureLocation -Verbose 