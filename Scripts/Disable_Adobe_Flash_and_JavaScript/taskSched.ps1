param (
    [Parameter(Mandatory = $true)]
    [string]$directoryPath,

    [Parameter(Mandatory = $true)]
    [string]$appName
)


# Check if the task already exists
$existingTask = Get-ScheduledTask -TaskName $appName -ErrorAction SilentlyContinue
if ($existingTask -ne $null) {
    Write-Host "Task '$appName' already exists. Exiting."
    Exit
}


# Define the path to the XML file
$xmlFilePath = "taskSched.xml"

# Read the XML content
$xmlContent = Get-Content -Path $xmlFilePath

# Define the full path to the script
$scriptPath = if ($directoryPath.EndsWith("\")) {
    "$directoryPath$appName\$appName.ps1"
} else {
    "$directoryPath\$appName\$appName.ps1"
}

# Define the arguments for the script
$arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""

# Replace <Arguments> and <URI> in the XML content
$xmlContent = $xmlContent -replace '<Arguments>.*</Arguments>', "<Arguments>$arguments</Arguments>"
$xmlContent = $xmlContent -replace '<URI>.*</URI>', "<URI>$scriptPath</URI>"

# Convert the XML content to a string
$xmlString = $xmlContent | Out-String

# Register the task in Task Scheduler
Register-ScheduledTask -Xml $xmlString -TaskName $appName -Force
