param(
 
     [Parameter()]
     [string]$Ip,

     [Parameter()]
     [string]$Dc

 )
Start-Transcript -Path "C:\Logs\04_scripts.txt"

#Setup DNS for AD domain join

$interface=  Get-NetIPAddress | Where-Object IPAddress -eq $Ip
$If_index= $interface.InterfaceIndex
Set-DnsClientServerAddress -InterfaceIndex $If_index -ServerAddresses ($Dc)

Stop-Transcript