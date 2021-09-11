function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    Write-Error "Script needs to be ran from an elevated command prompt."
}

Write-Host "Copying files..."
Copy-Item "..\Visual Studio IDE\VisualStudio.admx" "C:\Windows\PolicyDefinitions\VisualStudio.admx"
Copy-Item "..\Visual Studio IDE\en-US\VisualStudio.adml" "C:\Windows\PolicyDefinitions\en-US\VisualStudio.adml"
Write-Host "Done!"