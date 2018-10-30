# AX-2012

A repository for reusable code related to AX 2012 administration and maintenance.

## The Ultimate AX 2012 Table and Field ID Fix for Synchronization Errors

This script fixes both Table and Field IDs in SqlDictionary (data db) to match the AX code (Model db).  Useful for after a database has been restored and the table or field IDs do not match. Instead of letting the database synchronization process drop and recreate the table, just run this SQL Script!


## Get-AxDllVersions Cmdlet

Lists the versions for all the DLLs which will load in AX.  It checks nine locations on every computer provided to the command.  Run this script against all clients (RDP/Citrix/end-user) and servers.  This can be used to confirm that all DLLs deployed match in file version.

### Example 1: Export DLL Versions for Local Machine

```powershell
.\Get-AxDllVersions.ps1
```
Example single value:

> ComputerName    : Server1
> FileVersion     : 6.3.5000.3084
> ProductVersion  : 6.3.5000.3084
> OriginalName    : Microsoft.Dynamics.Retail.TestConnector.dll
> FilePath        : \\DAXDEVMCA1\c$\Program Files\Microsoft Dynamics AX\60\Server\Server1\bin\Connectors
> FileDescription :  
> ProductName     : Microsoft Dynamics AX
> Status          : Success

### Example 2: Retrieving Multiple Server DLL Versions

```powershell
.\Get-AxDllVersions.ps1 -ComputerName "Server1","Server2"
```

### Example 3: Export Multiple Server DLL Versions to CSV

```powershell
.\Get-AxDllVersions.ps1 -ComputerName (Get-Content "ComputerList.txt")  | Export-csv "c:\temp\AX_DLL_Versions.csv" -NotypeInformation
```

### Requirements
The script must be run as an account having Administrator access all computers.  The script will skip any offline/inaccessible computers.
