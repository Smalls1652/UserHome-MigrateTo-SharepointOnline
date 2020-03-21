[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [Parameter(ParameterSetName = "MigrationProgress")]
    [switch]$MigrationProgress,
    [Parameter(Position = 0)]
    [Parameter(ParameterSetName = "TotalJobsComplete")]
    [switch]$TotalJobsComplete
)

process {
    $SpmtMigration = Get-SPMTMigration

    switch ($PSCmdlet.ParameterSetName) {
        "MigrationProgress" {
            $returnObj = [System.Collections.Generic.List[pscustomobject]]::new()
            foreach ($task in ($SpmtMigration.StatusOfTasks | Sort-Object -Property "MigratingProgressPercentage")) {
                $returnObj.Add(
                    [pscustomobject]@{
                        "Source"          = $task.SourceURI;
                        "FilesToMigrate"  = $task.NumFileWillBeMigrated;
                        "FilesMigrated"   = $task.NumActuallyMigratedFiles;
                        "TotalFiles"      = $task.NumScannedTotalFiles;
                        "BadFiles"        = $task.NumScannedBadFiles;
                        "FailedFiles"     = $task.NumFailedFiles;
                        "PercentComplete" = $task.MigratingProgressPercentage;
                        "Status"          = $task.Status;
                    }
                )
            }
            break
        }

        "TotalJobsComplete" {
            $JobsCompleted = ($SpmtMigration.StatusOfTasks | Where-Object { $PSItem.Status -eq "COMPLETED" } | Measure-Object).Count
            $TotalNumberOfJobs = ($SpmtMigration.StatusOfTasks | Measure-Object).Count
            $JobsLeft = ($TotalNumberOfJobs - $JobsCompleted)
            $PercentComplete = [System.Math]::Round((($JobsCompleted / $TotalNumberOfJobs) * 100), 2)

            $returnObj = [pscustomobject]@{
                "JobsCompleted"   = $JobsCompleted;
                "TotalJobs"       = $TotalNumberOfJobs;
                "JobsLeft"        = $JobsLeft;
                "PercentComplete" = $PercentComplete;
            }
            break
        }
    }
}

end {
    return $returnObj
}