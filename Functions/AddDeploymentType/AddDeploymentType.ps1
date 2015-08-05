function New-DeploymentType
{
    <#
            .SYNOPSIS
            Add a new deployment type to an application.
            .DESCRIPTION
            A function that will add a deployment type (SCRIPT) to an application i SCCM 2012 R2 Using WMI.
            The Deployment will be created with a custom script detection rule, language: powershell.
            .DEPENDENCIES
            Microsoft.ConfigurationManagement.ApplicationManagement.dll
            Microsoft.ConfigurationManagement.ApplicationManagement.MsiInstaller.dll
            .EXAMPLE
            New-DeploymentType -Sitecode "PS1" -SiteServer "CM01.kingdom.local" -ApplicationName "Adobe Reader 11" -InstallCommand "Installer.exe /s /w /q" -UninstallCommand "Installer.exe /u" -DisplayName "Adobe Reader 11" -version "1" -source "\\Domain\CM\Source\AdobeReader\11"
            
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $True, Position = 0)]
        [System.String]
        $Sitecode = '',
        
        [Parameter(Mandatory = $True, Position = 1)]
        [System.String]
        $SiteServer = '',
        
        [Parameter(Mandatory = $True, Position = 2)]
        [System.String]
        $ApplicationName = '',
                
        [Parameter(Mandatory = $True, Position = 4)]
        [System.String]
        $InstallCommand = '',
        
        [Parameter(Mandatory = $false, Position = 5)]
        [System.String]
        $UninstallCommand = '',
        
        [Parameter(Mandatory = $True, Position = 6)]
        [System.String]
        $DisplayName = '',
        
        [Parameter(Mandatory = $True, Position = 7)]
        [System.String]
        $version = '',
        
        [Parameter(Mandatory = $True, Position = 8)]
        [System.String]
        $source = ''
    )
    
    Try 
    {
        #load Module and assemblies.
        $ScriptDir = Get-Location
               
        Import-Module "$ScriptDir\Bin\SCCM\ConfigurationManager.psd1"

        $null = [system.Reflection.Assembly]::LoadFile("$ScriptDir\Bin\SCCM\Microsoft.ConfigurationManagement.ApplicationManagement.dll")
        $null = [system.Reflection.Assembly]::LoadFile("$ScriptDir\Bin\SCCM\Microsoft.ConfigurationManagement.ApplicationManagement.MsiInstaller.dll")

        #get application by displayname and revision
        $Application = Get-WmiObject -Namespace "Root\SMS\Site_$Sitecode" -Class SMS_ApplicationLatest -ComputerName $SiteServer -Filter "LocalizedDisplayName='$ApplicationName'"
        #load lazy properties (includes XML)
        $Application.Get()
        #write XML to variable and print to screen
        $ApplicationXML = $Application.SDMPackageXML
        #deserialize XML to application object
        $ApplicationObject = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($ApplicationXML,$True)
    
        #Get scopeid
        $identificationClass = [WMICLASS]"\\$($SiteServer)\$("Root\SMS\Site_$Sitecode"):SMS_Identification"
        $cls = Get-WmiObject SMS_Identification -Namespace "Root\SMS\Site_$Sitecode" -ComputerName $SiteServer -List
        $tmp = $identificationClass.GetSiteID().SiteID
        $scopeid = "ScopeId_$($tmp.Substring(1,$tmp.Length -2))"
    
        $newDeploymentTypeID = 'DeploymentType_' + [guid]::NewGuid().ToString()
        $newDeploymentTypeID = New-Object -TypeName Microsoft.ConfigurationManagement.ApplicationManagement.ObjectID -ArgumentList ($scopeid, $newDeploymentTypeID)
    
        #Create Objects
        $newDeploymentType = New-Object  -TypeName Microsoft.ConfigurationManagement.ApplicationManagement.DeploymentType -ArgumentList ($newDeploymentTypeID, 'Script')
        $ApplicationObjectContent = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentImporter]::CreateContentFromFolder($source)
    
        #Deployment Type Script installer will be used
        $newDeploymentType.Title = "$DisplayName - Script Installer"
        $newDeploymentType.Version = $version
        $newDeploymentType.Installer.InstallCommandLine = $InstallCommand
        $newDeploymentType.Installer.UninstallCommandLine = $UninstallCommand
        $newDeploymentType.Installer.Contents.Add($ApplicationObjectContent)
    
    
        #Detectionmethod
        $DetectionScript = 'if (test-path "C:\Windows") {write-host "The application is installed."}'
        $newDeploymentType.Installer.DetectionMethod = 'Script'
        $newDetectionScript = New-Object -TypeName Microsoft.ConfigurationManagement.ApplicationManagement.Script
        $newDetectionScript.Language = 'PowerShell'
        $newDetectionScript.Text = $DetectionScript
        $newDeploymentType.Installer.DetectionScript = $newDetectionScript
    
        #Add the DeploymentType to the Application
        $ApplicationObject.DeploymentTypes.Add($newDeploymentType)
    
        #Serialize the object to an xml file and stuff it into SCCM
        $ApplicationObjectXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToSTring($ApplicationObject,$True)
    
        $Application.SDMPackageXML = $ApplicationObjectXML
    
        $null = $Application.Put()

        return $newDeploymentType.Title
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
                Return
            }
        }
    }
}
