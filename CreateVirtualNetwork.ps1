Param(
	[string] $AzureLocation = "northeurope",
    [string] $AzureUserName = "adminusername@<domainname>.onmicrosoft.com",
	[string] $AzureUserPassword = "<adminpassword>"

)

# Prepare credentials to loging to Azure subscription  
$azurePass = ConvertTo-SecureString $AzureUserPassword -AsPlainText -Force
$azureCred = New-Object System.Management.Automation.PSCredential ($AzureUserName, $azurePass)



# Login to an Azure subscription
Connect-AzureRmAccount -Credential $azureCred


# Create a resource group in North Europe region 
New-AzureRmResourceGroup -Name "BAT-VNET-RG" -Location $AzureLocation

# Configure subnets
$azureSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name bat-vnet-azure -AddressPrefix "10.16.149.0/24"
$secSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name bat-vnet-sec -AddressPrefix "10.16.148.0/24" 
$vms1Subnet = New-AzureRmVirtualNetworkSubnetConfig -Name bat-vnet-vms1 -AddressPrefix "10.16.151.0/26"
$vms2Subnet = New-AzureRmVirtualNetworkSubnetConfig -Name bat-vnet-vms2 -AddressPrefix "10.16.151.64/26"

# Create virtual network with configured subnets 
New-AzureRmVirtualNetwork -Name bat-vnet -ResourceGroupName BAT-VNET-RG `
    -Location $AzureLocation -AddressPrefix "10.16.144.0/21" -Subnet $azureSubnet,$secSubnet,$vms1Subnet,$vms2Subnet 
