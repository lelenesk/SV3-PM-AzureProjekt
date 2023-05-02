Start-Transcript -Path "C:\Logs\01_dns_role.txt" 

#Add New Zone
Add-DnsServerPrimaryZone -Name "GT-pmproject.hu" -ReplicationScope "Forest" -PassThru

#Add A Records
Add-DnsServerResourceRecordA -Name "GT-pmproject.hu" -ZoneName "GT-pmproject.hu" -AllowUpdateAny -IPv4Address "172.16.0.10" -TimeToLive 01:00:00
Add-DnsServerResourceRecordA -Name "dc" -ZoneName "GT-pmproject.hu" -AllowUpdateAny -IPv4Address "172.16.0.10" -TimeToLive 01:00:00
Add-DnsServerResourceRecordA -Name "fs1" -ZoneName "GT-pmproject.hu" -AllowUpdateAny -IPv4Address "172.16.0.11" -TimeToLive 01:00:00

#Add Cname REcords
Add-DnsServerResourceRecordCName -Name "www" -HostNameAlias "fs1.GT-pmproject.hu" -ZoneName "GT-pmproject.hu"
Add-DnsServerResourceRecordCName -Name "mail" -HostNameAlias "dc.GT-pmproject.hu" -ZoneName "GT-pmproject.hu"

$userName = 'Trainer'
$userPassword = 'Demo1234#'
$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force

$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)
Stop-Transcript