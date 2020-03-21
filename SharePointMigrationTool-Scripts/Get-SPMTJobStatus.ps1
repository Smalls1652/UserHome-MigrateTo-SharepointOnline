[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [Parameter(ParameterSetName = "MigrationProgress")]
    [switch]$MigrationProgress,
    [Parameter(Position = 1)]
    [Parameter(ParameterSetName = "MigrationProgress")]
    [ValidateSet("All", "InProgress", "Completed", "NotStarted")]
    [string]$OnlyShow = "All",
    [Parameter(Position = 0)]
    [Parameter(ParameterSetName = "TotalJobsComplete")]
    [switch]$TotalJobsComplete
)

process {
    $SpmtMigration = Get-SPMTMigration

    switch ($PSCmdlet.ParameterSetName) {
        "MigrationProgress" {
            $returnObj = [System.Collections.Generic.List[pscustomobject]]::new()
            switch ($OnlyShow) {
                "InProgress" {
                    $TaskStatus = $SpmtMigration.StatusOfTasks | Where-Object { $PSItem.Status -eq "INPROGRESS" } | Sort-Object -Property "MigratingProgressPercentage"
                    break
                }

                "Completed" {
                    $TaskStatus = $SpmtMigration.StatusOfTasks | Where-Object { $PSItem.Status -eq "COMPLETED" } | Sort-Object -Property "MigratingProgressPercentage"
                    break
                }

                "NotStarted" {
                    $TaskStatus = $SpmtMigration.StatusOfTasks | Where-Object { $PSItem.Status -eq "INITED" } | Sort-Object -Property "MigratingProgressPercentage"
                    break
                }

                Default {
                    $TaskStatus = $SpmtMigration.StatusOfTasks | Sort-Object -Property "MigratingProgressPercentage"
                    break
                }
            }
            foreach ($task in $TaskStatus) {
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