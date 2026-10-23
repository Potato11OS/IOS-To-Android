$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Refresh-Path {
    $MachinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$MachinePath;$UserPath"

    $GitCmd = Join-Path $env:ProgramFiles 'Git\cmd'
    if ((Test-Path (Join-Path $GitCmd 'git.exe')) -and ($env:Path -notlike "*$GitCmd*")) {
        $env:Path = "$GitCmd;$env:Path"
    }
}

function Install-WinGetPackage([string] $PackageId) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget is required to install $PackageId automatically. Install App Installer, then rerun setup.ps1."
    }

    & winget install --id $PackageId --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "winget could not install $PackageId (exit $LASTEXITCODE)."
    }
    Refresh-Path
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Install-WinGetPackage 'Git.Git'
}

$PythonLauncher = Get-Command py -ErrorAction SilentlyContinue
$PythonCommand = Get-Command python -ErrorAction SilentlyContinue
if (-not $PythonLauncher -and -not $PythonCommand) {
    Install-WinGetPackage 'Python.Python.3.13'
    $PythonLauncher = Get-Command py -ErrorAction SilentlyContinue
    $PythonCommand = Get-Command python -ErrorAction SilentlyContinue
}

$Bootstrap = Join-Path $ProjectRoot 'tools\bootstrap.py'
if ($PythonLauncher) {
    & py -3 $Bootstrap @args
} elseif ($PythonCommand) {
    & python $Bootstrap @args
} else {
    throw 'Python was installed, but this PowerShell session could not find it. Open a new terminal and rerun setup.ps1.'
}

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
