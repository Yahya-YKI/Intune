$previousLocation = Get-Location
Set-Location -Path $PSScriptRoot

# Global Vars
$GlobalVarsPath = "..\..\GlobalVars.txt"
$GlobalVars = @{}
Get-Content $GlobalVarsPath | ForEach-Object {
    $variable, $value = ($_ -replace ' = ', '=') -split '='
    $GlobalVars[$variable] = $value
}

# Logs Vars
$appName = $MyInvocation.MyCommand.Name -replace '\.ps1$'
$currentDate = Get-Date
$logpath = $GlobalVars['logPath']+"$appName"
$logfile = "$logpath\log__"+$currentDate.ToString("dd-MM-yyyy__HH-mm")+".txt"
New-Item -ItemType Directory -Path $logpath -Force


# Function to check if registry values match desired values
function CheckRegistryValues($registryPath) {
    $subkeyValues = Get-ItemProperty -Path "$registryPath"
    if ($subkeyValues.HideFileExt -eq 0) {
        Write-Output "HideFileExt=0, no further actions needed." | Out-File -FilePath $logfile -Append
        return $true
    }
    return $false
}

# Edit Registry and Restart Explorer to show extensions
if (-not (CheckRegistryValues)) {
    Write-Output "HideFileExt!=0 or not exists, Setting it to 0." | Out-File -FilePath $logfile -Append
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
    if (CheckRegistryValues) {
        Write-Output "Registry key has been set to 0." | Out-File -FilePath $logfile -Append
    }else {
        Write-Output "Registry modification failed. Trying later" | Out-File -FilePath $logfile -Append
    }
    Stop-Process -Name explorer -Force
    Start-Process explorer
}

# Update last execution time
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
Set-Location $previousLocation

