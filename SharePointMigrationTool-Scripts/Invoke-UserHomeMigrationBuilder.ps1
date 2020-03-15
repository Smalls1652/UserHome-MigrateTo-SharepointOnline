<#
.SYNOPSIS
    Get user data and export the data to a CSV for bulk migration with the Sharepoint Migration Tool.
.DESCRIPTION
    Build out a CSV file to bulk migrate user data from their home directory to their personal OneDrive folder in Sharepoint Online. Useful for quickly creating bulk jobs in the Sharepoint Migration Tool.
.PARAMETER UserName
    The username of a user that will have their data migrated.
.PARAMETER TenantName
    The domain name of your Office 365 tenant.
.PARAMETER SPOSubFolder
    The sub-folder to put the migrated data into during the migration job. Useful for preventing conflicts that may already exist.
.PARAMETER ExportPath
    The file path to export the CSV file to.
.EXAMPLE
    PS C:\> .\Invoke-UserHomeMigrationBuilder.ps1 -UserName @("jdoe1", "jwinger", "pryan") -TenantName "contoso.com" -SPOSubFolder "UserHome Migration" -ExportPath ".\UserHomeDir-MigrationJob.csv"
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [string[]]$UserName,
    [Parameter(Position = 1, Mandatory)]
    [string]$TenantName,
    [Parameter(Position = 2)]
    [string]$SPOSubFolder,
    [Parameter(Position = 2, Mandatory)]
    [string]$ExportPath
)

begin {
    class UserAccountObj {
        [string]$Source
        [string]$SourceDocLib
        [string]$SourceSubFolder
        [string]$TargetWeb
        [string]$TargetDocLib
        [string]$TargetSubFolder
    }

    $DomainSharepointBase = $TenantName.Replace(".", "") #Remove the '.' character for the sub-domain name to the Sharepoint Online domain.
    $SharepointPersonalDomain = $TenantName.Replace(".", "_") #Replace the '.' character with '_' to map to a user's personal Sharepoint Online library (OneDrive).
}

process {
    $UserData = @()

    #Loop through each UserName provided.
    foreach ($User in $UserName) {
        Write-Verbose "Getting user data for '$($User)'."
        $UserAccount = Get-ADUser -Identity $User -Properties "HomeDirectory" #Collect the user's AD object and ensure that the 'HomeDirectory' property is returned.

        if ($UserAccount.HomeDirectory) {
            #If the 'HomeDirectory' property does exist on the AD object, build an object and add it to the UserData array
            $UserData += [UserAccountObj]@{
                "Source"          = $UserAccount.HomeDirectory;
                "TargetWeb"       = "https://$($DomainSharepointBase)-my.sharepoint.com/personal/$($UserAccount.Name)_$($SharepointPersonalDomain)/";
                "TargetDocLib"    = "Documents";
                "TargetSubFolder" = $SPOSubFolder;
            }
        }
        else {
            #If the 'HomeDirectory' property does not exist on the AD object, return a warning message to the console. 
            Write-Warning "'$($UserAccount.Name)' does not have a home directory attached to their user object. Skipping."
        }
    }

    $TmpFile = New-TemporaryFile #Create a temporary file to export the data to
    Write-Verbose "Exporting the data to '$($ExportPath)'."
    $UserData | Export-Csv -Path $TmpFile.FullName -NoTypeInformation #Export the data as a CSV file to the temporary file
    $ExportedData = Get-Content -Path $TmpFile.FullName #Get the file content of the temporary file
    $null = Remove-Item -Path $TmpFile -Force #Remove the temporary file from the system

    #For some odd reason, the Sharepoint Migration Tool does not like having the header line in the CSV file. When we export the final file, it just skips the first line and saves it to the path specified.
    $ExportedData | Select-Object -Skip 1 | Out-File -FilePath $ExportPath

}