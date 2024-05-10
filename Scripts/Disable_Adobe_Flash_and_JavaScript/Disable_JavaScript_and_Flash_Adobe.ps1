$appName = $MyInvocation.MyCommand.Name -replace '\.ps1$'
$currentDate = Get-Date
$logpath = "C:\Logs\$appName"
$logfile = "$logpath\log__"+$currentDate.ToString("dd-MM-yyyy__hh-mm")+".txt"
New-Item -ItemType Directory -Path $logpath -Force
# Function to add missing registry key
function AddMissingRegistryKey($registryPath) {
    $newKeyPath = "$registryPath\FeatureLockDown"
    New-Item -Path $newKeyPath -Force | Out-Null
    Set-ItemProperty -Path $newKeyPath -Name "bDisableJavaScript" -Value 1
    Set-ItemProperty -Path $newKeyPath -Name "bEnableFlash" -Value 0
}

# Function to check if the script can execute based on last execution time
function CanExecuteScript {
    $lastExecFile = "LastExec.txt"
    if (-not (Test-Path -Path $lastExecFile)) {
        Write-Output "Debug : Line 18" | Out-File -FilePath $logfile -Append
        return $true
    }
    $lastExecTime = Get-Content -Path $lastExecFile
    $timeSinceLastExec = New-TimeSpan -Start $lastExecTime -End (Get-Date)
    Write-Output "Debug : Line 23 - "+$timeSinceLastExec.TotalHours | Out-File -FilePath $logfile -Append
    if ($timeSinceLastExec.TotalHours -ge 24) {
        Write-Output "Debug : Line 25" | Out-File -FilePath $logfile -Append
        return $true
    }
    return $false
}


# Check if the script can execute based on last execution time
if (-not (CanExecuteScript)) {
    Write-Output "Debug : Line 34" | Out-File -FilePath $logfile -Append
    Write-Output "Script has been executed within the last 24 hours. Exiting." | Out-File -FilePath $logfile -Append
    Exit
}


# Function to check if registry values match desired values
function CheckRegistryValues($registryPath) {
    $subkeyValues = Get-ItemProperty -Path "$registryPath\FeatureLockDown"
    if ($subkeyValues.bDisableJavaScript -eq 1 -and $subkeyValues.bEnableFlash -eq 0) {
        return $true
    }
    return $false
}


# Array of registry paths to check
$registryPaths = @(
    'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\DC',
    'HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC',
    'HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\11.0',
    'HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\10.0',
    'HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\9.0'
)

# Variables to store results
$registryRemediationsDetected = $false


# Loop through registry paths
foreach ($path in $registryPaths) {
    if (Test-Path -Path $path) {
        $newKeyAdded = $false
        
        # Check if the required subkey exists and values match, if not, add or fix it
        if (-not (Test-Path -Path "$path\FeatureLockDown") -or -not (CheckRegistryValues $path)) {
            AddMissingRegistryKey $path
            $newKeyAdded = $true
        }
        
        # Check the values of the subkey
        if (CheckRegistryValues $path) {
            $registryRemediationsDetected = $true
            if ($newKeyAdded) {
                Write-Output "Registry key added and correct values set for $($path)\FeatureLockDown"  | Out-File -FilePath $logfile -Append
            }
        }
    }
}

# Output result
if ($registryRemediationsDetected) {
    if ($newKeyAdded) {
        Write-Output "Registry Remediations Detected, Adobe is detected and now has been patched." | Out-File -FilePath $logfile -Append
    }
    else {
        Write-Output "Registry Remediations Detected, Adobe is already patched. No modifications needed." | Out-File -FilePath $logfile -Append
    }
} else {
    Write-Output "Registry Remediations not found! No Adobe instance found. Patching not required" | Out-File -FilePath $logfile -Append
}

# Update last execution time
$lastExecFile = Join-Path -Path $PSScriptRoot -ChildPath "LastExec.txt"
Set-Content -Path $lastExecFile -Value $currentDate


# Add or update a registry path to ensure detection of execution in intune
$RegKey = "$appName.ps1"
$registryPath = "HKLM:\Software\ISSROAD\$RegKey"
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

