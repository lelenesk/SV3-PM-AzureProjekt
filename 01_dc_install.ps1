param(

     [Parameter()]
     [string]$passwd,
 
     [Parameter()]
     [string]$domain,

     [Parameter()]
     [string]$IPdc1

 )

Start-Transcript -Path "C:\Logs\01_dc_install.txt" 

$Netbios= $domain.split(".")[0]

#DNS Setup   
$interface=  Get-NetIPAddress | Where-Object IPAddress -eq $IPdc1
$If_index= $interface.InterfaceIndex
   
Set-DnsClientServerAddress -InterfaceIndex $If_index -ServerAddresses ("$IPdc1")

#Install Windows Server Backup Feature
Install-WindowsFeature Windows-Server-Backup

#Install AD Services + ManagementTools
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

#SafeMode Admin Password Create
$Secure_Pwd = ConvertTo-SecureString $passwd -AsPlainText -Force

Install-ADDSForest `
  -DomainName $domain `
  -DatabasePath "C:\Windows\NTDS" `
  -DomainMode "7" `
  -DomainNetbiosName "$Netbios" `
  -ForestMode "7" `
  -InstallDns:$true `
  -LogPath "C:\Windows\NTDS" `
  -NoRebootOnCompletion:$True `
  -SysvolPath "C:\Windows\SYSVOL"`
  -SafeModeAdministratorPassword $Secure_Pwd `
  -Force 
  
Stop-Transcript
Restart-Computer -Force