param(
    [Parameter(Mandatory = $true)]
    [string] $AospRoot
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
if (-not $Wsl) {
    throw 'WSL2 is required for AOSP builds on Windows. Install an Ubuntu WSL2 distribution, then rerun this script.'
}

$LinuxProjectRoot = (& wsl.exe wslpath -a $ProjectRoot).Trim()
if ($LASTEXITCODE -ne 0 -or -not $LinuxProjectRoot) {
    throw 'Could not translate the project path into the default WSL2 distribution.'
}

& wsl.exe bash "$LinuxProjectRoot/build-android-userspace.sh" $AospRoot
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
