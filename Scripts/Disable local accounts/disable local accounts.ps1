Function GetAdminSID{
    $AdminSID = ""
    $executablePath = Join-Path -Path $PSScriptRoot -ChildPath "PsGetsid64.exe"
    $DomainSID = (Invoke-Expression "& '$executablePath' /accepteula" 2> $null)
    $AdminSID = $DomainSID[7]+"-500"
    return $AdminSID
}

Function GetUsersToDisable{
    $UsersToDisable=@()
    $AdminSID = GetAdminSID
    $UsersSID=Get-WmiObject -Class Win32_UserAccount
    $AuthenticatedUsers = (dir c:\users).Name

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
$UsersToDisable = GetUsersToDisable
if ($UsersToDisable.count -gt 0){
foreach ($user in $UsersToDisable)
{
    Disable-LocalUser -SID $User
}
}