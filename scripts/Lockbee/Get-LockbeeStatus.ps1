 #Define variables
    $BasePath = "C:\ProgramData\Avtre\Lockbee\"
    #Since programdata does not exist on windows server 2003 etc:
    $OSName = (Get-WmiObject -class win32_operatingsystem).caption
    if($OSName -match "Server 2003")
    {
     
        $BasePath = "C:\Documents and Settings\All Users\Application Data\Avtre\Lockbee\"
     
    }
    $SyncLogPath = $BasePath+"SynchReports.xml"
    $MonitorStatus = $BasePath+"Monitor.xml"
     
    ####
    #Error codes
    # 1001 = Failed to load log file
    # 1002 = "Failed to read XML file
    # 1003 = 
    # 1010 = "Previous sync job failed"
    # 1013 = "Monitoring failed"
    # 1014 = "Service not running"
    #
    ####
    $StatusList = @("busy","idle")
    $date = (get-date).AddDays(-1)
    $date = $date | get-date -Format "yyyy-MM-dd"
    try {
        [xml]$XML = Get-Content $SyncLogPath
    }
    catch
    {
        Write-Host "Failed to read sync XML log"
        Exit 1001
    }
    try
    {
        $FilteredXML = $XML.reportList.report | ? {$_.starttime -match $date}
        [int]$FailedSyncs = ($FilteredXML.section.results.result | ? {$_.description -match "Misslyckade"}).value
    }
    catch
    {
        write-host "Failed to read XML"
        exit 1002
    }
     
    if($FailedSyncs -ne 0)
    {
        write-host "One or more files in the synchronization failed ($FailedSyncs)"
        exit 1010
    }
     
    try {
     
        [XML]$MonitorXml = Get-Content $MonitorStatus
        $Monitor = $MonitorXml.monitorstatus.status
     
        if($StatusList -notcontains $Monitor)
        {
            write-host "Lockbee is in an unknown state! ($Monitor)"
           exit 1013
     
        }
    }
    catch
    {
        write-host "Could not read or parse monitor status"
     
    }
     
    try
    {
        $ServiceStatus = (Get-Service LockbeeMonitor).Status -eq "Running"
    }
    catch
    {
        write-host "The lockbee monitoring service is not installed on this computer - Is Lockbee installed at all?"
        exit 1014
     
    }
    if(!$ServiceStatus)
    {
        write-host "Lockbee Monitoring services is not running!"
        exit 1014
    }
     
    Write-Host "OK - $Monitor"
    exit 0