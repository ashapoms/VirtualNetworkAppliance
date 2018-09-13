# Define parameters 
Param(
	[string] $AzureLocation = "northeurope",
	[string] $DeployIndex = "01",
	[string] $ResourceGroupPrefix = "BAT-WS2012R2-CLI",
    [string] $VmPrefix = "ws2012r2-cli",
    [string] $subnetName = "bat-vnet-vms2",
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
$nicName = $VmPrefix + $DeployIndex + "-nic"
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
$subnetId = (Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet).Id
 


# Create a network interface for VM 
$nic = New-AzureRmNetworkInterface `
    -ResourceGroupName $rg.ResourceGroupName `
    -Name $nicName `
    -Location $AzureLocation `
    -SubnetId $subnetId `
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
    -Skus "2012-R2-Datacenter" `
    -Version "latest" `
    -Verbose

# Attach a network interface
$vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic.Id -Verbose

# Create VM
New-AzureRmVM -VM $vmConfig -ResourceGroupName $rg.ResourceGroupName -Location $AzureLocation -Verbose 