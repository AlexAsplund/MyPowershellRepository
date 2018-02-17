param(

    [Parameter(Mandatory=$True,Position=0)]
    [Array]$ComputerName,
    [Parameter(Mandatory=$True,Position=1)]
    [String]$OutFile,
    [Parameter(Position=2)]
    [PSCredential]$Credential

)

$ScriptBlock = {

    $WMIOperatingSystem = Get-WmiObject win32_OperatingSystem
    $WindowsCaption = $WMIOperatingSystem.Caption
    $WindowsVersion = $WMIOperatingSystem.Version

    $Session = New-Object -ComObject Microsoft.Update.Session
    $Searcher = $Session.CreateUpdateSearcher()
    $Results = $Searcher.Search("IsInstalled = 1")



    $WU = $Results.Updates | select Title,KBArticleIDs


    $QuickFixes = Get-WmiObject -Class Win32_QuickFixEngineering | Select HotFixID,InstalledOn

    $ComputerInfo = @{

        ComputerName = $env:COMPUTERNAME
        FetchedOnDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        OperatingSystemCaption = $WindowsCaption
        OperatingSystemVersion = $WindowsVersion

        UpdatesInstalled = $WU
        QuickFixes = $QuickFixes


    }
    return $ComputerInfo
}

if($Credential -ne $null){

    $CredentialSplat = @{
    
        Credential = $Credential

    }

}
else {

    $CredentialSplat = @{}

}


$Job = Invoke-Command -ComputerName $ComputerName -AsJob -JobName WindowsUpdateFetch -ScriptBlock $ScriptBlock @CredentialSplat

$Job | Wait-Job

$JobResult = $Job | Receive-Job

$JobResult | ConvertTo-Json | Out-File -FilePath $OutFile
