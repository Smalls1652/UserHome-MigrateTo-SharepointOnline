<#
.SYNOPSIS
    Import the SharePoint Migration Tool module to your current session.
.DESCRIPTION
    Easily import the SharePoint Migration Tool module to your current session without having to dig into your profile's WindowsPowerShell directory. 
.EXAMPLE
    PS C:\> .\Import-SPMTModule.ps1
    
    Imports the SharePoint Migration Tool module into your current session.
.NOTES
    Requires the SharePoint Migration Tool to be installed to your current profile to work.
#>
[CmdletBinding()]
param(

)

begin {
    <#
    This section might seem overkill, but there's a method to the madness. If your user profile's Documents library has been redirected to another location, such as by using OneDrive's 'Known Folder' redirection, this will pull the actual path location for your Documents library. From there, we combine that path with the known location of the module file.

    The reason why I made this is because the module shows up in your 'Modules' directory, but it doesn't officially show in your available modules when you load a PowerShell console. At least in my case it doesn't on Windows 10 1909/2004 or Windows Server 2019, so I wrote this to import it easily without searching for the module file itself. 
    #>
    
    $DocumentsLibrary = [System.Environment]::GetFolderPath("MyDocuments")
    $SpmtModulePath = "$($DocumentsLibrary)\WindowsPowerShell\Modules\Microsoft.SharePoint.MigrationTool.PowerShell\microsoft.sharepoint.migrationtool.powershell.psd1"
}

process {
    Write-Verbose "The SharePoint Migration Tool PowerShell module should be located at '$($SpmtModulePath)'."
    $PathTest = Test-Path -Path $SpmtModulePath #Test to see if the file exists.

    switch ($PathTest) {
        $false {
            #If the file is not found, throw a terminating error with the FileNotFoundException.
            Write-Verbose "The module file could not be found. Throwing a terminating error."
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.IO.FileNotFoundException]::new("The SharePoint Migration Tool module file could not be found. This usually occurs if the program was not installed under your user profile or the program is not installed at all.", $SpmtModulePath),
                    "SpmtModuleImport.TestPath",
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $SpmtModulePath
                )
            )
            break
        }

        Default {
            #If the file is found, then import it to the session.
            Write-Verbose "Module found. Importing to the session."
            Import-Module -Name $SpmtModulePath
            $ImportedModule = Get-Module -Name "microsoft.sharepoint.migrationtool.powershell"
            break
        }
    }
}

end {
    return $ImportedModule
}