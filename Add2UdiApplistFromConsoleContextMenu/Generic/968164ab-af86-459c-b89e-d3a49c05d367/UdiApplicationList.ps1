# FileName: PowerShellTemplate.ps1
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
Add new Application - Adds one Application to one Application group. 

Update: Update dependant name values for all instances of the application in the list.
        eg. the name of the package have changed. 

Remove: Remove all instanes of the marked application from the Aplicaiton list. 


Examples.

Add new Application to list. 
UdiApplicationList.ps1 -ModelName ##SUB:ModelName## -New

Update Application in list
UdiApplicationList.ps1 -ModelName ##SUB:ModelName## -Update

Remove Application from list
UdiApplicationList.ps1 -ModelName ##SUB:ModelName## -Delete

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
    [SWITCH]$Delete

)
#==============================================
#  DEFAULT VALUES
#==============================================

#SCCM Servername
$SMSServer = ''

#Backup path for 'UDIWizard_Config.xml.app'
$BackupDir = ''

#Path to 'UDIWizard_Config.xml.app'
$XMLPath = ''

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
    [XML]$CurrentApplicationlist = Get-Content $XMLPath -ErrorAction Stop

    #Backup Current XML File
    $Date = (Get-Date -DisplayHint Date -Format s).Replace(':','-')
    $BackupFileName = "$BackupDir\$Date"+'_'+'UDIWizard_Config.xml.app'
    Copy-Item $XMLPath -Destination $BackupFileName -ErrorAction Stop
}
Catch 
{
    $MsgError = $Error[0] 
            
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
    #Get current application groups:
    $AppGroups = $CurrentApplicationlist.Applications.ApplicationGroup |  Select-Object -ExpandProperty 'Name'
    
    #Choose Group GUI
    $objForm = New-Object -TypeName System.Windows.Forms.Form 
    $objForm.Text = 'Select a Group'
    $objForm.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (300, 250) 
    $objForm.StartPosition = 'CenterScreen'

    $objForm.KeyPreview = $true

    $$CheckBox = New-Object -TypeName System.Windows.Forms.CheckBox
    $CheckBox.Location = New-Object -TypeName System.Drawing.Size -ArgumentList (10, 120)
    $CheckBox.Text = "Selected"

    $objForm.Controls.Add($CheckBox)
   
    $OKButton = New-Object -TypeName System.Windows.Forms.Button
    $OKButton.Location = New-Object -TypeName System.Drawing.Size -ArgumentList (10, 155)
    $OKButton.Size = New-Object -TypeName System.Drawing.Size -ArgumentList (75, 23)
    $OKButton.Text = 'OK'

    $OKButton.Add_Click({
            #Add New Application when ok is presses
            
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

            #Assign listbox selection to Variable
            $AppGroup = $objListBox.Text

            #Add New application
            $Element = ($CurrentApplicationlist.SelectNodes("//ApplicationGroup[@Name='$AppGroup']")).application[0].clone()
            $Element.DisplayName = $FoundApp.LocalizedDisplayName
            $Element.id = ($HighestID+1).ToString()
            $Element.Name = $FoundApp.LocalizedDisplayName
            $Element.Guid = $FoundApp.ModelName
            $Element.ApplicationMappings.SelectNodes('//Match') |  ForEach-Object -Process {
                $_.DisplayName = $FoundApp.LocalizedDisplayName
            } 
            $Element.ApplicationMappings.FirstChild.Setter |   ForEach-Object -Process {
                $_.'#text' = $FoundApp.LocalizedDisplayName
            }
         
            #Append Changes
            Try
            {
                ($CurrentApplicationlist.SelectNodes("//ApplicationGroup[@Name='$AppGroup']")).AppendChild($Element)
    
                $CurrentApplicationlist.Save("$XMLPath")
            }
            Catch 
            {
                $MsgError = $Error[0] 
            
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
        $MsgError = $Error[0] 
            
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
        $MsgError = $Error[0] 
            
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

#*=============================================
#* END OF SCRIPT:
#*=============================================
