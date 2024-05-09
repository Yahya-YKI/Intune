# Define variables
$RegKey = "$appName.ps1"
$registryPath = "HKLM:\Software\ISSROAD\$RegKey"
$scheduledTaskName = $appName

# Remove folder and its contents
Remove-Item -Path $directoryPath -Recurse -Force

# Remove scheduled task by name
Unregister-ScheduledTask -TaskName $scheduledTaskName -Confirm:$false

# Remove registry path
Remove-Item -Path $registryPath -Recurse -Force
