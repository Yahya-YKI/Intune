param (
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath,
    [Parameter(Mandatory=$true)]
    [string]$ScriptVersion,
    [Parameter(Mandatory=$true)]
    [string]$AppName
)


# Ensure directory path ends with "\" and remove all trailing spaces
$ScriptPath = $ScriptPath.TrimEnd()
if (-not $ScriptPath.EndsWith("\")) { $ScriptPath += "\" }




$AutomaticVariables = Get-Variable
function cmpv {
    Compare-Object (Get-Variable) $AutomaticVariables -Property Name -PassThru | Where -Property Name -ne "AutomaticVariables"
}


#$appName = "Disable_JavaScript_and_Flash_Adobe"
$appName = $AppName

$RegKey = "$appName.ps1"
$registryPath = "HKLM:\Software\ISSROAD\$RegKey"
$RegistryValueName = "LastUpdated"

# Check if the registry path exists
if (Test-Path $RegistryPath) {
return 0
} else {

    $directoryPath = $ScriptPath+$appName+'\'
    $logPath = $directoryPath+'Logs\'

    # Create the directory if it does not exist or recreate it if it exists without deleting its content
    New-Item -Path $directoryPath -ItemType Directory -Force
    New-Item -Path $logPath -ItemType Directory -Force

#    Stop-Transcript
    
    # Limit access to Scripts folder to only System account and admin group
    Invoke-Expression "powershell.exe -ExecutionPolicy Bypass -File 'FolderAccessPermissions.ps1' -ScriptPath $ScriptPath"
    
#    $logInstall = "log_$appName"+"_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
#    Start-Transcript -Path "C:\Logs\"+$logInstall -Append
    
    # Copy the main scripts from the IntuneWin package to the directory, overwriting existing files if necessary
    Copy-Item -Path ".\$appName.ps1" -Destination $directoryPath -Force
    Copy-Item -Path ".\UNINSTALL.ps1" -Destination $directoryPath -Force
    # Define the line to append to the uninstall script
    $newLine2 = '$appName = "'+$appName+'"'
    $newLine3 = '$directoryPath = "'+$directoryPath+'"'

    # Read the contents of the script file to add global variables to other scripts
    $UninstallFile = $directoryPath+'UNINSTALL.ps1'
    $existingContent_uninstall = Get-Content -Path "$UninstallFile" -Raw

    # Combine the new line and existing content
    $newContent2 = "$newLine2`n$newLine3`n$existingContent_uninstall"

    # Write the updated content back to the script file
    Set-Content -Path $UninstallFile -Value $newContent2

#    Stop-Transcript
	
    # Execute the script taskSched.ps1 with the -ExecutionPolicy Bypass parameter
    Invoke-Expression -Command "powershell.exe -ExecutionPolicy Bypass -File .\taskSched.ps1 -directoryPath  $ScriptPath -appName  $AppName"


    # Get the formatted date and time
    $script_exec_date = (Get-Date).ToString('dd/MM/yyyy - HH:mm')
    $registryPath = "HKLM:\Software\ISSROAD\$RegKey"
    $RegistryVersion = "Version"
    $RegistryInstallDate = "Installation_Date"
    $RegistryLastUpdate = "Last_Update"
    $RegistryLastExecuted = "LastExecuted"

    # Check if the registry path exists
    if (Test-Path $RegistryPath) {
    } else {
        # Create the registry path
        New-Item -Path $RegistryPath -Force
        
        # Add a key and set it to the current date
        Set-ItemProperty -Path $RegistryPath -Name $RegistryInstallDate -Value $script_exec_date
        Set-ItemProperty -Path $RegistryPath -Name $RegistryLastExecuted -Value ""
        Set-ItemProperty -Path $RegistryPath -Name $RegistryVersion -Value $ScriptVersion
        Set-ItemProperty -Path $RegistryPath -Name $RegistryLastUpdate -Value ""

    }


    $logInstall = "log_$appName"+"_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    cmpv > "C:\Logs\$logInstall"
}