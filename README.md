# The Bureau: XCOM Declassified PhysXCore.dll Fix

## Description
This PowerShell script resolves an issue in The Bureau: XCOM Declassified related to the PhysXCore.dll file. The script finds version 2.8.4.10 in your Nvidia PhysX folder and copies it to the game's installation folder. This should stop the game crashing when PhysX is enabled.


## Requirements
- Install NVIDIA drivers with PhysX support.
- Install The Bureau: XCOM Declassified.[^1] 🤨

## Installation

1. **Launch Powershell**.
2. **Download the Script** by pasting the following code[^2]:
```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/metamec/bureau-fix/master/bureau-fix.ps1 -OutFile ./bureau-fix.ps1
```
3. **Run the Script** by pasting the following code:
```powershell
./bureau-fix.ps1
```

[^1]: If you are not using the Steam version of the game, you must update the $Global:InstallPath variable to reflect the game's installation folder.
[^2]: Downloading via this method instead of a browser avoids execution policy issues associated with Zone.Identifier ADS.