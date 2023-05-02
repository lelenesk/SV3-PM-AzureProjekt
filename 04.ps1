#VM:W11Client Image:Windows 11 Pro
Start-Transcript -Path "C:\Az-Cli\04.txt"

#Variables
$pwd =  pwd | Select -ExpandProperty Path

#Get Initial variables from Json
$Variables= Get-Content ".\_variables.json" | ConvertFrom-Json

$RG= $Variables.Variable.RG
$Vnet= $Variables.Variable.Vnet
$Subnet= $Variables.Variable.Subnet
$IPdc1= $Variables.Variable.IP_dc1
$Ip = $Variables.Variable.IP_w11client
$Domain= $Variables.Variable.Domain
$Admin= $Variables.Variable.Admin
$Password= $Variables.Variable.Password

#VM Details
$VM_Name="W11Client"
$Public_Ip="pm-projekt-w11-client"
$Nsg="pm-projekt-nsg"

#Set default ResourceGroup
az configure --defaults group=$RG

#VM Create
Write-Host "VM Create: $VM_Name" -ForegroundColor Red
az vm create --name $VM_Name `
--priority Spot `
--max-price -1 `
--eviction-policy Deallocate `
--resource-group $RG `
--image microsoftwindowsdesktop:windows-11:win11-21h2-pro:latest `
--size Standard_D2as_v4 `
--authentication-type password `
--admin-username $Admin `
--admin-password $Password `
--nsg-rule RDP `
--storage-sku StandardSSD_LRS `
--vnet-name $Vnet `
--subnet $Subnet `
--public-ip-address $Public_Ip `
--nsg $Nsg `
--public-ip-sku Basic `
--public-ip-address-allocation dynamic `
--nic-delete-option Delete `
--os-disk-delete-option Delete

#Change IP to Static on NIC
$NIC= $VM_Name + "VMNic";
Write-Host "Change IP to Static($Ip) on $NIC" -ForegroundColor Red
$IPConfig= "ipconfig" + $VM_Name
az network nic ip-config update `
--name $IPConfig `
--resource-group $RG `
--nic-name $NIC `
--private-ip-address $Ip

#Run script 04_scripts.ps1
Write-Host "Run script: 04_scripts.ps1" -ForegroundColor Red
az vm run-command invoke `
-g $RG `
-n $VM_Name `
--command-id RunPowerShellScript --scripts @$pwd\04_scripts.ps1 --parameters "Ip=$Ip" "Dc=$IPdc1"

#Run AD Join script
Write-Host "Run script: _ad_join.ps1" -ForegroundColor Red
az vm run-command invoke `
-g $RG `
-n $VM_Name `
--command-id RunPowerShellScript `
--scripts @$pwd\_ad_join.ps1 --parameters "Password=$Password" "Domain=$Domain" "Admin=$Admin"

Stop-Transcript