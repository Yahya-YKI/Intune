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
function CheckRegistryValues($RegToCheck) {
     
    $subkeyValues = Get-ItemProperty -Path "$RegToCheck"
    if ($subkeyValues.HideFileExt -eq 0) {
        Write-Output "HideFileExt=0, no further actions needed." | Out-File -FilePath $logfile -Append
        return $true
    }
    return $false
}
# \Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders

function GetAllSIDs {

    $tmp_ListAllSIDs = Get-ChildItem "Registry::HKEY_USERS" | Where-Object { $_.PSIsContainer } | Select-Object -ExpandProperty Name
    $ListAllSIDs = @()
    for ($i = 0; $i -lt $tmp_ListAllSIDs.Count; $i++) {
        $tmp_ListAllSIDs[$i]=$tmp_ListAllSIDs[$i].split('\')[1]
        if(($tmp_ListAllSIDs[$i].Length -gt 30) -and ($tmp_ListAllSIDs[$i] -match '^S-\d{1,}-\d{1,}-\d{1,}-\d{1,}-\d{1,}-\d{1,}-\d{1,}$')){
            $ListAllSIDs+=$tmp_ListAllSIDs[$i]
        }
    }

    return $ListAllSIDs    
}

# Edit Registry and Restart Explorer to show extensions
$AllSIDs = GetAllSIDs
$RestartExplorer = $false
foreach ($SID in $AllSIDs) {
    <# $SID is the current item #>
    $RegToEdit = "registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (Test-Path $RegToEdit) {
        if (-not (CheckRegistryValues -RegToCheck $RegToEdit)) {
            Write-Output "HideFileExt!=0 or not exists, Setting it to 0." | Out-File -FilePath $logfile -Append
            Set-ItemProperty -Path $RegToEdit -Name "HideFileExt" -Value 0
            if (CheckRegistryValues -RegToCheck $RegToEdit) {
                Write-Output "Registry key has been set to 0." | Out-File -FilePath $logfile -Append
                $RestartExplorer=$true
            }else {
                Write-Output "Registry modification failed. Trying later" | Out-File -FilePath $logfile -Append
            }
    
        }
    }
}
if($RestartExplorer){
    Stop-Process -Name explorer -Force
    Start-Process explorer
}



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

