
$Title = '[V04] Azure Deployment '

    Clear-Host
    Write-Host "======= $Title =======`r`n" -ForegroundColor Green
    
    Write-Host "1: Press '1' for Deploy DC1 (WS 2019 Active Directory Domain Controller - project.local )"
    Write-Host "2: Press '2' for Deploy FS1 (Windows Server 2019 Core - File Server)" 
    Write-Host "3: Press '3' for Deploy Windows 10 Client (21H2-Pro)"
    Write-Host "4: Press '4' for Deploy Windows 11 Client (21H2-Pro)"
    Write-Host "5: Press '5' for Auto Deploy (DC1 + FS1 + W10 Client)`r`n" -ForegroundColor Red
    Write-Host "Q: Press 'Q' to quit.`r`n"

$menu = Read-Host "What you want to do?"

switch ($menu)
 {
     '1' {
        ./01.ps1
     } '2' {
        ./02.ps1
     } '3' {
        ./03.ps1
     } '4' {
        ./04.ps1
     } '5' {
      ./auto_deploy.ps1
     }
     'q' {
         return
     }
 }