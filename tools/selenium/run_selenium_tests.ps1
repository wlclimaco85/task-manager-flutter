param(
  [string]$Browser = "chrome",
  [string]$Port = "5200",
  [switch]$Headed,
  [switch]$AllScreens,
  [string]$BaseUrl = "",
  [string]$Projects = "client"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceRoot = Resolve-Path (Join-Path $ScriptDir "..\..\..")
$HarnessDir = Join-Path $WorkspaceRoot ".selenium-app-academia-e2e"
$VenvDir = Join-Path $HarnessDir ".venv"

if (-not (Test-Path $VenvDir)) {
  python -m venv $VenvDir
}

$Python = Join-Path $VenvDir "Scripts\python.exe"
& $Python -m pip install --upgrade pip -q
& $Python -m pip install -r (Join-Path $HarnessDir "requirements.txt") -q

$env:APP_ACADEMIA_BROWSER = $Browser
$env:APP_ACADEMIA_PORT = $Port
$env:APP_ACADEMIA_HEADLESS = if ($Headed) { "0" } else { "1" }
$env:APP_ACADEMIA_ALL_SCREENS = if ($AllScreens) { "1" } else { "0" }
$env:APP_ACADEMIA_PROJECTS = $Projects
if ($BaseUrl) {
  $env:APP_ACADEMIA_BASE_URL = $BaseUrl
  $env:APP_ACADEMIA_USE_EXTERNAL_URL = "1"
}

Push-Location $WorkspaceRoot
try {
  & $Python -m pytest (Join-Path $HarnessDir "tests") -v --no-header -p no:warnings
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}
finally {
  Pop-Location
}
