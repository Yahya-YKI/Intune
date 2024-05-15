$previousLocation = Get-Location
Set-Location -Path $PSScriptRoot

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

function SIDtoUsername($SID) {

    # Convert SID to NTAccount
    try {
        $userAccount = New-Object System.Security.Principal.SecurityIdentifier($SID)
        $userName = $userAccount.Translate([System.Security.Principal.NTAccount]).Value
        return $userName
    } catch {
        Write-Output "Failed to convert SID to username. Error: $_"  | Out-File -FilePath $logfile -Append
        return ""
    }

    
}

Function GetAdminSID{
    $AdminSID = ""
    $executablePath = Join-Path -Path $PSScriptRoot -ChildPath "PsGetsid64.exe"
    $DomainSID = (Invoke-Expression "& '$executablePath' /accepteula" 2> $null)
    $AdminSID = $DomainSID[7]+"-500"
    if ((SIDtoUsername -SID $AdminSID) -eq "" ) {
        Write-Output "Couldn't Detect Admin account, Aborting..."  | Out-File -FilePath $logfile -Append
        Exit -1
    }
    return $AdminSID
}

Function GetUsersToDisable{
    $UsersToDisable=@()
    $AdminSID = GetAdminSID
    $UsersSID=Get-WmiObject -Class Win32_UserAccount
    $AuthenticatedUsers = (Get-ChildItem c:\users).Name

    foreach ($user in $AuthenticatedUsers)
    {
        if ($user -in $UsersSID.Name) {
            if ((($UsersSID | Where-Object { $_.Name -eq $user }).SID -ne $AdminSID) -and ($UsersSID | Where-Object { $_.Name -eq $user }).Disabled ){
                $UsersToDisable += ($UsersSID | Where-Object { $_.Name -eq $user }).SID
            }
        }
    }
    return $UsersToDisable
}

#Disable Users
$UsersToDenyLogon = Get-WmiObject -Class Win32_UserAccount
$AdminSID = GetAdminSID
foreach ($user in $UsersToDenyLogon)
{
    if($user.SID -ne $AdminSID)
    {
        $scriptResult = .\Set-UserRights.ps1 -AddRight -Username $user.Caption -UserRight SeDenyInteractiveLogonRight
        Write-Output "$scriptResult" | Out-File -FilePath $logfile -Append
        Write-Output "The user "+$user.Caption+" has been added to `"SeDenyInteractiveLogonRight`" policy." | Out-File -FilePath $logfile -Append
    }

}

Set-Location -Path $previousLocation