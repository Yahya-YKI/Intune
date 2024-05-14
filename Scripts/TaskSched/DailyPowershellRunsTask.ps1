################################################################################
#                                                                              #
#   Author: YKI                                                                #
#   Date: 10-05-2024                                                           #
#   Script: RegisterDailyTask.ps1                                              #
#   Purpose: This script registers a daily task in Windows Task Scheduler to   #
#            execute the DailyTasks.ps1 script located in the                  #
#            C:\ISSROAD\Intune\Scripts\TaskSched directory.                    #
#            The DailyTasks.ps1 has all the powershell files to run            #
#            The task is configured using the taskSched.xml template file.     #
#            If a task with the same name already exists, the script exits.    #
#            This script runs automatically from the script :                  #
#            "CreateScriptsDir.ps1"                                            #
#                                                                              #
################################################################################

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

# Script Vars
$previousLocation = Get-Location
$workingPath = Set-Location -Path $PSScriptRoot

Set-Location $workingPath # "C:\ISSROAD\Intune\Scripts\TaskSched"

# Check if the task already exists
$existingTask = Get-ScheduledTask -TaskName $appName -ErrorAction SilentlyContinue
if ($null -ne $existingTask) {
    Write-Output "Task '$appName' already exists. Exiting." | Out-File -FilePath $logfile -Append
    Set-Location $previousLocation
    Exit
}


# Define the path to the XML file
$xmlFilePath = "taskSched.xml"

# Read the XML content
$xmlContent = Get-Content -Path $xmlFilePath

# Define the full path to the script
$scriptPath = "$workingPath\DailyTasks.ps1"

# Define the arguments for the script
$arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""

# Replace <Arguments> and <URI> in the XML content
$xmlContent = $xmlContent -replace '<Arguments>.*</Arguments>', "<Arguments>$arguments</Arguments>"
$xmlContent = $xmlContent -replace '<URI>.*</URI>', "<URI>$scriptPath</URI>"
$xmlContent = $xmlContent -replace '<Date>.*</Date>', "<Date>$($currentDate.ToString("yyyy-MM-ddTHH:mm:ss"))</Date>"
$xmlContent = $xmlContent -replace '<StartBoundary>.*</StartBoundary>', "<StartBoundary>$($currentDate.ToString("yyyy-MM-ddTHH:mm:ss"))</StartBoundary>"


# Convert the XML content to a string
$xmlString = $xmlContent | Out-String

# Register the task in Task Scheduler
Register-ScheduledTask -Xml $xmlString -TaskName $appName -Force
