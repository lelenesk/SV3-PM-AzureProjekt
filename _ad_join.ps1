param(

     [Parameter()]
     [string]$Password,
 
     [Parameter()]
     [string]$Admin,

     [Parameter()]
     [string]$Domain

 )

$userPassword = $Password
$userName = "$Admin@$Domain"

$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName,$secStringPassword

Add-Computer -DomainName $Domain -DomainCredential $Credential -Restart -Verbose