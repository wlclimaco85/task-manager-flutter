param(
  [string]$Browser = "chrome",
  [string]$Port = "5200",
  [switch]$Headed,
  [switch]$AllScreens,
  [string]$BaseUrl = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..")
$VenvDir = Join-Path $ScriptDir ".venv"

if (-not (Test-Path $VenvDir)) {
  python -m venv $VenvDir
}

$Python = Join-Path $VenvDir "Scripts\python.exe"
& $Python -m pip install --upgrade pip
& $Python -m pip install -r (Join-Path $ScriptDir "requirements.txt")

$env:SELENIUM_BROWSER = $Browser
$env:SELENIUM_PORT = $Port
$env:SELENIUM_HEADLESS = if ($Headed) { "0" } else { "1" }
$env:SELENIUM_ALL_SCREENS = if ($AllScreens) { "1" } else { "0" }
if ($BaseUrl) {
  $env:SELENIUM_BASE_URL = $BaseUrl
}

Push-Location $RepoRoot
try {
  & $Python -m pytest $ScriptDir
}
finally {
  Pop-Location
}
