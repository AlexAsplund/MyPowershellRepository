#Enable Wifi on ESSID
Param(
  [string]$SecurityProfile,
  [string]$Username,
  [string]$Password,
  [string]$MailPasswordTo
  [string]$CCEmail
  [string]$Wlancontroller
)

Import-Module Meru
$secpasswd = ConvertTo-SecureString "$Password" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential ("$Username", $secpasswd)
$NewWPAPassword = Get-RandomPassword
Set-WLCWpaKey -SecurityProfile $SecurityProfile -NewPassword $NewWPAPassword -Credential $creds -Computername $wlancontroller


$Message = @"
Hi,

The new password for wifi is:

$NewWPAPassword

"@

Send-MailMessage -Body $Message -Cc $CCEmail -From NoReply_WifiAutomation@domain.com -To $MailPasswordTo -Subject "The new password for wifi is: $NewWPAPassword" -SmtpServer smtpserver.contoso.com -Encoding UTF8