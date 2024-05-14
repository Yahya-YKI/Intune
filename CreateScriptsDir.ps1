################################################################################
#                                                                              #
#   Author: YKI                                                                #
#   Date: 10-05-2024                                                           #
#   Purpose: This script creates a folder named ISSROAD in C:\ if it doesn't   #
#            exist, clones the GitHub repository 'Yahya-YKI/Intune' as a local #
#            branch named 'ISSROAD' if no .git folders are found, and restricts#
#            access to the folder to administrators and the SYSTEM account.    #
#            It also registers a sched task that runs all configured ps in     #
#            DailyTasks.ps1 using DailyPowershellRunsTask.ps1.                 #
#            This script runs automatically from the intune app :              #
#            "#W#_   Prepare_Git_Env"                                          #
#                                                                              #
################################################################################

# Ensure Git Exists in PATH
Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1
refreshenv

$previousLocation = Get-Location
Set-Location -Path $PSScriptRoot

# Global Vars
$GlobalVarsPath = "GlobalVars.txt"
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
$folderPath = $GlobalVars['WorkingDir']
New-Item -ItemType Directory -Path $logpath -Force

# Script Vars
$workingPath = $folderPath
$pullPath = $workingPath+"Intune"
$repoUrl = $GlobalVars['repoUrl']
$branchName = $GlobalVars['branchName']

# Delete ISSROAD Folder from previous intune deployment (that wasn't based on github)
$RegKey = "$appName.ps1"
$registryPath = $GlobalVars['RegPath']+"$RegKey"

if ((Test-Path -Path $workingPath -PathType Container) -and !(Test-Path $registryPath)){
    Remove-Item -Path $workingPath -Recurse -Force
}

# 1. Create folder named ISSROAD in C:\ if it doesn't exist and pull from remote git branch
if (Test-Path -Path $folderPath -PathType Container) {
    $gitFolders = Get-ChildItem -Path $folderPath -Force -Recurse -Filter ".git" -Directory
    if ($gitFolders.Count -eq 0) {
        # Delete and recreate ISSROAD folder if no .git folders are found
        Remove-Item -Path $folderPath -Recurse -Force
        New-Item -Path $folderPath -ItemType Directory
        # Clone branch
        Set-Location -Path $workingPath
        $result = git clone --branch $branchName $repoUrl 2>&1
        Write-Output "This is not an error, just git output are of type stderr. $result" | Out-File -FilePath $logfile -Append
    }
    else{
        # Update local branch with a pull
        $result = git -C $pullPath pull 2>&1
        Write-Output Write-Output "This is not an error, just git output are of type stderr. $result" | Out-File -FilePath $logfile -Append
    }
} else {
    # Create ISSROAD folder if it doesn't exist
    New-Item -Path $folderPath -ItemType Directory
    # Clone branch
    Set-Location -Path $workingPath
    $result = git clone --branch $branchName $repoUrl 2>&1
    Write-Output "This is not an error, just git output are of type stderr. $result" | Out-File -FilePath $logfile -Append
}
Set-Location -Path "$pullPath\scripts"
# Refuse standard users access to C:\ISSROAD\ path
Invoke-Expression "powershell.exe -ExecutionPolicy Bypass -File 'FolderAccessPermissions.ps1' -PathToSecure $workingPath"
# Register the scheduled tasks for daily runs
Invoke-Expression "powershell.exe -ExecutionPolicy Bypass -File 'TaskSched\DailyPowershellRunsTask.ps1'"

Set-Location -Path $previousLocation


# Add or update a registry path to ensure detection of execution in intune
$RegKey = "$appName.ps1"
$registryPath = $GlobalVars['RegPath']+"$RegKey"
$RegistryLastExecuted = "LastExecuted"

# Check if the registry path exists
if (Test-Path $RegistryPath) {
    # Update the key to the current date
    Set-ItemProperty -Path $RegistryPath -Name $RegistryLastExecuted -Value $currentDate.ToString("dd-MM-yyyy__HH-mm")
} else {
    # Create the registry path
    New-Item -Path $RegistryPath -Force

    # Add a key and set it to the current date
    Set-ItemProperty -Path $RegistryPath -Name $RegistryLastExecuted -Value $currentDate.ToString("dd-MM-yyyy__HH-mm")
}
