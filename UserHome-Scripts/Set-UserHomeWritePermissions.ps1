<#
.SYNOPSIS
    Change explicit user permissions for a folder.
.DESCRIPTION
    Remove explicit permissions for a specific user on a folder and add a new explicit permission for that user, if provided.
.PARAMETER Domain
    The Active Directory domain name.
.PARAMETER UserName
    The username to modify explicit permissions for.
.PARAMETER FolderPath
    The path to the folder to modify permissions for.
.PARAMETER NewAccessType
    The permissions to add to the folder. See the notes section for more info.
.EXAMPLE
    PS C:\> .\Set-UserHomeWritePermissions.ps1 -Domain "contoso" -UserName "jdoe1" -FolderPath ".\path\to\folder\"

    Removes any explicit permissions for a user and then add a Read/Execute permission to the folder for the user.
.EXAMPLE
    PS C:\> $NewAccess = [pscustomobject]@{
        "FileSystemRights"  = [System.Security.AccessControl.FileSystemRights]::FullControl;
        "AccessControlType" = [System.Security.AccessControl.AccessControlType]::Deny;
    }

    PS C:\> .\Set-UserHomeWritePermissions.ps1 -Domain "contoso" -UserName "jdoe1" -FolderPath ".\path\to\folder\" -NewAccessType $NewAccess

    Removes any explicit permissions for a user and then adds deny permissions to the folder for the user.
.NOTES
    To create an object for the 'NewAccessType' parameter, it must be in this format:

    [pscustomobject]@{
        "FileSystemRights"  = [System.Security.AccessControl.FileSystemRights];
        "AccessControlType" = [System.Security.AccessControl.AccessControlType];
    }

    For info on the 'System.Security.AccessControl.FileSystemRights' type:  https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights
    For info on the 'System.Security.AccessControl.AccessControlType' type: https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.accesscontroltype
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [string]$Domain,
    [Parameter(Position = 1, Mandatory)]
    [string]$UserName,
    [Parameter(Position = 2, Mandatory)]
    [string]$FolderPath,
    [Parameter(Position = 3)]
    [pscustomobject]$NewAccessType = [pscustomobject]@{
        "FileSystemRights"  = [System.Security.AccessControl.FileSystemRights]::ReadAndExecute;
        "AccessControlType" = [System.Security.AccessControl.AccessControlType]::Allow;
    }
)

process {
    $CombinedUserName = "$($Domain)\$($UserName)" #Combine the domain and the username for the IdentityReference property.

    Write-Verbose "Getting the current ACL for '$($FolderPath)'."
    $FolderAcl = Get-Acl -Path $FolderPath #Get the current ACL for the folder.
    $ExplicitUserPermissions = $FolderAcl.Access | Where-Object { $PSItem.IdentityReference -eq $CombinedUserName } #Get all of the access rules for the user

    if ($ExplicitUserPermissions) {
        #If any access rules were found, remove them from the ACL object.
        foreach ($item in $ExplicitUserPermissions) {
            $removeResult = $FolderAcl.RemoveAccessRule($item)

            switch ($removeResult) {
                $false {
                    Write-Warning "Failed to remove a permission for '$($UserName)'."
                    break
                }

                Default {
                    Write-Verbose "Removed a permission for '$($UserName)'."
                    break
                }
            }
        }
    }

    if ($NewAccessType) {
        #If 'NewAccessType' was provided, then generate a new access rule with the provided settings.
        Write-Verbose "'NewAccessType' was provided. Adding the new rule to the ACL."
        $NewAclRule = [System.Security.AccessControl.FileSystemAccessRule]::new(
            $CombinedUserName,
            $NewAccessType.FileSystemRights,
            ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit, [System.Security.AccessControl.InheritanceFlags]::ObjectInherit),
            [System.Security.AccessControl.PropagationFlags]::None,
            $NewAccessType.AccessControlType
        )

        $FolderAcl.AddAccessRule($NewAclRule) #Add the new access rule to the ACL object.
    }

    Write-Verbose "Updating the ACL for '$($FolderPath)'."
    Set-Acl -Path $FolderPath -AclObject $FolderAcl -ErrorAction Stop #Add the modified ACL object to the folder.

}