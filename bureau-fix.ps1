# This install path is only used if the installation location cannot be detected.
$Global:InstallPath = "C:\Program Files (x86)\Steam\steamapps\common\The Bureau"

$Global:PhysXPath = Join-Path ${env:ProgramFiles(x86)} "NVIDIA Corporation\PhysX"
$Global:PhysXDLL = "PhysXCore.dll"
$Global:RequiredVersion = "2.8.4.10"

class NVHandlerException : Exception {
    NVHandlerException([string] $message) : base($message) {}
}
class NVHandler {
    [string] $DLLPath
    [Hashtable] $DLLTable

    NVHandler([string] $DLLPath, [string] $DLLName) {
        $this.DLLTable = @{}
        $this.SetDLLPath($DLLPath)
        $this.EnumDLLs($DLLName)
    }

    [void] SetDLLPath([string] $DLLPath) {
        if (Test-Path $DLLPath -PathType Container) {
            $this.DLLPath = $DLLPath
        }
        else {
            throw [NVHandlerException]::new("$DLLPath does not exist")
        }
    }

    [void] EnumDLLs([string] $DLLName) {
        Get-ChildItem -Path $this.DLLPath -File -Recurse -Filter $DLLName | ForEach-Object {
            $DLLVersion = $this.VersionString($_.FullName) 
            $this.DLLTable[$DLLVersion] = $_.FullName
        }
    }

    [string] VersionString([string] $DLLName) {
        try {
            return  (Get-Item $DLLName).VersionInfo.FileVersion -replace ', ', '.'
        }
        catch {
            return [string]::Empty
        }
    }

    [string] FetchDLL([string] $Version) {
        return $this.DLLTable[$Version]
    }

}
class GameHandlerException : Exception {
    GameHandlerException([string] $message) : base($message) {}
}
class GameHandler {
    [string] $InstallPath
    [string] $DLLPath

    GameHandler() {
        $this.SetInstallPath()
        $this.SetDLLPath()
    }

    [void] SetInstallPath() {
        # Try to get install path from registry
        try {
            $RegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 65930'
            $RegistryKey = 'InstallLocation'
            $this.InstallPath = (Get-ItemProperty -Path $RegistryPath -ErrorAction SilentlyContinue).$RegistryKey
            # Otherwise, use hardcoded path
            if ([string]::IsNullOrEmpty($this.InstallPath)) {
                $this.InstallPath = $Global:InstallPath
            }
        }
        catch {
            $this.InstallPath = $Global:InstallPath
        }

        if (-not (Test-Path -Path $this.InstallPath)) {
            throw [GameHandlerException]::new('{0} does not exist' -f $this.InstallPath)
        }
    }

    [void] SetDLLPath() {
        $this.DLLPath = Join-Path -Path $this.InstallPath -ChildPath "Binaries\Win32"
        if (-not (Test-Path -Path $this.DLLPath)) {
            throw [GameHandlerException]::new('{0} does not exist' -f $this.DLLPath)
        }
    }

    [bool] ReplaceDLL([string] $SourceDLL) {
        try {
            Copy-Item -Path $SourceDLL -Destination $this.DLLPath -Force -ErrorAction stop
            return $true
        } catch {
            return $false
        }
    }
}

try {
    $NVMagic = [NVHandler]::new($Global:PhysXPath, $Global:PhysXDLL)
    $WorkingDLL = $NVMagic.FetchDLL($Global:RequiredVersion)

    if ([string]::IsNullOrEmpty($WorkingDLL)) {
        throw '{0} v{1} could not be found.' -f $Global:PhysXDLL, $Global:RequiredVersion
    }

    $GameMagic = [GameHandler]::new()
    if ($GameMagic.ReplaceDLL($WorkingDLL)){
        Write-Output ('{0} version {1} was successfully copied to {2}' -f $Global:PhysXDLL, $Global:RequiredVersion, $GameMagic.DLLPath)
    } else {
        throw 'Unable to copy {0} ({1}) to {2}' -f $WorkingDLL, $Global:RequiredVersion, $GameMagic.DLLPath
    }

}
catch [NVHandlerException] {
    Write-Error ('NVHandlerException: {0}. Please ensure PhysX is installed and $Global:PhysXPath reflects the correct path.' -f $_.Exception.Message)
    Exit 1
}
catch [GameHandlerException] {
    Write-Error ('GameHandlerException: {0}.' -f $_.Exception.Message)
    Exit 1
}
catch {
    Write-Error "An unexpected error occurred: $_"
    Exit 1
}