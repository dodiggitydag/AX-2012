
.\Get-AxDllVersions.ps1 -ComputerName (Get-Content "C:\Users\dcalafell\Desktop\PowerShell\Computers - All.txt")  | Export-csv "c:\temp\AX_DLL_Versions.csv" -NoTypeInformation
#.\Get-AxDllVersions.ps1 -ComputerName ("AxTrain1","DaxDevMca1") | Export-csv "c:\temp\AX_DLL_Versions.csv" -NoTypeInformation
