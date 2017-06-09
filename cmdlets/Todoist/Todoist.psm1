﻿$APIUri = "https://todoist.com/API/v7/sync"
$ProjectName = 'POSHDoist'

<#
.Synopsis
   Initiate todoist with your APIToken
.DESCRIPTION
   Sets a global variable for the APIToken
.EXAMPLE
   Set-TodoistAPIToken -APIToken
#>
function Set-TodoistAPIToken
{
    [CmdletBinding()]
    Param
    (
        # APIToken
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $APIToken
    )

    Begin
    {

        $Global:TodositAPIToken = $APIToken

    }
    Process
    {

        #Test the token with a sync
        try
        {

            $data = Get-TodoistResource -Resources all

        }
        catch
        {

            Write-Error "Could not set and test the APIToken, wrong token?"
            Write-Error $_

        }

    }
    End
    {

        Write-Verbose "ApiToken is set to $Global:TodositAPIToken"

    }
}

<#
.Synopsis
   Get-TodoistSync
   Gets all data from todoist
.DESCRIPTION
   Gets all data from todoist
.EXAMPLE
   Get-TodoistSync -resources "items","labels" -token $ApiToken
   Get-TodoistSync -resources "all" -token $ApiToken
#>
function Get-TodoistResource
{
    [CmdletBinding()]
    Param
    (
        #Type of resources to fetch: all, labels, projects,items, notes, filters, reminders, locations, user, live_notifications, collaborators, notification_settings
        [Parameter(Position=0)]
        [ValidateSet('labels','projects','items','notes','filters','reminders','locations','user','live_notifications','collaborators','notification_settings','all')]
        $Resources,
        # APIToken for todoist
        [Parameter(Position=1)]
        $APIToken
        
    )

    Begin
    {
        
        # See if global APIToken is overridden
        if($APIToken -eq $null){
            if($Global:TodositAPIToken -eq $null)
            {

                #No key!
                Write-Error "No apitoken was defined with either Set-TodoistApiToken or -APIToken! Terminating."
                break

            }

            $APIToken = $Global:TodositAPIToken

        }

        # Check resources
        if ($Resources.gettype().Name -notin "String","Object[]")
        {
        
            Write-Error "The type of -Resources is not system.object[] or String. exit"
            break

        }

        if ($Resources.gettype().Name -eq "String")
        {

            $ResourcesNew = '["' + $Resources + '"]'

        }
        if ($Resources.gettype().Name -eq "Object[]")
        {
            $ResourcesString = ($Resources -join '","') 
            $ResourcesNew = '["' + $ResourcesString + '"]'


        }


        # Build body


        $Body = @{

            token = $APIToken
            sync_token = "*"
           resource_types= $ResourcesNew

        }

    }

    Process
    {
        # Invoke restmethod to fetch data
        try
        {
            $request = Invoke-RestMethod -Method Post -body $Body -Uri $APIUri
        }
        catch
        {

            Write-Error "An error occured while requesting data from $APIUri"
            Write-Error $_

        }
    }

    End
    {

        return $request

    }
}

<#
.Synopsis
   Gets tasks from todoist
.DESCRIPTION
   Gets all tasks from todoist, can fetch by project name
.EXAMPLE
   Get-TodoistTask -Project Work
.EXAMPLE
   Get-TodoistTask
#>
function Get-TodoistTask
{
    [CmdletBinding()]
    Param
    (
        #TaskID
        [Parameter(Mandatory=$false)]
        $TaskID,
        # Project Name
        [Parameter(Mandatory=$false)]
        $Project,
        [Parameter(Mandatory=$false)]
        $Label
    )

    Begin
    {

        Write-Verbose "Fetching sync data from Todoist"

        if(($Project -or $Label) -ne $null){
            
            $data = Get-TodoistResource -Resources all
        }
        else
        {

           $data = Get-TodoistResource -Resources "items" 

        }


    }
    Process
    {

        if($Project -ne $null)
        {
            # Get project ID
            $Project = $data.projects | ? {$_.name -eq $Project}
            if($Project -eq $null){

                Write-Error "Project not found!"
                Break
            }

            #
            $ToReturn = $data.items | ? {$_.project_id -eq $Project.id}

        }

        if($Label -ne $null)
        {
            # Get project ID
            $Labels = $data.labels | ? {$_.name -eq $label}
            if($labels -eq $null){

                Write-Error "Label not found!"
                Break
          }else{

            $ToReturn = $data.items

        }
        }
            
        if($TaskID -ne $null)
        {
        
            $ToReturn = $data.items | ? {$_.id -eq $TaskID}
            
        }else{

            $ToReturn = $data.items

        }

    }
    End
    {

        return $ToReturn

    }
}

