# Start the timer
$startTime = Get-Date

# Your script code here
# For example, let's wait for a few seconds to simulate script execution
Start-Sleep -Seconds 3

# Calculate the duration of running
$duration = ((Get-Date) - $startTime).TotalSeconds

# Generate the content for the text file
$content = "Script ran successfully in $duration seconds"

# Specify the path to the output file
$outputFile = "C:\Test_script.txt"

# Write the content to the output file
$content | Set-Content -Path $outputFile
