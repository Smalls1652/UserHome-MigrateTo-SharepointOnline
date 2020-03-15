<#
.SYNOPSIS
    Get the license state for a user in Azure AD.
.DESCRIPTION
    Get the license state for a user in Azure AD by evaluating if they are are assigned to the right license or if their object exists in Azure AD.
.PARAMETER UserName
    The username of a user to check.
.PARAMETER DomainName
    The domain name of the user's UserPrincipalName.
.PARAMETER SkuId
    The license plan GUID to check for.
.PARAMETER SkuPartNumber
    The license plan name to check for.
.EXAMPLE
    PS C:\> .\Get-AadUserIsLicensed.ps1 -UserName @("jdoe1", "jwinger", "phawthorne") -DomainName "contoso.com" -SkuId "e97c048c-37a4-45fb-ab50-922fbf07a370"
    
    Gets the license status of the users 'jdoe1', 'jwinger', and 'phawthorne' for the domain 'contoso.com' and if they are licensed for the M365 A5 Faculty plan by using the GUID for it.
.EXAMPLE
    PS C:\> .\Get-AadUserIsLicensed.ps1 -UserName @("jdoe1", "jwinger", "phawthorne") -DomainName "contoso.com" -SkuPartName "M365EDU_A5_FACULTY"
    
    Gets the license status of the users 'jdoe1', 'jwinger', and 'phawthorne' for the domain 'contoso.com' and if they are licensed for the M365 A5 Faculty plan by using the SkuPartName for it.
.NOTES
    Ensure that the 'AzureAD' module and the 'Connect-AzureAD' cmdlet has been ran before running this script.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [Parameter(ParameterSetName = "BySkuId")]
    [Parameter(ParameterSetName = "BySkuPartNumber")]
    [ValidateNotNullOrEmpty()]
    [string[]]$UserName,
    [Parameter(Position = 1, Mandatory)]
    [Parameter(ParameterSetName = "BySkuId")]
    [Parameter(ParameterSetName = "BySkuPartNumber")]
    [ValidateNotNullOrEmpty()]
    [string]$DomainName,
    [Parameter(Position = 2)]
    [Parameter(ParameterSetName = "BySkuId")]
    [ValidateNotNullOrEmpty()]
    [string]$SkuId,
    [Parameter(Position = 2)]
    [Parameter(ParameterSetName = "BySkuPartNumber")]
    [ValidateNotNullOrEmpty()]
    [string]$SkuPartNumber
)

begin {
    #Depending on whether or not the SkuId or the SkuPartNumber parameters are used, we will determine what to set the filter to.
    switch ($PSCmdlet.ParameterSetName) {
        "BySkuId" {
            #If SkuId was provided, set the LicenseFilter to filter for the SkuId
            filter LicenseFilter {
                if ($PSItem.SkuId -eq $SkuId) {
                    $PSItem
                }
            }
            break
        }

        "BySkuPartNumber" {
            #If SkuPartNumber was provided, set the LicenseFilter to filter for the SkuPartNumber
            filter LicenseFilter {
                if ($PSItem.SkuPartNumber -eq $SkuPartNumber) {
                    $PSItem
                }
            }
            break
        }
    }

    $returnObj = @()
}

process {
    #Now we need to loop each provided username and gather details for each.
    foreach ($User in $UserName) {
        $AadUser = Get-AzureADUser -SearchString "$($User)@$($DomainName)" #The search string searches for by the UserPrincipalName by supplying a combined string of '[User]@[DomainName]' to reduce the amount of conflicting account objects that may arise.

        #Check to see if we actually got a result back and if what was returned was just one.
        $AadUserReturnCount = $AadUser | Measure-Object
        switch ($AadUserReturnCount.Count) {
            { ($PSItem -eq 0) -or ($PSItem -gt 1) } {
                #If we get more than 1 or 0 results, write an error to the console.
                #Do note that the error should not stop the processing of the remaining objects, unless ErrorAction is explicitly changed to 'Stop'.
                $PSCmdlet.WriteError([System.Management.Automation.ErrorRecord]::new(
                        [System.Exception]::new("'$($AadUserReturnCount.Count)' returned for '$($User)'. There should only be one record for this username."),
                        "AadLicenseCheck.UserSearch",
                        [System.Management.Automation.ErrorCategory]::InvalidData,
                        ([pscustomobject]@{
                                "UserName"         = $User;
                                "AadSearchResults" = $AadUser
                            })
                    )
                )

                #Add to the returnObj array that the user is not licensed, even if the user doesn't exist or too many results came back.
                $returnObj += [pscustomobject]@{
                    "UserName"          = $User;
                    "UserPrincipalName" = "N/A";
                    "IsLicensed"        = $false;
                }
                break
            }

            Default {
                #If we get 1 result back, check if they have the right license assigned to them.

                $UserIsLicensed = $false
                if ($AadUser) {
                    $AadUserLicenses = Get-AzureADUserLicenseDetail -ObjectId $AadUser.ObjectId #Get the license assigned to the user

                    if ($AadUserLicenses | LicenseFilter) {
                        #If the LicenseFilter returns anything, set the UserIsLicensed variable to 'true'.
                        $UserIsLicensed = $true
                    }
                }

                #Add to the returnObj array that the user is either licensed properly or not.
                $returnObj += [pscustomobject]@{
                    "UserName"          = $User;
                    "UserPrincipalName" = $AadUser.UserPrincipalName;
                    "IsLicensed"        = $UserIsLicensed;
                }
                break
            }
        }
    }
}

end {
    return $returnObj
}