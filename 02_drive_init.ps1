Start-Transcript -Path "C:\Logs\02_drive_init.txt"

#Drive Data Setup   
$Driver_letter="S"

#Get Disk id
$Disks = Get-Disk
$Disk_id = $Disks[-1].Number

#Initialize Disk
Get-Disk -Number $Disk_id | Initialize-Disk -PartitionStyle GPT

#Create New Partition
New-Partition -DiskNumber $Disk_id -Driveletter $Driver_letter -UseMaximumSize

#Format
Format-Volume -DriveLetter $Driver_letter -FileSystem NTFS -AllocationUnitSize 65536 -Confirm:$false

#Wait for it ... :)
Stop-Transcript