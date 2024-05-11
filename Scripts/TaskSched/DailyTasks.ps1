# Ensure Git Exists in PATH
Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1
refreshenv

# Logs Vars
$appName = $MyInvocation.MyCommand.Name -replace '\.ps1$'
$currentDate = Get-Date
$logpath = "C:\Logs\$appName"
$logfile = "$logpath\log__"+$currentDate.ToString("dd-MM-yyyy__HH-mm")+".txt"
New-Item -ItemType Directory -Path $logpath -Force

# Pull latest changes from remote branch
$result = git -C "C:\ISSROAD\Intune\" pull 2>&1
Write-Output "Result of Git Pull : $result" | Out-File -FilePath $logfile -Append

# A function that sanitizes the input scripts name imported from ScriptsToRun.txt file
function Sanitize {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScriptName
    )
    # Check if the string doesn't end with ".ps1", and if so, append it
    $oldName =$ScriptName
    if (-not $ScriptName.EndsWith(".ps1")) {
        $ScriptName += ".ps1"

    }
    # Remove "\" or "/" characters from the string
    $ScriptName = $ScriptName -replace '[\\/\:]', ''

    if (-not ($oldName -eq $ScriptName)) {
        Write-Output "Warning : ScriptName ""$oldName"" has been sanitized to ""$ScriptName""" | Out-File -FilePath $logfile -Append
        Write-Output "Please input the filename with extension (ps1) only. no path is needed" | Out-File -FilePath $logfile -Append
    }
    
    return $ScriptName
}

$previousLocation = Get-Location
$workingPath = "C:\ISSROAD\Intune"

Set-Location $workingPath
$scriptsToExecutePath = "Scripts\TaskSched\ScriptsToRun.txt"  

$scriptsToExecute = Get-Content -Path $scriptsToExecutePath | Where-Object { $_ -notmatch '^\s*(#|$)' }
foreach ($script in $scriptsToExecute) {
    $matchingFile = Get-ChildItem -Path . -Recurse -Filter (Sanitize -ScriptName $script)
    if ($matchingFile) {
        # Get the full path of the file
        $fullPath = $matchingFile.FullName
        Write-Output "Full path of '$script': $fullPath" | Out-File -FilePath $logfile -Append
        Write-Output "Executing the script '$script'" | Out-File -FilePath $logfile -Append
        Invoke-Expression "powershell.exe -ExecutionPolicy Bypass -File $fullPath -PathToSecure $workingPath"
        Write-Output "'$script' has been executed, check its log to see its execution status." | Out-File -FilePath $logfile -Append
    } else {
        Write-Output "No file named '$script' found within the current directory and its subdirectories." | Out-File -FilePath $logfile -Append
    }
}

Set-Location $previousLocation

