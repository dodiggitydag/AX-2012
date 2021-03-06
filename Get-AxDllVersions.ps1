﻿# Must be an Admin on all computers and the computers must be accessible from the calling computer
# Adapted from https://4sysops.com/archives/powershell-script-to-query-file-versions-on-remote-computers/
# .\Get-AxDllVersions.ps1 -ComputerName (Get-Content "Computers.txt")  | Export-csv "AX_DLL_Versions.csv" -NotypeInformation

[CmdletBinding()]
Param(
    [string[]]$ComputerName = $env:ComputerName
)

$OutputArr = @()
foreach($Computer in $ComputerName) {
    Write-Host "Querying file version on $Computer"
    
    if(Test-Connection -ComputerName $Computer -count 1 -quiet) {

        $FoldersToCheckForDlls = @()

        # Add Client DLL locations
        $FoldersToCheckForDlls += [string]::format("\\{0}\c`$\Program Files (x86)\Microsoft Dynamics AX\60\Client\Bin\*.dll", $Computer)
        $FoldersToCheckForDlls += [string]::format("\\{0}\c`$\Program Files (x86)\Microsoft Dynamics AX\60\Client\Bin\Connectors\*.dll", $Computer)
        $FoldersToCheckForDlls += [string]::format("\\{0}\c`$\Program Files (x86)\Microsoft Dynamics AX\60\Client\Share\Include\*.dll", $Computer)

        # Add Server DLL locations in C
        $TargetPath = [string]::format("\\{0}\c`$\Program Files\Microsoft Dynamics AX\60\Server\*", $Computer)
        $ServerFolders = Get-ChildItem $TargetPath | Where { $_.Name -ne "Common" }
        foreach ($AosServerFolder in $ServerFolders) {
            $FoldersToCheckForDlls += [string]::format("\\{0}\c`$\Program Files\Microsoft Dynamics AX\60\Server\{1}\bin\*.dll", $Computer, $AosServerFolder.Name)
            $FoldersToCheckForDlls += [string]::format("\\{0}\c`$\Program Files\Microsoft Dynamics AX\60\Server\{1}\bin\Connectors\*.dll", $Computer, $AosServerFolder.Name)
            $FoldersToCheckForDlls += [string]::format("\\{0}\c`$\Program Files\Microsoft Dynamics AX\60\Server\{1}\bin\Application\Share\Include\*.dll", $Computer, $AosServerFolder.Name)
        }

        # Add Server DLL locations in D
        $TargetPath = [string]::format("\\{0}\d`$\Program Files\Microsoft Dynamics AX\60\Server\*", $Computer)
        $ServerFolders = Get-ChildItem $TargetPath | Where { $_.Name -ne "Common" }
        foreach ($AosServerFolder in $ServerFolders) {
            $FoldersToCheckForDlls += [string]::format("\\{0}\d`$\Program Files\Microsoft Dynamics AX\60\Server\{1}\bin\*.dll", $Computer, $AosServerFolder.Name)
            $FoldersToCheckForDlls += [string]::format("\\{0}\d`$\Program Files\Microsoft Dynamics AX\60\Server\{1}\bin\Connectors\*.dll", $Computer, $AosServerFolder.Name)
            $FoldersToCheckForDlls += [string]::format("\\{0}\d`$\Program Files\Microsoft Dynamics AX\60\Server\{1}\bin\Application\Share\Include\*.dll", $Computer, $AosServerFolder.Name)
        }

        # Get list of DLLs
        Get-ChildItem $FoldersToCheckForDlls | Select-Object -Property FullName,DirectoryName,Name | % {
            $TargetDll = $_.FullName

            $OutputObj = New-Object -TypeName PSobject  
            $OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer 
            $OutputObj | Add-Member -MemberType NoteProperty -Name FileVersion -Value $null
            $OutputObj | Add-Member -MemberType NoteProperty -Name ProductVersion -Value $null
            $OutputObj | Add-Member -MemberType NoteProperty -Name OriginalName -Value $null
            $OutputObj | Add-Member -MemberType NoteProperty -Name FilePath -Value $Path
            $OutputObj | Add-Member -MemberType NoteProperty -Name FileDescription -Value $null
            $OutputObj | Add-Member -MemberType NoteProperty -Name ProductName -Value $null
            $OutputObj | Add-Member -MemberType NoteProperty -Name Status -Value $null

            $OutputObj.FilePath = $_.DirectoryName
            $OutputObj.OriginalName = $_.Name

            Write-Verbose "Retrieving $TargetDll file version"
            if(Test-Path $TargetDll) {
                try {
                    $VersionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($TargetDll)
                    $OutputObj.FileVersion = $VersionInfo.FileVersion
                    $OutputObj.ProductVersion = $VersionInfo.ProductVersion
                    $OutputObj.FileDescription = $VersionInfo.FileDescription
                    $OutputObj.ProductName = $VersionInfo.ProductName
                    $OutputObj.Status = "Success"
                    $OutputArr += $OutputObj
                } catch {
                    $OutputObj.Status = "Failed To Query"
                    $OutputArr += $OutputObj
                    Write-Warning "Failed to Query $TargetDll"
                }
            } else {
                $OutputObj.Status = "Path Not Accessible"
                $OutputArr += $OutputObj
                Write-Warning "Inaccessible: $TargetDll"
            }
        }

    } else {
        Write-Warning "$Computer Not Reachable"
    }
}

$OutputArr