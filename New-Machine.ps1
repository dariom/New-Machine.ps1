[CmdletBinding()]
param ()

$ErrorActionPreference = 'Stop';

$IsAdmin = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    throw "You need to run this script elevated"
}

Write-Progress -Activity "Setting execution policy"
Set-ExecutionPolicy RemoteSigned

Write-Progress -Activity "Ensuring PS profile exists"
if (-not (Test-Path $PROFILE)) {
    New-Item $PROFILE -Force
}

Write-Progress -Activity "Ensuring Chocolatey is available"
$null = Get-PackageProvider -Name chocolatey

Write-Progress -Activity "Ensuring Chocolatey is trusted"
if (-not ((Get-PackageSource -Name chocolatey).IsTrusted)) {
    Set-PackageSource -Name chocolatey -Trusted
}

@(
    "googlechrome",
    "git.install",
    "putty.install",
    "fiddler4",
    "microsoft-teams",
    "nodejs.install",
    "vlc",
    "lastpass",
    "sourcetree",
    "vscode",
    "sql-server-management-studio",
    "linqpad5.install",
    "teamviewer",
    "adobereader",
    "7zip.install",
    "notepadplusplus.install",
    "sysinternals",
    "paint.net"
) | % {
    Write-Progress -Activity "Installing $_"
    Install-Package -Name $_ -ProviderName chocolatey
}

Write-Progress -Activity "Setting git identity"
$userName = (Get-WmiObject Win32_Process -Filter "Handle = $Pid").GetRelated("Win32_LogonSession").GetRelated("Win32_UserAccount").FullName
Write-Verbose "Setting git user.name to $userName"
git config --global user.name $userName
# This seems to the be MSA that was first used during Windows setup
$userEmail = (Get-WmiObject -Class Win32_ComputerSystem).PrimaryOwnerName
Write-Verbose "Setting git user.email to $userEmail"
git config --global user.email $userEmail

Write-Progress -Activity "Setting git push behaviour to squelch the 2.0 upgrade message"
if ((& git config push.default) -eq $null) {
    git config --global push.default simple
}

Write-Progress -Activity "Setting git aliases"
git config --global alias.st "status"
git config --global alias.co "checkout"
git config --global alias.cob "checkout -b"
git config --global alias.cm "!git add -A && git commit -m"
git config --global alias.df "diff"
git config --global alias.lg "log --graph --oneline --decorate"
git config --global alias.undo "reset HEAD~1 --mixed"

Write-Progress -Activity "Setting VS Code as the Git editor"
git config --global core.editor "code --wait"

Write-Progress -Activity "Installing PoshGit"
Install-Module posh-git -Scope CurrentUser
Add-PoshGitToProfile

Write-Progress "Enabling PowerShell on Win+X"
if ((Get-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\).DontUsePowerShellOnWinX -ne 0) {
    Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ -Name DontUsePowerShellOnWinX -Value 0
    Get-Process explorer | Stop-Process
}

Write-Progress "Making C:\Code"
if (-not (Test-Path C:\Code)) {
    New-Item C:\Code -ItemType Directory
}

Write-Progress "Making C:\Temp"
if (-not (Test-Path C:\Temp)) {
    New-Item C:\Temp -ItemType Directory
}

Write-Progress -Activity "Reloading PS profile"
. $PROFILE
