#Enable Wifi on ESSID
Param(
  [string]$Essid,
  [string]$Username,
  [string]$Password,
  [bool]$Enable
)
Import-Module Meru
$secpasswd = ConvertTo-SecureString "$Password" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential ("$Username", $secpasswd)
Set-WLCNet -Essid $Essid -Enable $Enable -Credential $creds -Computername wlancontrollse