<#
.Synopsis
   Flyttar alla VM's från en host och balanserar det ut på övriga hostar.
.DESCRIPTION
   Flyttar alla VM's från en host och balanserar det ut på övriga hostar. Kollar på ram-användningen.
.EXAMPLE
   Move-AllVMsFromHost -MoveFromHost esxiserver11.domain.example.com
#>
function Move-AllVMsFromHost
{
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $MoveFromHost
    )

    Begin
    {
    
        $VMOnHost = Get-VM |select name, vmhost, PowerState| ? {($_.VMHost -match $MoveFromHost) -and ($_.PowerState -ne "PoweredOff")}
        $ErrorActionPreference = "Break"   
    }
    Process
    {
        $VMOnHost | foreach -Process {
            #Vm namn
            $VMName = $_.name
            #VMHost som har minst minnesanvändning (det är denna vi kommer att migrera till)
            Write-Verbose "Analyserar hostar och väljer den med minst minne"
            $LeastUsedHost = (Get-VMHost | ? {$_.name -ne $MoveFromHost} | Sort-Object MemoryUsageGB)[0]
            
            #Flytta VM till den minst använda hosten
            Write-Verbose "Valet blev $LeastUsedHost"
            Write-Verbose "Migrerar VM: $vmname FRÅN $MoveFromHost TILL $LeastUsedHost"
            Get-VM -Name ($_.name) | Move-VM -Destination ($LeastUsedHost)


        }
    }
    End
    {
        Write-Verbose "Kollar om alla virituella maskiner har flyttats"

        #Kolla om det finns några påslagna maskiner kvar på hosten. Varna om så är fallet.
        $VMcount = Get-VM | ? {($_.VMHost -match $MoveFromHost) -and ($_.PowerState -eq "PoweredOn")} | Measure-Object
        if (($VMcount.Count) -gt 0) {
            Write-Warning "Alla virituella maskiner har inte flyttats eller har blivit påslagna under processen, var god rätta till detta."
        }
        Write-Verbose "The following VM's were moved:"
        return $VMOnHost
    }
}