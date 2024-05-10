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

$previousLocation = Get-Location
$workingPath = "C:\ISSROAD\Intune"
$scriptsToExecute = @("Disable_JavaScript_and_Flash_Adobe.ps1")

Set-Location $workingPath

foreach ($script in $scriptsToExecute) {
    $matchingFile = Get-ChildItem -Path . -Recurse -Filter $script
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

