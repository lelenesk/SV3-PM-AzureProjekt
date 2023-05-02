Start-Transcript -Path "C:\Logs\01_dhcp_role.txt" 

#Install DHCP Role
Install-WindowsFeature -Name DHCP -IncludeManagementTools

netsh dhcp add securitygroups
Restart-Service dhcpserver
Add-DhcpServerv4Scope -name "PM-Projekt" -StartRange 172.16.0.100 -EndRange 172.16.0.200 -SubnetMask 255.255.255.0 -State Active

#Get Azure Gateway IP
$conf = Get-NetIPConfiguration
$gateway = $conf.IPv4DefaultGateway | Select-Object -ExpandProperty Nexthop

#Setup DNS name and gateway
Set-DhcpServerV4OptionValue -ComputerName project.local -ScopeID 172.16.0.100 -DNSServer 172.16.0.10 -Router $gateway

#Check
DhcpServerV4Scope
Get-DhcpServerV4OptionValue

Stop-Transcript