# Change $GamePath if you installed The Bureau to a different location
$GamePath = "C:\Program Files (x86)\Steam\steamapps\common\The Bureau"

$PhysXPath = "C:\Program Files (x86)\NVIDIA Corporation\PhysX\Engine"
$DllFile = "PhysXCore.dll"

$ErrorActionPreference = "Stop"

try {
    # Get the PhysXCore.dll with the highest version number
    $LatestDLL = Get-ChildItem -Path $PhysXPath -Filter $DllFile -File -Recurse |
    ForEach-Object {
        $DLLVersion = (Get-ItemProperty -Path $_.FullName).VersionInfo.FileVersion -replace ', ', '.'
        [PSCustomObject]@{
            FilePath    = $_.FullName
            FileVersion = [Version]$DLLVersion
        }
    } |
    Sort-Object FileVersion -Descending | Select-Object -First 1

    # Overwrite the game's PhysXCore.dll with the latest version.
    $Destination = Join-Path -Path $GamePath -ChildPath "Binaries\Win32"
    Copy-Item -Path $LatestDLL.FilePath -Destination $Destination -Force

    Write-Output "$DllFile version $($LatestDLL.FileVersion.ToString()) was successfully copied to $Destination"
}
catch {
    Write-Output 'An error occurred.  Please check paths assigned to $GamePath and $PhysXPath are valid.'
    exit 1
}