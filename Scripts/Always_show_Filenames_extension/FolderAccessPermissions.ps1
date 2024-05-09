param (
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath
)
# Get the name of the local administrators group using its well-known SID
$AdminGroupName = (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")).Translate([System.Security.Principal.NTAccount]).Value

# Extract just the group name without "BUILTIN\"
$AdminGroupName = $AdminGroupName -replace "^BUILTIN\\"

# Define the path of the folder
$folderPath = $ScriptPath

# Get the security descriptor for the folder
$acl = Get-Acl -Path $folderPath

# Remove any inherited access rules
$acl.SetAccessRuleProtection($true, $false)

# Remove any existing access rules
$acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }

# Define a new access rule allowing SYSTEM full control with inheritance
$ruleSystem = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")

# Define a new access rule allowing administrators full control with inheritance
$ruleAdmin = New-Object System.Security.AccessControl.FileSystemAccessRule($AdminGroupName, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")

# Add the access rules to the security descriptor
$acl.AddAccessRule($ruleSystem)
$acl.AddAccessRule($ruleAdmin)

# Set the updated security descriptor for the folder
Set-Acl -Path $folderPath -AclObject $acl