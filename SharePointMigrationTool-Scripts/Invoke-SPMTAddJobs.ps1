[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position = 0)]
    [Parameter(ParameterSetName = "InputObject")]
    [ValidateNotNull()]
    [pscustomobject]$InputData,
    [Parameter(Position = 0)]
    [Parameter(ParameterSetName = "JsonFile")]
    [ValidateNotNullOrEmpty()]
    [string]$JsonPath
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

    #Determine what should be done if a certain parameterset is used.
    switch ($PSCmdlet.ParameterSetName) {
        "InputObject" {
            #If -InputData is provided, there is nothing to do.
            break
        }

        "JsonFile" {
            #If -JsonPath is provided, test for the file path and import it as 'InputData'.
            if ((Test-Path -Path $JsonPath) -eq $false) {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.IO.FileNotFoundException]::new("The JSON file could not be found."),
                        "SpmtAddTask.ImportJsonData",
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $JsonPath
                    )
                )
            }

            $InputData = Get-Content -Path $JsonPath -Raw | ConvertFrom-Json
            break
        }
    }

    foreach ($Job in $InputData) {
        try {
            $null = [UserAccountObj]$Job
        }
        catch {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new("An item in the input data is invalid."),
                    "SpmtAddTask.ValidateInput",
                    [System.Management.Automation.ErrorCategory]::InvalidType,
                    $Job
                )
            )
        }
    }
}

process {
    foreach ($Job in $InputData) {
        if ($PSCmdlet.ShouldProcess($Job.Source, "Migrate to '$($Job.TargetWeb)'")) {
            Add-SPMTTask -FileShareSource $Job.Source -TargetSiteUrl $Job.TargetWeb -TargetList $Job.TargetDocLib -TargetListRelativePath $Job.TargetSubFolder
        }
    }
}