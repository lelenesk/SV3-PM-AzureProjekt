#VM: FS1 Image:Windows Server Core 2019 Gen2

Start-Transcript -Path "C:\Az-Cli\02.txt" 
#Variables
$pwd =  pwd | Select -ExpandProperty Path

#Get Initial variables from Json
$Variables= Get-Content ".\_variables.json" | ConvertFrom-Json

$RG= $Variables.Variable.RG
$Vnet= $Variables.Variable.Vnet
$Subnet= $Variables.Variable.Subnet
$IPdc1= $Variables.Variable.IP_dc1
$Domain= $Variables.Variable.Domain
$Admin= $Variables.Variable.Admin
$Password= $Variables.Variable.Password
$Ip = $Variables.Variable.IP_fs1

#VM Details
$VM_Name="FS1"
$Public_Ip="pm-projekt-fs1"
$Nsg="pm-projekt-nsg"
$DiskName ="pm-project"

#Set default ResourceGroup
az configure --defaults group=$RG

#VM Create
Write-Host "VM Create: $VM_Name" -ForegroundColor Red
az vm create --name $VM_Name `
--priority Spot `
--max-price -1 `
--eviction-policy Deallocate `
--resource-group $RG `
--image MicrosoftWindowsServer:WindowsServer:2019-datacenter-core-g2:latest `
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

#Creating new disk
Write-Host "Creating new disk: $DiskName" -ForegroundColor Red
az disk create -g $RG -n $DiskName --size-gb 4 --sku StandardSSD_LRS

#Attaching disk to VM
Write-Host "Attaching disk:$DiskName to $VM_Name" -ForegroundColor Red
az vm disk attach `
    --resource-group $RG `
    --vm-name $VM_Name `
    --name $DiskName 

#Change IP to Static on NIC
$NIC= $VM_Name + "VMNic";
Write-Host "Change IP to Static($Ip) on $NIC" -ForegroundColor Red
$IPConfig= "ipconfig" + $VM_Name
az network nic ip-config update `
--name $IPConfig `
--resource-group $RG `
--nic-name $NIC `
--private-ip-address $Ip

#Run DNS Setup script
Write-Host "Run script: 02_dns_setup.ps1" -ForegroundColor Red
az vm run-command invoke `
-g $RG `
-n $VM_Name `
--command-id RunPowerShellScript --scripts @$pwd\02_dns_setup.ps1 --parameters "Ip=$Ip" "Dc=$IPdc1"

#Run drive init script
Write-Host "Run script: 02_drive_init.ps1" -ForegroundColor Red
az vm run-command invoke `
-g $RG `
-n $VM_Name `
--command-id RunPowerShellScript --scripts @$pwd\02_drive_init.ps1

#Run AD Join script
Write-Host "Run script: _ad_join.ps1" -ForegroundColor Red
az vm run-command invoke `
-g $RG `
-n $VM_Name `
--command-id RunPowerShellScript `
--scripts @$pwd\_ad_join.ps1 --parameters "Password=$Password" "Domain=$Domain" "Admin=$Admin"

#Wait 3 min (Time to restarting)
$Seconds = 180
$EndTime = [datetime]::UtcNow.AddSeconds($Seconds)

while (($TimeRemaining = ($EndTime - [datetime]::UtcNow)) -gt 0) {
  Write-Progress -Activity 'Watiting for...' -Status Reboot... -SecondsRemaining $TimeRemaining.TotalSeconds
  Start-Sleep 1
}

#Run script (Files Sharing, Folders,Quota)
Write-Host "Run script: 02_scripts.ps1" -ForegroundColor Red
az vm run-command invoke `
-g $RG `
-n $VM_Name `
--command-id RunPowerShellScript `
--scripts @$pwd\02_scripts.ps1 --parameters "Domain=$Domain" "Admin=$Admin"