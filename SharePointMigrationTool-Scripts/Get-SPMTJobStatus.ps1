[CmdletBinding()]
param(

)

process {
    $SpmtMigration = Get-SPMTMigration

    $returnObj = [System.Collections.Generic.List[pscustomobject]]::new()
    foreach ($task in ($SpmtMigration.StatusOfTasks | Sort-Object -Property "MigratingProgressPercentage")) {
        $returnObj.Add(
            [pscustomobject]@{
                "Source" = $task.SourceURI;
                "FilesToMigrate" = $task.NumFileWillBeMigrated;
                "FilesMigrated" = $task.NumActuallyMigratedFiles;
                "TotalFiles" = $task.NumScannedTotalFiles;
                "BadFiles" = $task.NumScannedBadFiles;
                "FailedFiles" = $task.NumFailedFiles;
                "PercentComplete" = $task.MigratingProgressPercentage;
                "Status" = $task.Status;
            }
        )
    }
}

end {
    return $returnObj
}