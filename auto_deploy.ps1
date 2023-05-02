Start-Transcript -Path "C:\Az-Cli\auto-deploy.txt" 
#Variables
$pwd =  pwd | Select -ExpandProperty Path

#Get Initial variables from Json
$Variables= Get-Content ".\_variables.json" | ConvertFrom-Json

$RG= $Variables.Variable.RG
$Vnet= $Variables.Variable.Vnet
$Subnet= $Variables.Variable.Subnet
$IP_AdrrSpace = $Variables.Variable.IP_AdrrSpace
$IP_Subnet = $Variables.Variable.IP_Subnet
$IPdc1= $Variables.Variable.IP_dc1
$Domain= $Variables.Variable.Domain
$Admin= $Variables.Variable.Admin
$Password= $Variables.Variable.Password
$Default_ADUP = $Variables.Variable.Default_ADUP

#VM Details
$VM_Name="DC1"
$Public_Ip="PM-Projektdc1"
$Nsg="PM-Projektnsg"

#Set default ResourceGroup
az configure --defaults group=$RG

#Create Networking
az network vnet create --name $Vnet `
--address-prefix $IP_AdrrSpace `
--subnet-name $Subnet `
--subnet-prefix $IP_Subnet

#VM Create
Write-Host "VM Create: $VM_Name" -ForegroundColor Red
az vm create --name $VM_Name `
--priority Spot `
--max-price -1 `
--eviction-policy Deallocate `
--resource-group $RG `
--image MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest `
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
Write-Host "Change IP to Static($IPdc1) on $NIC" -ForegroundColor Red
$IPConfig= "ipconfig" + $VM_Name
az network nic ip-config update `
--name $IPConfig `
--resource-group $RG `
--nic-name $NIC `
--private-ip-address $IPdc1

#Enable Icmp on NSG for Test-Netconnection 
Write-Host "Enable Icmp on NSG fot Test-Netconnection" -ForegroundColor Red
az network nsg rule create `
 --nsg-name "$Nsg" `
 --name "Enable ICMP" `
 --description "Enable Icmp on NSG fot Test-Netconnection" `
 --protocol "Icmp" `
 --direction "Inbound" `
 --priority "1010" `
 --destination-port-ranges "*"

 #Install AD Domain Services + Create DC Forest
 Write-Host "ADDS DC Install" -ForegroundColor Red
 $RG="GT"
 $VM_Name ="DC1"
 az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts @$pwd\01_dc_install.ps1 --parameters "passwd=$Password" "domain=$Domain" "IPdc1=$IPdc1"

#Check VM is rebooted?
$port = "3389"

do {
   #waiting for rebooting
   sleep 10
   #check
   Write-Host "Waiting for reboot" -ForegroundColor Red
   sleep 10
   $public_ip= az vm show -d -g $RG -n $VM_Name --query publicIps -o tsv    
   Write-Host $public_ip
} until(Test-NetConnection $public_ip -Port 3389 | ? { $_.TcpTestSucceeded} )
   
#Check AD install finished?
[bool]$ad_installed= $false
$try=0
$check= $false

while ($ad_installed -eq $false) {
Start-Transcript -Path "C:\Az-Cli\ad_install.txt" 

Write-Host "Creating AD Organisations, Groups Users ..." -ForegroundColor Red

$cmd= az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts @$pwd\01_dc_ou_users.ps1 --parameters "Admin=$Admin" "DefaultADUP=$Default_ADUP" "Domain=$Domain"

Write-Output $cmd 

$check = (Get-Content -Path "C:\Az-Cli\ad_install.txt" |  Select-String -Pattern 'ActiveDirectoryOperationException').Matches.Success

#Check for null value
if (!$check) {

   $ad_installed= $true
   Write-Host "[Ok] Creating AD Organisations, Groups Users ..." -ForegroundColor Green
   Stop-Transcript

} else {
   Stop-Transcript
   del C:\Az-Cli\ad_install.txt
   $try++

   #wait 60sec
   $Seconds = 60
   $EndTime = [datetime]::UtcNow.AddSeconds($Seconds)
   
   while (($TimeRemaining = ($EndTime - [datetime]::UtcNow)) -gt 0) {
     Write-Progress -Activity 'Watiting for...' -Status ADDS... -SecondsRemaining $TimeRemaining.TotalSeconds
     Start-Sleep 1
   }
   Write-Host "Attempts: $try" -ForegroundColor Red
   Write-Output $cmd 
}

} 

Write-Host "DHCP Role Install" -ForegroundColor Red

az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts @$pwd\01_dhcp_role.ps1

#Run DNS Scripts
Write-Host "Run DNS Scripts" -ForegroundColor Red

az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts @$pwd\01_dns.ps1  

Write-Host "The First part is finished ... :)" -ForegroundColor Green

#Run Deploy Stage 2 (FS1)
iex ./02.ps1
Write-Host "The Second part is finished ... :)" -ForegroundColor Green

#Run Deploy Stage 3 (W10Client)
iex ./03.ps1

Write-Host "The Final part is finished ... :)" -ForegroundColor Green

Stop-Transcript