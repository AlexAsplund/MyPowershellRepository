$EvernoteMailAdress = "yourevernotemail@m.evernote.com"
$YourMailAddress = "test@contoso.com"
$TargetFolderName = "NameOfFolderToMoveMailItemToAfterProcessing"


Add-Type -assembly "Microsoft.Office.Interop.Outlook"
$Outlook = New-Object -comobject Outlook.Application

$myNameSpace = $Outlook.GetNamespace("MAPI") 
$Account = $myNameSpace.Folders | ? { $_.Name -eq $YourMailAddress };
$TargetFolder = ($Account.Folders | ? {$_.name -eq $TargetFolderName})

$Outlook.ActiveExplorer().Selection | foreach {

    $SelectedItem = $_
    $MoveItem = $SelectedItem.Move($TargetFolder)

    $MoveItem.UnRead = $false

    $EntryID = $MoveItem.EntryID

    $ForwardItem = $MoveItem.Forward()

    $ForwardItem.Recipients.Add($EvernoteMailAdress)
    $ForwardItem.HTMLBody = '<a href="outlook:'+ $EntryID + '">Link to message<a/> <br /> <hr />' + $MoveItem.HTMLBody
    $ForwardItem.Send()

}