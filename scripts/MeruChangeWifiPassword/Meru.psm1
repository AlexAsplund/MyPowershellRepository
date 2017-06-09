#Av Alex Asplund
Import-Module Posh-SSH


function Get-RandomPassword
{
	
	Write-Verbose "Generating password."
	$refStr1 = ("A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "X", "Y", "Z")
	$refStr2 = ("A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "X", "Y", "Z").ToLower()
	$refStr3 = ("2", "3", "4", "5", "6", "7", "8", "9")
	$refStrComplete = $refStr1 + $refStr2 + $refStr3
	$PwComplete = (($refStrComplete | Get-Random -Count 6) -join "") + ($refStr1 | Get-Random) + ($refStr2 | Get-Random) + ($refStr3 | Get-Random)
	return $PwComplete
	
	
}

<#
.Synopsis
   Loggar in på WLAN-Controllern och startar/deaktiverar ett ESS.
.DESCRIPTION
   Loggar in på WLAN-Controllern och startar/deaktiverar ett ESS.
   Kräver POSH-SSH (importerar från våran share ovan, men se till att användarkontot som kör detta har rättighet att komma åt den katalogen.
.EXAMPLE
   Set-WLCNet -Essid name_of_essid -Enable $True -Computername <ip till wlan-controller> -Credentials $Creds
.EXAMPLE
   Set-WLCNet -Essid name_of_essid -Enable $False -Computername <ip till wlan-controller> -Credentials $Creds
#>
function Set-WLCNet
{
    [CmdletBinding()]
    
    Param
    (
        # Namn på ESSID
        [Parameter(Mandatory=$true)]
        $Essid,

        # $True eller $False beroende på om man vill enabla eller disabla...
        [Parameter(Mandatory=$true)]
        $Enable,
        
        #Credentials, ett credentials prompt kommer upp om det inte refererar till något vettigt.
        #Credentials kan automatiskt läggas in av scriptet ovan.
        [Parameter(Mandatory = $true)]
		$Credential,
        [Parameter(Mandatory = $true)]
		$Computername
		
    )

    Begin
    {


        #Börja med att skapa en anslutning via SSH till MERU wlan-controller.
        $connection = New-SSHSession -ComputerName $Computername -Credential $Credential -AcceptKey
		$session = Get-SSHSession -Index 0
		$stream = $session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
        
        $Commando = ""
        #Forma kommandot
        if ($Enable -eq $true) {
        $Commando = "enable"
        }
        if ($Enable -eq $false) {
            $Commando = "disable"
        }

    }
    Process
    {
        
        $stream.Write("configure terminal`n")
        start-sleep 1
        $stream.Write("essid $Essid`n")
        Start-Sleep 1
        $stream.Write("$Commando`n")
        Start-Sleep 1
        $stream.Write("end`n")
        start-sleep 1
        
    }
    End
    {
        $VerboseOut = $stream.read()
        #Ta bort skräp, avsluta SSH-sessionen
        $trash = Remove-SSHSession 0
        Write-Verbose $VerboseOut
    }
}

<#
.Synopsis
   Loggar in på WLAN-Controllern och ändrar lösen på vald säkerhetsprofil.
.DESCRIPTION
   Loggar in på WLAN-Controllern och ändrar lösen på vald säkerhetsprofil.
   Kräver POSH-SSH (importerar från våran share ovan, men se till att användarkontot som kör detta har rättighet att komma åt den katalogen.
.EXAMPLE
   Set-WLCWpaKey -SecurityProfile name_of_secprof -NewPassword <new-password> -Computername <ip till wlan-controller> -Credentials $Creds
.EXAMPLE
   Set-WLCWpaKey -SecurityProfile name_of_secprof -NewPassword <new-password> -Computername <ip till wlan-controller> -Credentials $Creds
#>
function Set-WLCWpaKey
{
    [CmdletBinding()]
    
    Param
    (
        # Namn på säkerhetsprofil
        [Parameter(Mandatory=$true)]
        $SecurityProfile,

        # $True eller $False beroende på om man vill enabla eller disabla...
        [Parameter(Mandatory=$true)]
        $NewPassword,
        
        #Credentials, ett credentials prompt kommer upp om det inte refererar till något vettigt.
        #Credentials kan automatiskt läggas in av scriptet ovan.
        [Parameter(Mandatory = $true)]
		$Credential,

        #IP eller hostnamn till wlan-controller...
        [Parameter(Mandatory = $true)]
		$Computername
		
    )

    Begin
    {


        #Börja med att skapa en anslutning via SSH till MERU wlan-controller.
        $connection = New-SSHSession -ComputerName $Computername -Credential $Credential -AcceptKey
		$session = Get-SSHSession -Index 0
		$stream = $session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)

    }
    Process
    {
        
        $stream.Write("configure terminal`n")
        start-sleep 1
        $stream.Write("security-profile $SecurityProfile`n")
        Start-Sleep 1
        $stream.Write("psk key $NewPassword`n")
        Start-Sleep 1
        $stream.Write("end`n")
        start-sleep 1
        
    }
    End
    {
        $VerboseOut = $stream.read()
        #Ta bort skräp, avsluta SSH-sessionen
        $trash = Remove-SSHSession 0
        Write-Verbose $VerboseOut
    }
}