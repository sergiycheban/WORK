param(
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
$TrackerDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $TrackerDir
$PromptPath = Join-Path $TrackerDir 'prompts\update-jobs.md'
$DataPath = Join-Path $TrackerDir 'data\jobs.json'
$BuildPath = Join-Path $TrackerDir 'scripts\build-tracker.mjs'

foreach ($command in @('codex', 'node')) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        throw "Required command '$command' was not found. Install it and retry."
    }
}

foreach ($path in @($PromptPath, $DataPath, $BuildPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required file was not found: $path"
    }
}

if ($CheckOnly) {
    Write-Host 'Preflight passed: Codex, Node.js, and tracker files are available.' -ForegroundColor Green
    exit 0
}

Write-Host 'Searching for new jobs and checking the current list...' -ForegroundColor Cyan
$prompt = Get-Content -Raw -LiteralPath $PromptPath
$prompt | & codex exec -C $RootDir --sandbox workspace-write --skip-git-repo-check -
if ($LASTEXITCODE -ne 0) {
    throw "Codex exited with code $LASTEXITCODE. The HTML was not rebuilt by this command."
}

Write-Host 'Validating data and rebuilding HTML...' -ForegroundColor Cyan
Push-Location $RootDir
try {
    & node --test job-tracker/tests/*.test.mjs
    if ($LASTEXITCODE -ne 0) { throw 'Tracker tests failed.' }
    & node job-tracker/scripts/build-tracker.mjs
    if ($LASTEXITCODE -ne 0) { throw 'Failed to rebuild HTML.' }
}
finally {
    Pop-Location
}

Write-Host "Done: $TrackerDir\index.html" -ForegroundColor Green