function New-Guid {

    return ([guid]::NewGuid()).guid

}

<#
.Synopsis
   Creates a new task in todoist.
.DESCRIPTION
   Creates a new task in todoist.
.EXAMPLE
   New-Task -Description "Get milk" -Project Personal
#>
function New-TodoistTask
{
    [CmdletBinding()]
    Param
    (
        # Content of the task
        [Parameter(Mandatory=$true)]
        [string]
        $TaskContent,

        # Project name
        [string]
        $ProjectName
    )

    Begin
    {

        # See if global APIToken is overridden

        $Resource = Get-TodoistResource -Resources "projects"

        if($ProjectName -ne $null){
            
            
            $ProjectID = ($Resource.projects | ? {$_.name -eq $ProjectName}).id
            
            

        }
        else
        {

            $ProjectID = ($Resource | ? {$_.projects.inbox_project -eq "true"}).id

        }

    }
    Process
    {

        $UUID = New-Guid
        $temp_id = New-Guid
        $Command = @"
        [{
            "type":  "item_add",
            "temp_id":  "$temp_id",
            "uuid":  "$UUID",
            "args":  {
                         "content":  "$TaskContent",
                         "project_id":  $ProjectID
                     }
        }]
"@


        
        $body = @{

            token = $Global:TodositAPIToken
            commands = $Command
            
            }

        # Invoke restmethod to fetch data
        try
        {
            $request = Invoke-RestMethod -Method Post -Body $Body -Uri $APIUri -Verbose
        }
        catch
        {

            Write-Error "An error occured while requesting data from $APIUri"
            Write-Error $_

        }



    }
    End
    {

        return $request

    }
}

<#
.Synopsis
   Updates task in todoist.
.DESCRIPTION
   Updates task in todoist.
.EXAMPLE
   Update-TodoistTask -Content "Get milk" -Project Personal
#>
function Update-TodoistTask
{
    [CmdletBinding()]
    Param
    (
        # Content of the task
        [Parameter(Mandatory=$true)]
        $TaskID = "",

        #Pass task object instead of ID.
        $TaskObject = "",
        
        #Task content
        $Content = "",
        
        #Must be UTC and have format: 2012-3-24T23:59
        $DueDate = "",
        
        #An array of INT, will replace the already existing labels so be careful
        $Labels = "",
        
        #Will add labels, int array! to get label id use Get-TodoistResource -resource labels
        $AddLabels = ""
    )

    Begin
    {
        if($TaskID -ne "")
        {
            $TaskItem = (Get-TodoistResource -Resources items).items | ? {$_.id -eq $TaskID}
        }
        if($TaskObject -ne "")
        {

            $TaskItem = $TaskObject

        }
        # Add labels from $AddLabels if its not null
        if($AddLabel -ne ""){

            $AddLabels | foreach {

                $TaskItem.labels += " " + $_

            }

        }

        # Add new due date if its not null
        
        if($DueDate -ne ""){
            
            if($DueDate -notmatch "\d\d\d\d-\d{1,2}-\d{1,2}T\d\d:\d\d")
            {
             
             Write-Error "Due date does not match format: 2012-3-24T23:59"
                
            }
            else
            {
                $TaskItem.due_date_utc = $DueDate
            }

        }
        if($Content -ne "")
        {

            $TaskItem.Content = $Content
            Write-Verbose $TaskItem

        }


    }
    Process
    {

        $UUID = New-Guid
        $TaskItemToJson = $TaskItem | ConvertTo-Json
        $Command = @"
        [{
            "type":  "item_update",
            "uuid":  "$UUID",
            "args":  $TaskItemToJson
        }]
"@
        Write-Verbose $TaskItemToJson
        $body = @{

            token = $Global:TodositAPIToken
            commands = $Command
            
            }


        # Invoke restmethod to fetch data
        try
        {
            $request = Invoke-RestMethod -Method Post -Body $Body -Uri $APIUri -Verbose
        }
        catch
        {

            Write-Error "An error occured while requesting data from $APIUri"
            Write-Error $_

        }



    }
    End
    {

        Write-Verbose $request

    }
}

function Convert-DateToTodoistDate($date)
{

    return $date | Get-Date -Format "yyyy-M-dThh:mm"

}