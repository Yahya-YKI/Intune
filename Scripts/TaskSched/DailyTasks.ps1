# Ensure Git Exists in PATH
Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1
refreshenv

# Logs Vars
$appName = $MyInvocation.MyCommand.Name -replace '\.ps1$'
$currentDate = Get-Date
$logpath = "C:\Logs\$appName"
$logfile = "$logpath\log__"+$currentDate.ToString("dd-MM-yyyy__HH-mm")+".txt"
$repositoryPath = "C:\ISSROAD\Intune"
New-Item -ItemType Directory -Path $logpath -Force

# Define the path you want to check
$folderPath = "C:\ISSROAD"
$gitFolders = Get-ChildItem -Path $folderPath -Force -Recurse -Filter ".git" -Directory
$rebuildLocaBranch = $false

# Check if the folder exists and contains a ".git" folder
if (Test-Path -Path $repositoryPath -PathType Container) {
    if ($gitFolders.Count -gt 0) {
        Write-Output "Local Branch Healty! Start pulling process."
        # Step 1: Discard local changes in the branch
        git -C $repositoryPath checkout HEAD -- . 2>&1

        # Step 2: Reset the branch to the state of the remote repository
        git -C $repositoryPath fetch origin 2>&1
        git -C $repositoryPath reset --hard 2>&1

        # Step 3: Pull changes from the remote repository
        git -C $repositoryPath pull  2>&1
        Write-Output "Result of Git Pull : $result" | Out-File -FilePath $logfile -Append

        # Step 3: Run Scripts
        Invoke-Expression "powershell.exe -ExecutionPolicy Bypass -File '$repositoryPath\Scripts\TaskSched\Helper.ps1' -logfile $logfile"
    }else {
        $rebuildLocaBranch = $true
    }
}else {
    $rebuildLocaBranch = $true
}
if ($rebuildLocaBranch) {
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Yahya-YKI/Intune/main/CreateScriptsDir.ps1' -OutFile 'C:\Windows\Temp\CreateScriptsDir.ps1'
    Invoke-Expression "powershell.exe -ExecutionPolicy Bypass -File 'C:\Windows\Temp\CreateScriptsDir.ps1'"
    Remove-Item -Path "C:\Windows\Temp\CreateScriptsDir.ps1" -Force
    Invoke-Expression "powershell.exe -ExecutionPolicy Bypass -File '$repositoryPath\Scripts\TaskSched\Helper.ps1' -logfile $logfile"
}



