#requires -Version 1
#=============================================
<#
        Script Name: UdiApplicationList.ps1
        Created: 08/04/2015
        Author: Asbjørn Sørensen
        Company: TDCH
        Email: ambs@tdchosting.dk / cm@tdchosting.dk
        Web: 
        Reqrmnts: .net Framework
        Keywords: Add, update remove application from UDI.
    
#>
#==============================================

# Purpose:
#==============================================
<# 

        RightclickTool that enables you to edit the UDI Application list from the
        SCCM console. 

        Features:
        1. Add new Application - Adds one Application to one Application group. 

        2. Update dependant name values for all instances of the application in the list.
        eg. the name of the package have changed. 

        3. Remove all instanes of the marked application from the Aplicaiton list. 

        4. Check for any consistency issues in application list. 
        Checks for:
        -Dublicate application ID's
        -Application Name mismatch
        -Expired Applications
        -Auto install set to true (Allow application to be run from task sequence)

        Examples.

        Add new Application to a list group. 
        UdiApplicationList.ps1 -ModelName ##SUB:ModelName## -New

        Update Application in all list groups
        UdiApplicationList.ps1 -ModelName ##SUB:ModelName## -Update

        Remove Application from all list groups
        UdiApplicationList.ps1 -ModelName ##SUB:ModelName## -Delete

        Check Application List
        UdiApplicationList.ps1 -Check

#>
#==============================================

#==============================================
#  SCRIPT BODY
#==============================================

[cmdletbinding()]

PARAM (
    [STRING]$ModelName,
    [SWITCH]$New,
    [SWITCH]$Update,
    [SWITCH]$Delete,
    [SWITCH]$Check

)
#==============================================
#  DEFAULT VALUES
#==============================================

#SCCM Servername
$SMSServer = ''

#Backup path for 'UDIWizard_Config.xml.app'
$BackupDir = ''

#Path to 'UDIWizard_Config.xml.app'
$XMLPath = 'C:\Users\ambs\OneDrive for Business\Git\CM12\Tools\Add2UdiApplistFromConsoleContextMenu\UDIWizard_Config.xml.app'

#==============================================
#  DEFAULT VALUES END
#==============================================


