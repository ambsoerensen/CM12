#requires -Version 1
<#

    Purpose: Install Right click tool


    ErrorCodes:
    0 - Success
    1 - Copy failed
    2 - SCCM console installation folder not found.
#>

#Default install directory
$ConsoleDir = 'Microsoft Configuration Manager\AdminConsole\XmlStorage\Extensions\Actions'

#Do not Edit
$SccmConsoleGuid = '968164ab-af86-459c-b89e-d3a49c05d367'
[XML]$template = Get-Content -Path .\_TemplateAddAppToUDI.xml

$installx64 = 1
$installx86 = 1

Try 
{
    #x64
    If (Test-Path -Path "$env:ProgramFiles\$ConsoleDir") 
    {
        Copy-Item -Path .\$SccmConsoleGuid -Destination "$env:ProgramFiles\$ConsoleDir\$SccmConsoleGuid" -Recurse -Force -ErrorAction Stop
    
        #Set parameter to installed path
        $template.ActionDescription.ActionGroups.ActionDescription.Executable |  ForEach-Object -Process {
            $Value = $_.Parameters
            $Value = $Value.Replace('ReplaceMe',"$env:ProgramFiles\$ConsoleDir\$SccmConsoleGuid\UdiApplicationList.ps1" )
            $_.Parameters = $Value
        }
        $template.Save("$env:ProgramFiles\$ConsoleDir\$SccmConsoleGuid\AddAppToUDI.xml")

        $installx64 = 0
    }
    
    #x86
    If (Test-Path -Path "${env:ProgramFiles(x86)}\$ConsoleDir") 
    {
        Copy-Item -Path .\$SccmConsoleGuid -Destination "${env:ProgramFiles(x86)}\$ConsoleDir$SccmConsoleGuid" -Recurse -Force -ErrorAction Stop
    
        #Set parameter to installed path
        $template.ActionDescription.ActionGroups.ActionDescription.Executable |  ForEach-Object -Process {
            $Value = $_.Parameters
            $Value = $Value.Replace('ReplaceMe',"${env:ProgramFiles(x86)}\$ConsoleDir\$SccmConsoleGuid\UdiApplicationList.ps1" )
            $_.Parameters = $Value
        }
    
        $template.Save("${env:ProgramFiles(x86)}\$ConsoleDir\$SccmConsoleGuid\AddAppToUDI.xml")

        $installx86 = 0
    }
}

Catch 
{
    $MsgError = $_
            
    $MsgErrorLine = $_.InvocationInfo.ScriptLineNumber
                     
    Write-Verbose -Message "Right click tool install failed, Line $MsgErrorLine, error: $MsgError"

    Exit 1
}

If (($installx64 -eq 0) -or ($installx86 -eq 0)) 
{
    Exit 0
}

Exit 2