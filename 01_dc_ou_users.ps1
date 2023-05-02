param(
 
     [Parameter()]
     [string]$Admin,

     [Parameter()]
     [string]$DefaultADUP,

     [Parameter()]
     [string]$Domain

 )
 Start-Transcript -Path "C:\Logs\01_dc_ou_users.txt" 

 $Password = $DefaultADUP | ConvertTo-SecureString -AsPlainText -Force

 #Split AD Domain name
 $dc_01 = $Domain.split(".")[0]
 $dc_02 = $Domain.split(".")[1]

 #Check
 if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'PROJECT'")) {

#Add Organization Units
 $OU_List=@("PROJECT","Hallgatok","Oktatok","KliensGepek","Csoportok")

foreach ($ou in $OU_List) {
    New-ADOrganizationalUnit -Name "$ou" -Path "DC=$dc_01,DC=$dc_02"
}

#Default User Password
$Password = $DefaultADUP | ConvertTo-SecureString -AsPlainText -Force

#Add Users to Hallgatok OU
$Hallgatok_U=@("Gipsz Jakab","Beton Bela")


$Oktatok_U =@("Trainer")

foreach ($U in $Hallgatok_U) {  
    $Sam = $U.replace(" ",'.').ToLower()
    $princ = "$U"+"`@$Domain"
    $split = $U.split(" ")
    New-ADUser -Name "$U" -path "OU=hallgatok, DC=$dc_01, DC=$dc_02" -SamAccountName "$Sam" -UserPrincipalName "$princ" -AccountPassword $Password -GivenName $split[0]   -Surname $split[1] -DisplayName "$U" -Enabled $true
    Set-ADuser -Identity $Sam -replace @{msnpallowdialin=$true}
}

#Add User/s to Oktatok OU
$Oktatok_U =@("Trainer","Tomi","Gé Tomi")
foreach ($O in $Oktatok_U) {
    
    $Sam = $O.replace(" ",'.').ToLower()
    $princ = "$O"+"`@$Domain"
    $split = $O.split(" ")
    New-ADUser -Name "$O" -path "OU=oktatok, DC=$dc_01, DC=$dc_02" -SamAccountName "$Sam" -UserPrincipalName "$princ" -AccountPassword $Password -GivenName $split[0]   -Surname $split[1] -DisplayName "$O" -Enabled $true
    Set-ADuser -Identity $Sam -replace @{msnpallowdialin=$true}
}

#Add Trainer to Domain Admins Group
Add-ADGroupMember -Identity "Domain Admins" -Members Trainer
Add-ADGroupMember -Identity "Domain Admins" -Members Ati

#Add new ADGroups
New-ADGroup -Name "oktatok" -SamAccountName "oktatok" -GroupScope DomainLocal -DisplayName "Oktatók" -Path "OU=csoportok,DC=$dc_01,DC=$dc_02"
New-ADGroup -Name "hallgatok" -SamAccountName "hallgatok" -GroupScope DomainLocal -DisplayName "Hallgatók" -Path "OU=csoportok,DC=$dc_01,DC=$dc_02"

#Add users to ADGroups
Add-ADGroupMember -Identity hallgatok -Members "gipsz.jakab","beton.bela"
Add-ADGroupMember -Identity oktatok -Members "trainer"

 }

#BugFix for Shared Folder https://windowsreport.com/folder-doesnt-map/

Install-WindowsFeature GPMC 

#Create GPO
New-GPO -Name "FLO"

#Link GPO
New-GPLink -Name "FLO" -Target "dc=$dc_01,dc=$dc_02" 

#Download GPO
wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt/main/Gpo.zip -OutFile c:\Gpo.zip

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip "C:\Gpo.zip" "C:\"

Import-GPO -BackupGpoName FLO -Path "C:\Gpo" -TargetName FLO

Remove-Item -Recurse -Force C:\Gpo
del c:\manifest.xml
#Import Shared-Folders GPO

#Create GPO
New-GPO -Name "Shared-Folders"

#Link GPO
New-GPLink -Name "Shared-Folders" -Target "dc=$dc_01,dc=$dc_02" 

#Download GPO
wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt/main/Gpo2.zip -OutFile c:\Gpo2.zip

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip "C:\Gpo2.zip" "C:\"

Import-GPO -BackupGpoName Shared-Folders -Path "C:\Gpo" -TargetName Shared-Folders

Remove-Item -Recurse -Force C:\Gpo

#Cleanup
del C:\Gpo.zip
del C:\Gpo2.zip
del c:\manifest.xml

Stop-Transcript