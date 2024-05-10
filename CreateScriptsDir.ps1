################################################################################
#                                                                              #
#   Author: YKI                                                                #
#   Date: 10-05-2024                                                           #
#   Purpose: This script creates a folder named ISSROAD in C:\ if it doesn't   #
#            exist, clones the GitHub repository 'Yahya-YKI/Intune' as a local #
#            branch named 'ISSROAD' if no .git folders are found, and restricts#
#            access to the folder to administrators and the SYSTEM account.    #
#                                                                              #
################################################################################

# Logs Vars
$appName = $MyInvocation.MyCommand.Name -replace '\.ps1$'
$currentDate = Get-Date
$logpath = "C:\Logs\$appName"
$logfile = "$logpath\log__"+$currentDate.ToString("dd-MM-yyyy__HH-mm")+".txt"
New-Item -ItemType Directory -Path $logpath -Force

# Script Vars
$previousLocation = Get-Location
$workingPath = "C:\ISSROAD\"
$pullPath = $workingPath+"Intune"
$repoUrl = "https://github.com/Yahya-YKI/Intune"
$branchName = "main"

# 1. Create folder named ISSROAD in C:\ if it doesn't exist and pull from remote git branch
$folderPath = "C:\ISSROAD"
if (Test-Path -Path $folderPath -PathType Container) {
    $gitFolders = Get-ChildItem -Path $folderPath -Force -Recurse -Filter ".git" -Directory
    if ($gitFolders.Count -eq 0) {
        # Delete and recreate ISSROAD folder if no .git folders are found
        Remove-Item -Path $folderPath -Recurse -Force
        New-Item -Path $folderPath -ItemType Directory
        # Clone branch
        Set-Location -Path $workingPath
        $result = git clone --branch $branchName $repoUrl 2>&1
        Write-Output $result | Out-File -FilePath $logfile -Append
    }
    else{
        # Update local branch with a pull
        $result = git -C $pullPath pull 2>&1
        Write-Output $result | Out-File -FilePath $logfile -Append
    }
} else {
    # Create ISSROAD folder if it doesn't exist
    New-Item -Path $folderPath -ItemType Directory
    # Clone branch
    Set-Location -Path $workingPath
    $result = git clone --branch $branchName $repoUrl 2>&1
    Write-Output $result | Out-File -FilePath $logfile -Append
}
Set-Location -Path "$pullPath\scripts"
Invoke-Expression "powershell.exe -ExecutionPolicy Bypass -File 'FolderAccessPermissions.ps1' -PathToSecure $workingPath"
Set-Location -Path $previousLocation
