####################################################################
#    DSC-Configuration för ny domänkontroller.
#    Anpassad för core-installation.
####################################################################

$Config = (Get-Content ..\Config.inf -Raw | ConvertFrom-Json)

$secpasswd = ConvertTo-SecureString $Config.AD_SafemodePassword -AsPlainText -Force
$SafeModePW = New-Object System.Management.Automation.PSCredential ('guest', $secpasswd)
 
$secpasswd = ConvertTo-SecureString $Config.AD_LocalAdminPassword -AsPlainText -Force
$localuser = New-Object System.Management.Automation.PSCredential ('guest', $secpasswd)

$FirstDomainAdminPasswordSec = ConvertTo-SecureString $Config.AD_DomainAdminPassword -AsPlainText -Force
$DomainAdminCredentials = New-Object System.Management.Automation.PSCredential ($Config.AD_DomainAdminUsername, $secpasswd) 
 
configuration StandardADEnviroment
{ 
     param
    ( 
        [string[]]$NodeName ='localhost', 
        [Parameter(Mandatory)][string]$MachineName, 
        [Parameter(Mandatory)][string]$DomainName,
        [Parameter()]$firstDomainAdmin,
        [Parameter()][string]$UserName,
        [Parameter()]$SafeModePW,
        [Parameter()]$LocalAdminRealName,
        [Parameter()]$LocalAdminDescription,
        [Parameter()]$Password
    )     

    #Import the required DSC Resources  
    Import-DscResource -Module xComputerManagement 
    Import-DscResource -Module xActiveDirectory
   
    Node $NodeName
    { #ConfigurationBlock 

        xComputer NewNameAndWorkgroup 
        { 
            Name          = $MachineName
            WorkgroupName = 'TESTLAB'
             
        }
          
          
        User LocalAdmin {
            UserName = $UserName
            Description = $LocalAdminDescription
            Ensure = 'Present'
            FullName = $LocalAdminRealName
            Password = $Password
            PasswordChangeRequired = $false
            PasswordNeverExpires = $true
            DependsOn = '[xComputer]NewNameAndWorkGroup'
        }
  
        Group AddToAdmin{
            GroupName='Administrators'
            DependsOn= '[User]LocalAdmin'
            Ensure= 'Present'
            MembersToInclude=$UserName
  
        }
 
        WindowsFeature ADDSInstall 
        { 
            DependsOn= '[Group]AddToAdmin'
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
            IncludeAllSubFeature = $true
        }
         
        xADDomain SetupDomain {
            DomainAdministratorCredential= $firstDomainAdmin
            DomainName= $DomainName
            SafemodeAdministratorPassword= $SafeModePW
            DependsOn= '[WindowsFeature]ADDSInstall'
            DomainNetbiosName = $DomainName.Split('.')[0]
        }

    #End Configuration Block    
    } 
}
 
$configData = 'a'
 
$configData = @{
                AllNodes = @(
                              @{
                                 NodeName = 'localhost';
                                 PSDscAllowPlainTextPassword = $true
                                 RebootNodeIfNeeded = 'True'
                                    }
                    )
               }
 
 
StandardADEnviroment -MachineName $Config.AD_Machinename -DomainName $Config.AD_DomainName -Password $localuser `
    -UserName $Config.AD_LocalAdminUsername -SafeModePW $SafeModePW -LocalAdminRealName = $Config.AD_LocalAdminRealName `
    -LocalAdminDescription $Config.AD_LocalAdminDescription -firstDomainAdmin $DomainAdminCredentials -ConfigurationData $configData
  
Start-DscConfiguration -ComputerName localhost  -Wait -Force -Verbose -path .\StandardADEnviroment -Debug