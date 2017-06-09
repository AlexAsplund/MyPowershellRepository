$DaysThreshold =30
$Certificates = Get-ChildItem Cert:\Localmachine\my -Recurse | where { $_.notafter -le (get-date).AddDays($DaysThreshold) -AND $_.notafter -gt (get-date)} | select thumbprint, subject,notbefore,notafter
$CertCount = ($Certificates | Measure-Object).count
if($CertCount -ge 1)
{
    
   Write-Host $Certificates
   Write-Host "THE FOLLOWING CERTIFICATES ARE ABOUT TO EXPIRE. Please renew."
   EXIT 1001

}

if($CertCount -eq 0)
{

    EXIT 0

}