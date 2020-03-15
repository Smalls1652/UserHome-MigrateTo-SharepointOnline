# PowerShell Scripts to Migrate User Home Drives to their OneDrive

I am dropping all of the scripts I have been making to migrate users' home drives to their work account's OneDrive. In my scenario, this project wasn't expected to be done in a short amount of time. Due to the concerns of coronavirus (COVID-19) and the probability of our workplace being switched to *Work-From-Home*/*Teach-From-Home*, which has just been officially enforced, we needed to fast track this project from months out to before the end of March 2020.

While we have not migrated users' home drives yet, I have been making these PowerShell scripts to quickly gather data about the users' home drive directory, if the user is licensed, and building a CSV file for bulk migration jobs utilizing the [SharePoint Migration Tool](https://docs.microsoft.com/en-us/sharepointmigration/introducing-the-sharepoint-migration-tool). This recently released tool from Microsoft allows administrators to migrate not just SharePoint sites, but also file shares.

I do want to note that not all of the scripts are ready to be pushed to this public repository, but I do heavily intend to get them on here as fast as I can. I do know that this current situation the world is in of coronavirus (COVID-19) is taxing a lot of IT departments out there because of the transition from on-premise resources to *cloud-based* resources. This is one of those instances where off-loading on-premise resources to the cloud, will alleviate the need for users to connect back with a VPN. In the end I hope this helps other administrators in the future, even after today's current events.

I hope this repository will help anybody out there!

## Status of Repository

- **Data Gather Scripts**
    - [x] Get-FolderFileSize.ps1
    - [x] Get-AadUserIsLicensed.ps1
- **User Home Scripts**
    - [ ] Remove-UserHomeSharePermissions.ps1
    - [ ] Remove-UserHomeMapping.ps1
- **SharePoint Migration Tool Scripts**
    - [x] Import-SPMTModule.ps1
    - [ ] Create-BatchListByTier.ps1
        - Cleaning up code and adding comments.
    - [x] Invoke-UserHomeMigrationBuilder.ps1
    - [ ] Invoke-AddJobsToSPMT.ps1

***Other scripts I create for this process will be added in when necessary.***

## Script Details

### Data Gather Scripts

In this section, I will cover the scripts that are most useful for gathering data on users and their respective home drives.

#### Get-FolderFileSize.ps1

This script is intended to help gather data from a folder and determine when the last time a file was written to it and how large the total size of the folder is. It also converts the total bytes into total gigabytes to make the output easier to read. In my case with our users' home drives, I needed to identify which users had the largest amount of storage. My methodology with doing the migration jobs utilizing the **SharePoint Migration Tool** was to create batches of jobs depending on who has the most data and how many to do based off of that.

To get the total size of a single folder, you can run the script like this:

```powershell
PS \> .\Get-FolderFileSize.ps1 -FolderPath ".\path\to\folder\"
```

The output would be something like this:

```
DirectoryPath          LastWrittenFileDate  SizeInGB
-------------          -------------------  --------
C:\path\to\folder\     9/17/2019 7:43:13 AM   0.0824
```

To get the total size of all the folders in directory, you can run the script like this:

```powershell
PS \> Get-ChildItem -Path "C:\path\to\folder\" | ForEach-Object { .\Get-FolderFileSize.ps1 -FolderPath $PSItem.FullName }
```

The output would be something like this:
```
DirectoryPath          LastWrittenFileDate  SizeInGB
-------------          -------------------  --------
C:\path\to\folder\a    9/17/2019 7:43:13 AM   12.7824
C:\path\to\folder\b    10/20/2016 8:00:43 AM  0.5334
C:\path\to\folder\c    4/21/2019 3:30:04 PM   3.9221
C:\path\to\folder\d    9/01/2012 1:03:19 AM   0.0020
```

#### Get-AadUserIsLicensed.ps1

This script will check to see if a user exists in Azure AD and if they are licensed with the right O365/M365 plan. Some users who have left in our environment still have a local on-premise user home drive that hasn't been removed yet, so to prevent unnecessary data being migrated this let me check for that. At the same time I needed a way to filter out users who have left, but their account hasn't been removed from Azure AD yet; however, they're not assigned the M365 A5 plan anymore because they've left.

To use this script, you need to ensure you have the `AzureAD` module installed and the `Connect-AzureAD` cmdlet has been ran before using it.

To get the license state for a user, you can run something like this:

```powershell
PS \> .\Get-AadUserIsLicensed.ps1 -UserName @("jdoe1", "jwinger", "phawthorne") -DomainName "contoso.com" -SkuId "e97c048c-37a4-45fb-ab50-922fbf07a370"
```

or

```powershell
PS \> .\Get-AadUserIsLicensed.ps1 -UserName @("jdoe1", "jwinger", "phawthorne") -DomainName "contoso.com" -SkuPartNumber "M365EDU_A5_FACULTY"
```

The output would look like:

```
[...]\Get-AadUserIsLicensed.ps1 : '0' returned for 'phawthorne'. There should only be one record for this username.
At line:1 char:1
+ .\Get-AadUserIsLicensed.ps1 -UserName @("jdoe1", "jwinger", "p ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidData: (@{UserName=phaw...SearchResults=}:PSObject) [Get-AadUserIsLicensed.ps1], Exception
    + FullyQualifiedErrorId : AadLicenseCheck.UserSearch,Get-AadUserIsLicensed.ps1


UserName    UserPrincipalName        IsLicensed
--------    -----------------        ----------
jdoe1       jdoe1@contoso.com             True
jwinger     jwinger@contoso.com           True
phawthorne  N/A                           False
```

**NOTE**: If a user doesn't exist, it should not stop processing users unless you change the `ErrorAction` explicitly. The error is meant to write to the console and provide details on what happened. In fact you can have the errors sent to a variable. You can run the script like this:

```powershell
PS \> .\Get-AadUserIsLicensed.ps1 -UserName @("jdoe1", "jwinger", "phawthorne", "bperry") -DomainName "contoso.com" -SkuId "e97c048c-37a4-45fb-ab50-922fbf07a370" -ErrorVariable "failedUsers"
```

From there you'll have a variable, `$failedUsers`, to look at. If you had numerous errors you can do `$failedUsers.TargetObject` to get a return of what caused the error for each user. You can also do `$failedUsers[n]`, where `n` is a number from 0 to however large the array is, to get the error for one particular object.

### SharePoint Migration Tool Scripts

In this section, I will cover scripts related to the SharePoint Migration Tool.

#### Import-SPMTModule.ps1

This is a script I made to easily import the SharePoint Migration Tool module to the current PowerShell session. The reason why I made this is because the module shows up in your 'Modules' directory, but it doesn't officially show in your available modules when you load a PowerShell console. At least in my case it doesn't on Windows 10 1909/2004 or Windows Server 2019, so I wrote this to import it easily without searching for the module file itself.

To use it you run it like this:

```powershell
PS \> .\Import-SPMTModule.ps1
```

#### Invoke-UserHomeMigrationBuilder.ps1

This script will utilize the `ActiveDirectory` module that comes installed with the **Remote Server Administration Tools** on Windows and Windows Server to get user objects and create the bulk migration job CSV file that can be imported into the **SharePoint Migration Tool**. You supply the usernames, Office 365 tenant domain name, and the subfolder you want to put into a user's OneDrive directory.

An example of using it would be like this:

```powershell
PS \> .\Invoke-UserHomeMigrationBuilder.ps1 -UserName @("jdoe1", "jwinger", "pryan") -TenantName "contoso.com" -SPOSubFolder "UserHome Migration" -ExportPath ".\UserHomeDir-MigrationJob.csv"
```

This will create a CSV file in the current directory that is formatted to import into the **SharePoint Migration Tool**.

**NOTE**: The way this script works, it only checks the `HomeDirectory` property that is on the user's Active Directory object. If you map their home directory differently, you can re-tool it to fit your needs.