#Av: Alex Asplund
#############################################################################################################################
#    Inställningar
#############################################################################################################################
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

$DFSServerName = $config.DFSServerHostName
$DomainName = $config.AD_DomainName

#Definiera vart DFSRooten ska ligga
#BP är inte att lägga den på C:\

$DfsRootDir = $config.DFSRootDir
$DfsFileDir = $config.DFSFileDir
#Sitename är Mappen i $DfsFileDir
$DFSSiteName = ($DfsFileDir -split "\\")[-1]


#Definera mappar som skall vara utdelade från början.
#Man ska inte lägga den på C:\ enligt BP.
$BaseShareDir = $config.DFSBaseShareDir
$Shares = $config.DFSShares

$FullComputerName = ($DFSServerName+"."+$DomainName)

if ((Get-WmiObject win32_computersystem).partofdomain -eq $false)
{
    try
    {
        Add-Computer -DomainCredential (Get-Credential $DomainName\) -DomainName $DomainName -NewName $DFSServerName -Restart -Force
    }
    catch
    {
        Write-Error $_
        break
    }
}

Install-WindowsFeature FS-DFS-Namespace, FS-DFS-Replication -ComputerName $FullComputerName

Install-WindowsFeature RSAT-DFS-Mgmt-Con


$argumentlist = @{
    sharename=$sharename
    shares=$shares
    BaseShareDir = $BaseShareDir
    DfsRootDir = $DfsRootDir
    DFSFileDir = $DfsFileDir
}
Invoke-Command -ComputerName $FullComputerName -ArgumentList $argumentlist -ScriptBlock {
    param($argumentlist)

    $Shares_ = $argumentlist.Shares
    $sharename_ = $argumentlist.Sharename
    $BaseShareDir_ = $argumentlist.Basesharedir
    $DfsRootDir_ = $argumentlist.DfsRootDir
    $DfsFileDir_ = $argumentlist.DfsFileDir

    Write-Host $BaseShareDir_
    mkdir -path $BaseShareDir_ -Force
    mkdir -Path $Shares_ -Force
    mkdir -Path $DfsRootDir_ -Force 
    mkdir -Path $DfsFileDir_ -Force
    $Shares_ | ForEach-Object {$sharename_ = (Get-Item $_).name; New-SMBShare -Name $sharename_ -Path $_ -FullAccess "Domain Users"}
    $DF = Get-Item $DfsFileDir_
    New-SmbShare -Name $df.Name -Path $DfsFileDir_ -FullAccess "Domain Users" 

}

New-DfsnRoot -Path "\\$DomainName\$DFSSiteName" -TargetPath "\\$FullComputerName\$DFSSiteName" -Type DomainV2

$shares | Where-Object {$_ -like "*shares*"} | ForEach-Object {

    $name = (Get-Item $_).name
    $DfsPath = ("\\$DomainName\$DFSSiteName\" + $name)
    $targetPath = ("\\$FullComputerName\" + $name)
    New-DfsnFolderTarget -Path $dfsPath -TargetPath $targetPath
}