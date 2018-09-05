# AX-2012

A repository for reusable code related to AX 2012 deployment and maintenance.

## Get-AxDllVersions Cmdlet

Lists the versions for all DLLs which will load in AX.  Run this script against all clients (RDP/Citrix/end-user) and servers.  This is useful to confirm that all DLLs deployed match in file version.

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
