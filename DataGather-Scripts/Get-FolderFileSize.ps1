<#
.SYNOPSIS
    Get the total size of a folder.
.DESCRIPTION
    Get a folder's total size by calculating each file in it (Including sub-directories) and return it in a readable object with the folder path, last time a file was written, and the total size of the folder in GBs.
.PARAMETER FolderPath
    The file path to the folder to collect data on.
.EXAMPLE
    PS C:\> .\Get-FolderFileSize.ps1 -FolderPath ".\test\folder\"
    
    Get the total size for a single folder.
.EXAMPLE
    PS C:\> Get-ChildItem -Path ".\" | Foreach-Object { .\Get-FolderFileSize.ps1 -FolderPath $PSItem.FullName }

    Get total size for all folders in folder.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [string]$FolderPath
)

begin {
    $FolderObj = Get-Item -Path $FolderPath -ErrorAction Stop #Get the folder path as an object

    if (!($FolderObj.PSIsContainer)) {
        #If PSIsContainer (Folder) is set to $false, then throw a terminating error that the item is not a folder.
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new("Item is not a folder."),
                "Item.IsPathFolder",
                [System.Management.Automation.ErrorCategory]::MetadataError,
                $FolderPath
            )
        )
    }
}

process {
    $FilesInFolder = $FolderObj.GetFiles("*", [System.IO.SearchOption]::AllDirectories) #Get all files in all sub-directories in the folder.

    $LastWrittenFile = $FilesInFolder | Sort-Object -Property "LastWriteTime" -Descending | Select-Object -First 1 #Get the last file that has been written to.

    $TotalSize = 0
    foreach ($item in $FilesInFolder) {
        #Loop through each file found and add the file size to the $TotalSize variable.
        $TotalSize += $item.Length
    }

    $TotalSizeReadable = [Math]::Round(($TotalSize / 1GB), 4) #Convert the $TotalSize variable to a readable format in GB.
}

end {
    return [pscustomobject]@{
        "DirectoryPath"       = $FolderObj.FullName;
        "LastWrittenFileDate" = $LastWrittenFile.LastWriteTime;
        "SizeInGB"            = $TotalSizeReadable;
    }
}