Try
{
    #Load -net assemblies.
    [void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    [void] [System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') 

    #Get app that have been marked in SCCM client center.    
    $FoundApp = Get-WmiObject -Namespace 'Root\SMS\Site_PS1' -Class SMS_ApplicationLatest -Filter "ModelName='$ModelName'" -ComputerName $SMSServer -ErrorAction Stop

    #Get XML containing Apps
    [XML]$CurrentApplicationlist = Get-Content $XMLPath -Force -ErrorAction Stop

    #Backup Current XML File
    $Date = (Get-Date -DisplayHint Date -Format s).Replace(':','-')
    $BackupFileName = "$BackupDir\$Date"+'_'+'UDIWizard_Config.xml.app'
    Copy-Item $XMLPath -Destination $BackupFileName -ErrorAction Stop
}
Catch 
{
    $MsgError = $_
            
    $MsgErrorLine = $_.InvocationInfo.ScriptLineNumber
                     
    $oReturn = ,
    [System.Windows.Forms.MessageBox]::Show("$MsgError `nLine: $MsgErrorLine", 
        'Error', [System.Windows.Forms.MessageBoxButtons]::OK, 
    [System.Windows.Forms.MessageBoxIcon]::exclamation)

    switch ($oReturn){
        'OK' 
        {
            Exit
        }
    }
}

#Add a new application to a specific subgroup. 
If ($New -eq $true)
{
    $FoundApp.get()
    [XML]$FoundAppXML = $FoundApp.SDMPackageXML
    #Checks

    #Check for expired App
    if ($FoundApp.IsExpired -ne $false) 
    {
        $oReturn = ,
        [System.Windows.Forms.MessageBox]::Show('Application is expired, Please choose an active application', 
            'Error', [System.Windows.Forms.MessageBoxButtons]::OK, 
        [System.Windows.Forms.MessageBoxIcon]::exclamation)

        switch ($oReturn){
            'OK' 
            {
                Exit
            }
        }
    }
    #Check auto install
    IF ($FoundAppXML.AppMgmtDigest.Application.AutoInstall -ne $true) 
    {
        $oReturn = ,
        [System.Windows.Forms.MessageBox]::Show('Application not enabled for install through Task Sequence', 
            'Error', [System.Windows.Forms.MessageBoxButtons]::OK, 
        [System.Windows.Forms.MessageBoxIcon]::exclamation)

        switch ($oReturn){
            'OK' 
            {
                Exit
            }
        }            
    }

    #Get current application groups:
    $AppGroups = $CurrentApplicationlist.Applications.ApplicationGroup |  Select-Object -ExpandProperty 'Name'
    
    #Choose Group GUI
    $objForm = New-Object -TypeName System.Windows.Forms.Form 
    $objForm.Text = 'Select a Group'
    $objForm.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (300, 250) 
    $objForm.StartPosition = 'CenterScreen'

    $objForm.KeyPreview = $true

    $objForm.Controls.Add($CheckBox)
   
    $OKButton = New-Object -TypeName System.Windows.Forms.Button
    $OKButton.Location = New-Object -TypeName System.Drawing.Size -ArgumentList (10, 155)
    $OKButton.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (75, 23)
    $OKButton.Text = 'OK'

    #Add New Application when ok is pressed
    $OKButton.Add_Click({
            #Add application

            #Get highest ID, to avoid dublicates
            $CurrentID = ($CurrentApplicationlist.Applications.ApplicationGroup).Application | Select-Object -ExpandProperty id
        
            [INT]$HighestID = 1
            Foreach ($ID in $CurrentID) 
            {
                [INT]$ID = $ID
                If ($ID -gt $HighestID) 
                {
                    $HighestID = $ID
                }
            }

            $finalID = $HighestID+1


            #Assign listbox selection to Variable
            $AppGroup = $objListBox.Text

            #Add New application
            
            If (($CurrentApplicationlist.SelectNodes("//ApplicationGroup[@Name='$AppGroup']")).application.Count -eq 1) 
            {
                $Element = ($CurrentApplicationlist.SelectNodes("//ApplicationGroup[@Name='$AppGroup']")).application.clone()
            }
            Else
            {
                $Element = ($CurrentApplicationlist.SelectNodes("//ApplicationGroup[@Name='$AppGroup']")).application[0].clone()
            }


            $Element.DisplayName = $FoundApp.LocalizedDisplayName
            $Element.id = ($finalID).ToString()
            $Element.Name = $FoundApp.LocalizedDisplayName
            $Element.Guid = $FoundApp.ModelName
            $Element.ApplicationMappings.SelectNodes('//Match') |  ForEach-Object -Process {
                $_.DisplayName = $FoundApp.LocalizedDisplayName
            } 
            $Element.ApplicationMappings.FirstChild.Setter |   ForEach-Object -Process {
                $_.'#text' = $FoundApp.LocalizedDisplayName
            }
         
            #set As Selected
            $CurrentApplicationlist.Applications.SelectedApplications.



            #Append Changes
            Try
            {
                ($CurrentApplicationlist.SelectNodes("//ApplicationGroup[@Name='$AppGroup']")).AppendChild($Element)
    
                if ($CheckBox.Checked -eq $true) 
                {
                    $SelectedElement = $CurrentApplicationlist.Applications.SelectedApplications.FirstChild.Clone()
                    $SelectedElement.'Application.Id' = $finalID.ToString()

                    #append change

                    $CurrentApplicationlist.Applications.SelectedApplications.AppendChild($SelectedElement)
                }
                $CurrentApplicationlist.Save("$XMLPath")
            }
            Catch 
            {
                $MsgError = $_
            
                $MsgErrorLine = $_.InvocationInfo.ScriptLineNumber
                     
                $oReturn = ,
                [System.Windows.Forms.MessageBox]::Show("$MsgError `nLine: $MsgErrorLine", 
                    'Error', [System.Windows.Forms.MessageBoxButtons]::OK, 
                [System.Windows.Forms.MessageBoxIcon]::exclamation)

                switch ($oReturn){
                    'OK' 
                    {
                        Exit
                    }
                }
            }
                              

            $objForm.Close()
        }
        
    )
    $objForm.Controls.Add($OKButton)

    $CancelButton = New-Object -TypeName System.Windows.Forms.Button
    $CancelButton.Location = New-Object -TypeName System.Drawing.Size -ArgumentList (95, 155)
    $CancelButton.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (75, 23)
    $CancelButton.Text = 'Cancel'

    $CancelButton.Add_Click({
            $objForm.Close()
        }
    )
    $objForm.Controls.Add($CancelButton)

    $objLabel = New-Object -TypeName System.Windows.Forms.Label
    $objLabel.Location = New-Object -TypeName System.Drawing.Size -ArgumentList (10, 20) 
    $objLabel.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (280, 20) 
    $objLabel.Text = 'Please select a Group:'
    $objForm.Controls.Add($objLabel) 

    $objListBox = New-Object -TypeName System.Windows.Forms.ListBox 
    $objListBox.Location = New-Object -TypeName System.Drawing.Size -ArgumentList (10, 40) 
    $objListBox.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (260, 20) 
    $objListBox.Height = 80

    #Add GroupNames to GUI

    foreach ($Group in $AppGroups) 
    {
        [void] $objListBox.Items.Add("$Group")
    }

    $objForm.Controls.Add($objListBox) 

    $objForm.Topmost = $true

    $objForm.Add_Shown({
            $objForm.Activate()
        }
    )
    [void] $objForm.ShowDialog()

    #Choose Group GUI END
}

#Update applications. Updates Names of the application. If the name of an application is changed in SCCM the change needs to match in UDI app XML. 
if ($Update -eq $true) 
{
    #Get unique guid/ModelName
    $Guid = $FoundApp.ModelName

    #Get all Applications in list that matches
    $MatchedApplications = $CurrentApplicationlist.SelectNodes("//Application[@Guid='$Guid']")

    #Check if any were found if not then create popup and exit.
    if ([STRING]::IsNullOrEmpty($MatchedApplications))
    {
        $MsgError = 'No Applications Found'
                                              
        $oReturn = ,
        [System.Windows.Forms.MessageBox]::Show("$MsgError", 
            'Error', [System.Windows.Forms.MessageBoxButtons]::OK, 
        [System.Windows.Forms.MessageBoxIcon]::exclamation)

        switch ($oReturn){
            'OK' 
            {
                Exit
            }
        }
    }

    #Update DisplayName, ApplicationMappings and Setter values for all matches
    foreach ($Element in $MatchedApplications)
    {
        $Element.DisplayName = $FoundApp.LocalizedDisplayName
        $Element.Name = $FoundApp.LocalizedDisplayName
        $Element.ApplicationMappings.ChildNodes | ForEach-Object -Process {
            $_.DisplayName = $FoundApp.LocalizedDisplayName
        }
        $Element.ApplicationMappings.FirstChild.Setter | ForEach-Object -Process {
            $_.'#text' = $FoundApp.LocalizedDisplayName
        }
    }

    #Commit Changes
    Try
    {
        $CurrentApplicationlist.Save("$XMLPath")
    }
    Catch 
    {
        $MsgError = $_
            
        $MsgErrorLine = $_.InvocationInfo.ScriptLineNumber
                     
        $oReturn = ,
        [System.Windows.Forms.MessageBox]::Show("$MsgError `nLine: $MsgErrorLine", 
            'Error', [System.Windows.Forms.MessageBoxButtons]::OK, 
        [System.Windows.Forms.MessageBoxIcon]::exclamation)

        switch ($oReturn){
            'OK' 
            {
                Exit
            }
        }
    }
}

#Delete applications. Deletes all matching applications.
If ($Delete -eq $true) 
{
    #set unique guid/ModelName to variable
    $Guid = $FoundApp.ModelName

    #Get all Applications in list that matches
    $MatchedApplications = $CurrentApplicationlist.SelectNodes("//Application[@Guid='$Guid']")

    #Check if any were found if not then create popup and exit.
    if ([STRING]::IsNullOrEmpty($MatchedApplications))
    {
        $MsgError = 'No Applications Found'
                                              
        $oReturn = ,
        [System.Windows.Forms.MessageBox]::Show("$MsgError", 
            'Error', [System.Windows.Forms.MessageBoxButtons]::OK, 
        [System.Windows.Forms.MessageBoxIcon]::exclamation)

        switch ($oReturn){
            'OK' 
            {
                Exit
            }
        }
    }

    #Remove applications
    foreach ($Element in $MatchedApplications)
    {
        #Remove App if selected by default 
        $ID = $Element.Id

        #If the selected Value for the application exists remove it. 
        if (![STRING]::IsNullOrEmpty(($CurrentApplicationlist.Applications.SelectedApplications.SelectSingleNode("SelectApplication[@Application.Id='$ID']")))) 
        {
            $SelectedApp = ($CurrentApplicationlist.Applications.SelectedApplications.SelectSingleNode("SelectApplication[@Application.Id='$ID']"))
            [VOID] $CurrentApplicationlist.Applications.SelectedApplications.RemoveChild($SelectedApp)
        }
        
        #Remove Application
        [VOID] $Element.ParentNode.RemoveChild($Element)
    }

    #Commit Changes
    Try
    {
        $CurrentApplicationlist.Save("$XMLPath")
    }
    Catch 
    {
        $MsgError = $_
            
        $MsgErrorLine = $_.InvocationInfo.ScriptLineNumber
                     
        $oReturn = ,
        [System.Windows.Forms.MessageBox]::Show("$MsgError `nLine: $MsgErrorLine", 
            'Error', [System.Windows.Forms.MessageBoxButtons]::OK, 
        [System.Windows.Forms.MessageBoxIcon]::exclamation)

        switch ($oReturn){
            'OK' 
            {
                Exit
            }
        }
    }
}

If ($Check -eq $true)
{
    "







        UDI Application list consistency check

        Checks the following settings:
        1. Names of application match in SCCM and UDI APP list.
        2. That 'Allow application to be deployed through task sequence' is set to True.
        3. Dublicate IDs in the App list.
        4. Expired Applications.
    
    "



    [XML]$CurrentApplicationlist = Get-Content $XMLPath -ErrorAction Stop

    [Array]$allapps = $CurrentApplicationlist.Applications.ApplicationGroup.application

    #Check for no errors
    $ErrorCheck = 0

    #set progress to 0
    $i = 0

    #Check names of applications.
    ForEach ($x in $allapps)
    {
        #progress
        $i++
        $Name = $x.Name
        if ([STRING]::IsNullOrEmpty($Name)) 
        {
            $Name = ' '
        }
        Write-Progress -Activity 'Consistency Check' -Status "$Name" -PercentComplete (($i / $allapps.Count) * 100)

        If (![STRING]::IsNullOrEmpty($x))
        {
            $ModelName = $x.Guid
            
            $AppObject = Get-WmiObject -ComputerName $SMSServer -Namespace 'ROOT\SMS\Site_PS1' -Class 'SMS_ApplicationLatest' -Filter "ModelName = '$ModelName'"
    
            $AppObject.get()

            #Check Name
            if ($AppObject.LocalizedDisplayName -ne $x.Name) 
            {
                Write-Host $x.Name 'ID:' $x.Id 'Application Name Mismatch' -ForegroundColor Red
                $ErrorCheck = 1
            }
            #Check Auto Install (Allow through task sequence)
            [XML]$AppObjectXml = $AppObject.SDMPackageXML
            IF ($AppObjectXml.AppMgmtDigest.Application.AutoInstall -ne $true) 
            {
                Write-Host $x.Name ': Auto install not set to True' -ForegroundColor Red
                $ErrorCheck = 1
            }

            #Check if app is retired or superseeded
            if ($AppObject.IsExpired -ne $false)
            {
                Write-Host $x.Name ': Package is expired' -ForegroundColor Red
                $ErrorCheck = 1 
            }
        }
    }

    #Check for dublicate Id
    $Hash = @{}

    $allapps.id | ForEach-Object -Process {
        $Hash["$_"] += 1
    }

    foreach ( $key in $Hash.Keys ) 
    {
        if ($Hash."$key" -gt 1) 
        {
            Write-Host -Object "Dublicate application ID: $key" -ForegroundColor Red
            $ErrorCheck = 1
        }
    }

    If ($ErrorCheck -eq 0) 
    {
        Write-Host -Object '

            No Errors Found

        ' -ForegroundColor Green
    }




    Write-Host -Object '

        Press any key to continue ...

    '
    $null = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

#*=============================================
#* END OF SCRIPT:
#*=============================================
