#Av Alex Asplund
$VerbosePreference = "Continue"
#V0.1
##########################################################################
#    Skapa OU-Design efter microsoft type-based best-practice med lite modifikation för verkligheten.
#    Bäst lämpad för singel site
#    Lägger även in ett adminkonto med fulla behörigheter.
##########################################################################'
try
{
    $Config = (Get-Content ..\Config.inf -Raw | ConvertFrom-Json)
}
catch
{

    Write-Error "KUNDE INTE IMPORTERA INSTÄLLNINGAR"
    Write-Error $_
    break

}
#####################################################################################
#KÖR SOM DOMÄNADMIN PÅ EN DATOR SOM INTE ÄR DC

#Installera RSAT
Write-Verbose "Hämtar status på RSAT-modulen"
if((Get-WIndowsFeature RSAT).Installed -ne $True)
{
    Install-WindowsFeature RSAT
}
Else
{
    Write-Verbose "RSAT redan installerat, hoppar över..."
}

#Sätt vilket domän som skall användas (obs, datorn måste vara med i domänen)
$Domain = $env:USERDNSDOMAIN

##########################################################################
$UserDNSDomain = $env:USERDNSDOMAIN -split "\."
#get domain
$DC0 = $UserDNSDomain[0]
$DC1 = $UserDNSDomain[1]
$DC2 = $UserDNSDomain[2]

Write-Verbose "Börjar skapa OU"
#Tugga OU'n
try
{
New-ADOrganizationalUnit "Accounts" -Path "DC=$DC0,DC=$DC1,DC=$DC2"
    New-ADOrganizationalUnit "Users" -Path "OU=Accounts,DC=$DC0,DC=$DC1,DC=$DC2"
    New-ADOrganizationalUnit "Privileged" -Path "OU=Accounts,DC=$DC0,DC=$DC1,DC=$DC2"
    New-ADOrganizationalUnit "Service" -Path "OU=Accounts,DC=$DC0,DC=$DC1,DC=$DC2"
    New-ADOrganizationalUnit "Test" -Path "OU=Accounts,DC=$DC0,DC=$DC1,DC=$DC2"
    }
catch
{
    
    Write-Verbose "Ser ut som om att OU'n för Användare redan har skapats."

}

try
{
    New-ADOrganizationalUnit "Devices" -Path "DC=$DC0,DC=$DC1,DC=$DC2"
        New-ADOrganizationalUnit "Servers" -Path "OU=Devices,DC=$DC0,DC=$DC1,DC=$DC2"
        New-ADOrganizationalUnit "Printers" -Path "OU=Devices,DC=$DC0,DC=$DC1,DC=$DC2"
        New-ADOrganizationalUnit "Workstations" -Path "OU=Devices,DC=$DC0,DC=$DC1,DC=$DC2"
            New-ADOrganizationalUnit "Deployed" -Path "OU=Workstations,OU=Devices,DC=$DC0,DC=$DC1,DC=$DC2"
                New-ADOrganizationalUnit "Windows 7" -Path "OU=Deployed,OU=Workstations,OU=Devices,DC=$DC0,DC=$DC1,DC=$DC2"
                New-ADOrganizationalUnit "Windows 8" -Path "OU=Deployed,OU=Workstations,OU=Devices,DC=$DC0,DC=$DC1,DC=$DC2"
                New-ADOrganizationalUnit "Windows 10" -Path "OU=Deployed,OU=Workstations,OU=Devices,DC=$DC0,DC=$DC1,DC=$DC2"
            New-ADOrganizationalUnit "Manual" -Path "OU=Workstations,OU=Devices,DC=$DC0,DC=$DC1,DC=$DC2"
                New-ADOrganizationalUnit "Windows 7" -Path "OU=Manual,OU=Workstations,OU=Devices,DC=$DC0,DC=$DC1,DC=$DC2"
                New-ADOrganizationalUnit "Windows 8" -Path "OU=Manual,OU=Workstations,OU=Devices,DC=$DC0,DC=$DC1,DC=$DC2"
                New-ADOrganizationalUnit "Windows 10" -Path "OU=Manual,OU=Workstations,OU=Devices,DC=$DC0,DC=$DC1,DC=$DC2"

}
catch
{
    
    Write-Verbose "Ser ut som om att OU'n för Datorer redan har skapats."

}

#Skapa användare och lägg till i grupper
Write-Verbose "Skapar domänadmin."
Try
{
New-ADUser -AccountPassword ($Config.AD_DomainAdminPassword | ConvertTo-SecureString -AsPlainText -Force) -Company $comp -Country "SE" `
-Description $Config.AD_DomainAdminDescription -DisplayName $Config.AD_DomainAdminUsername -Enabled $true -Name $Config.AD_DomainAdminUsername `
-PasswordNeverExpires $true -SamAccountName $Config.AD_DomainAdminUsername -Title "Konsultkonto" -UserPrincipalName ($Config.AD_DomainAdminUsername+ "@" + $Domain) `
-Path "OU=Privileged,OU=Accounts,DC=$DC0,DC=$DC1,DC=$DC2"
}
catch
{
    
    Write-Warning "Kunde ej skapa domänadmin..."

}
try
{
    Get-ADGroup -Filter * | ? {$_.name -match "admins"} | Add-ADGroupMember -Members $Config.AD_DomainAdminUsername
}
catch
{
    Write-Warning "Kunde ej lägga till användaren i grupp."

}