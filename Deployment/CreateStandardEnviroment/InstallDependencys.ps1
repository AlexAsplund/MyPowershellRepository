#Av Alex Asplund

#Installera Dependencys för att kunna installera AD.

$VerbosePreference = "Continue"
Write-Verbose "[+]Installerar PackageManagement"
.\PackageManagement_x64.msi /passive
Write-Verbose "Väntar i 5 sekunder på PackageManagement"
Start-Sleep 5
Install-Module xActiveDirectory,xComputerManagement,cDFS -Force