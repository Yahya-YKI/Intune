﻿$appName = $MyInvocation.MyCommand.Name -replace '\.ps1$'
# Function to add missing registry key
function AddMissingRegistryKey($registryPath) {
    New-Item -Path $registryPath -Force | Out-Null
    Set-ItemProperty -Path $newKeyPath -Name "HideFileExt" -Value 0
}



# Function to check if registry values match desired values
function CheckRegistryValues($registryPath) {
    $subkeyValues = Get-ItemProperty -Path "$registryPath"
    if ($subkeyValues.HideFileExt -eq 0) {
        return $true
    }
    return $false
}

# Edit Registry and Restart Explorer to show extensions
if (-not (CheckRegistryValues)) {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
    Stop-Process -Name explorer -Force
    Start-Process explorer
}

# Update last execution time
$currentDate = Get-Date
$lastExecFile = Join-Path -Path $PSScriptRoot -ChildPath "LastExec.txt"
Set-Content -Path $lastExecFile -Value $currentDate


# Add or update a registry path to ensure detection of execution in intune
$RegKey = "$appName.ps1"
$registryPath = $GlobalVars['RegPath']+"$RegKey"
$RegistryLastExecuted = "LastExecuted"

# Check if the registry path exists
if (Test-Path $RegistryPath) {
    # Update the key to the current date
    Set-ItemProperty -Path $RegistryPath -Name $RegistryLastExecuted -Value $currentDate
} else {
    # Create the registry path
    New-Item -Path $RegistryPath -Force

    # Add a key and set it to the current date
    Set-ItemProperty -Path $RegistryPath -Name $RegistryLastExecuted -Value $currentDate
}

