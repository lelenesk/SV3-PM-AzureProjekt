param(
 
     [Parameter()]
     [string]$Domain,

     [Parameter()]
     [string]$Admin

 )
Start-Transcript -Path "C:\Logs\02_scripts.txt"

#Install FS-Resource-Manager
Install-WindowsFeature -Name FS-Resource-Manager -IncludeManagementTools

#Install Data-Deduplication
Install-WindowsFeature -Name FS-Data-Deduplication

#Creating Folders
$Driver_letter="S"


$folders=@("Hallgatok","Oktatok ","Vizsga","Users")
foreach ($folder in $folders) {
    New-item -itemtype Directory -path "S:\Shares\$folder"
}

#Creating SMB Shares
New-SmbShare -Name "hallgatok" -Path "S:\Shares\Hallgatok"
New-SmbShare -Name "oktatok" -Path "S:\Shares\Oktatok"
New-SmbShare -Name "vizsga" -Path "S:\Shares\Vizsga"

#SMB Grants

#hallgatok

Grant-SmbShareAccess -Name hallgatok -AccountName Administrators -AccessRight Full -force
Grant-SmbShareAccess -Name hallgatok -AccountName hallgatok -AccessRight Change -force

#Debug
Get-SmbShareAccess -Name hallgatok

#oktatok
Grant-SmbShareAccess -Name oktatok -AccountName Administrators -AccessRight Full -force
Grant-SmbShareAccess -Name oktatok -AccountName oktatok -AccessRight Change -force

#Debug
Get-SmbShareAccess -Name oktatok

#vizsga
Grant-SmbShareAccess -Name vizsga -AccountName Administrators -AccessRight Full -force
Grant-SmbShareAccess -Name vizsga -AccountName hallgatok -AccessRight Change -force
Grant-SmbShareAccess -Name vizsga -AccountName oktatok -AccessRight Read -force

#Debug
Get-SmbShareAccess -Name vizsga

#Create Users Folder Base Share
New-SmbShare -Name "Home" -Path "S:\Shares\Users"
Grant-SmbShareAccess -Name Home -AccountName Administrators -AccessRight Full -force
Grant-SmbShareAccess -Name Home -AccountName hallgatok -AccessRight Full -force
Grant-SmbShareAccess -Name Home -AccountName oktatok -AccessRight Full -force


##Install AD Services + ManagementTools for Powershell modules
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

#Create home folders + Enable Quota
$names = Get-ADUser -Filter * | Select-Object -ExpandProperty SamAccountName

#Creating Quota Template 
New-FsrmQuotaTemplate -Name "Home-Folders" -Description "Limit usage to 500 MB" -Size 500MB -Threshold (New-FsrmQuotaThreshold -Percentage 90)

foreach ($name in $names) {
    New-item -itemtype Directory -path S:\Shares\Users\$name
    $path = "S:\Shares\Users\" +$name
    New-FsrmQuota -Path $path -Description "Limit usage to 500 MB" -Template "Home-Folders"
}

#Add NTFS ACL Rights
foreach ($name in $names) {
    $acl = Get-Acl -Path S:\Shares\Users\$name
    $ace = New-Object System.Security.Accesscontrol.FileSystemAccessRule ("$name", "Full", "Allow")
    $acl.AddAccessRule($ace)
    Set-Acl -Path S:\Shares\Users\$name -AclObject $acl
}

#Create SMB Shares
foreach ($name in $names) {
New-SmbShare -Name $name -Path S:\Shares\Users\$name
Grant-SmbShareAccess -Name $name -AccountName $name -AccessRight Full -force
}

Stop-Transcript