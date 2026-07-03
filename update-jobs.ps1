param(
    [string]$Profile = 'rosina',
    [string]$CvPath,
    [ValidateSet('Ask', 'Manual', 'Recommended')]
    [string]$CriteriaMode = 'Ask',
    [switch]$Force,
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
if ($Profile -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
    throw 'Profile must be a lowercase ASCII slug, for example: ivan-petrov'
}

$TrackerDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $TrackerDir
$ProfileDir = Join-Path $TrackerDir "profiles\$Profile"
$PrivateDir = Join-Path $TrackerDir "private-cv\$Profile"
$LocalCv = Join-Path $PrivateDir 'cv.pdf'
$ProfileJson = Join-Path $ProfileDir 'profile.json'
$CriteriaJson = Join-Path $ProfileDir 'criteria.json'
$JobsJson = Join-Path $ProfileDir 'jobs.json'
$UpdatePrompt = Join-Path $TrackerDir 'prompts\update-jobs.md'
$CreatePrompt = Join-Path $TrackerDir 'prompts\create-profile.md'
$BuildScript = Join-Path $TrackerDir 'scripts\build-tracker.mjs'
$BackupRoot = Join-Path $TrackerDir '.backups'

function Write-Utf8NoBom([string]$Path, [string]$Text) {
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $encoding)
}

function Split-Answer([string]$Value) {
    return @($Value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Test-CriteriaComplete([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    try { $value = Get-Content -Raw -Encoding UTF8 -LiteralPath $Path | ConvertFrom-Json } catch { return $false }
    foreach ($key in @('locations','workModels','roles','seniority','employmentTypes')) {
        if (-not $value.$key -or @($value.$key).Count -eq 0) { return $false }
    }
    return $true
}

function Invoke-CodexPrompt([string]$PromptPath, [string]$Context) {
    $prompt = (Get-Content -Raw -Encoding UTF8 -LiteralPath $PromptPath) + "`n`n" + $Context
    $prompt | & codex exec -C $RootDir --sandbox workspace-write --skip-git-repo-check -
    if ($LASTEXITCODE -ne 0) { throw "Codex exited with code $LASTEXITCODE" }
}

function Invoke-ManualWizard {
    New-Item -ItemType Directory -Force $ProfileDir | Out-Null
    $displayName = Read-Host 'Candidate display name'
    if (-not $displayName) { $displayName = $Profile }
    $headline = Read-Host 'Professional headline'
    $locations = Split-Answer (Read-Host 'Locations, comma separated')
    $workModels = Split-Answer (Read-Host 'Work models, comma separated')
    $roles = Split-Answer (Read-Host 'Target roles, comma separated')
    $seniority = Split-Answer (Read-Host 'Seniority levels, comma separated')
    $employment = Split-Answer (Read-Host 'Employment types, comma separated')
    $salaryText = Read-Host 'Preferred net monthly salary in EUR (optional)'
    $languages = Split-Answer (Read-Host 'Languages, comma separated')
    $authorization = Read-Host 'Work authorization'
    $exclusions = Split-Answer (Read-Host 'Excluded industries, comma separated (optional)')
    $salary = 0; [void][int]::TryParse($salaryText, [ref]$salary)
    $today = Get-Date -Format 'yyyy-MM-dd'
    $profileObject = [ordered]@{ id=$Profile; displayName=$displayName; headline=$headline; createdDate=$today; updatedDate=$today }
    $criteriaObject = [ordered]@{ locations=$locations; workModels=$workModels; roles=$roles; seniority=$seniority; employmentTypes=$employment; salary=[ordered]@{preferredNetEurMonthly=$(if($salary -gt 0){$salary}else{$null});acceptableNetEurMonthly=$null;maximum=$null};languages=$languages;workAuthorization=$authorization;relocation=$false;excludedIndustries=$exclusions }
    Write-Utf8NoBom $ProfileJson (($profileObject | ConvertTo-Json -Depth 8) + "`n")
    Write-Utf8NoBom $CriteriaJson (($criteriaObject | ConvertTo-Json -Depth 8) + "`n")
    if (-not (Test-Path -LiteralPath $JobsJson)) { Write-Utf8NoBom $JobsJson "[]`n" }
}

foreach ($command in @('codex', 'node')) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "Required command '$command' was not found" }
}
foreach ($path in @($UpdatePrompt, $CreatePrompt, $BuildScript)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Required file was not found: $path" }
}

if ($CvPath) {
    if (-not (Test-Path -LiteralPath $CvPath -PathType Leaf)) { throw "CV file was not found: $CvPath" }
    if ([IO.Path]::GetExtension($CvPath) -ne '.pdf') { throw 'CV must be a PDF file' }
}

if ($CheckOnly) {
    if (-not (Test-Path -LiteralPath $ProfileDir)) { throw "Unknown profile '$Profile'. Pass -CvPath to create it." }
    foreach ($path in @($ProfileJson, $CriteriaJson, $JobsJson, $LocalCv)) { if (-not (Test-Path -LiteralPath $path)) { throw "Required profile file was not found: $path" } }
    if (-not (Test-CriteriaComplete $CriteriaJson)) { throw "Criteria are incomplete for profile '$Profile'" }
    Write-Host "Preflight passed: profile=$Profile" -ForegroundColor Green
    exit 0
}

$profileExisted = Test-Path -LiteralPath $ProfileDir
if (-not $profileExisted -and -not $CvPath) { throw "Unknown profile '$Profile'. Pass -CvPath to create it." }

if ($CvPath) {
    if ((Test-Path -LiteralPath $LocalCv) -and -not $Force) {
        $answer = Read-Host "Replace the existing CV for '$Profile'? (yes/no)"
        if ($answer -notmatch '^(y|yes)$') { throw 'CV replacement cancelled' }
    }
    New-Item -ItemType Directory -Force $PrivateDir | Out-Null
    Copy-Item -LiteralPath $CvPath -Destination $LocalCv -Force
}
if (-not (Test-Path -LiteralPath $LocalCv)) { throw "Private CV is missing for profile '$Profile': $LocalCv" }

if (-not (Test-CriteriaComplete $CriteriaJson)) {
    $mode = $CriteriaMode
    if ($mode -eq 'Ask') {
        $choice = Read-Host 'Criteria are missing. Choose 1=manual wizard or 2=Codex recommendations'
        $mode = if ($choice -eq '1') { 'Manual' } else { 'Recommended' }
    }
    if ($mode -eq 'Manual') { Invoke-ManualWizard }
    else { Invoke-CodexPrompt $CreatePrompt "PROFILE_ID=$Profile`nCV_PATH=job-tracker/private-cv/$Profile/cv.pdf`nPROFILE_DIR=job-tracker/profiles/$Profile" }
}

foreach ($path in @($ProfileJson, $CriteriaJson, $JobsJson)) { if (-not (Test-Path -LiteralPath $path)) { throw "Profile setup did not create: $path" } }
if (-not (Test-CriteriaComplete $CriteriaJson)) { throw "Criteria remain incomplete for profile '$Profile'" }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $BackupRoot "$Profile-$stamp"
New-Item -ItemType Directory -Force $backupDir | Out-Null
foreach ($path in @($ProfileJson, $CriteriaJson, $JobsJson)) { Copy-Item -LiteralPath $path -Destination $backupDir -Force }

try {
    Write-Host "Updating jobs for profile '$Profile'..." -ForegroundColor Cyan
    Invoke-CodexPrompt $UpdatePrompt "PROFILE_ID=$Profile`nCV_PATH=job-tracker/private-cv/$Profile/cv.pdf`nPROFILE_DIR=job-tracker/profiles/$Profile"
    Push-Location $RootDir
    try {
        & node --test job-tracker/tests/*.test.mjs
        if ($LASTEXITCODE -ne 0) { throw 'Tracker tests failed' }
        & node job-tracker/scripts/build-tracker.mjs
        if ($LASTEXITCODE -ne 0) { throw 'HTML build failed' }
    } finally { Pop-Location }
} catch {
    foreach ($name in @('profile.json','criteria.json','jobs.json')) {
        $backup = Join-Path $backupDir $name
        if (Test-Path -LiteralPath $backup) { Copy-Item -LiteralPath $backup -Destination (Join-Path $ProfileDir $name) -Force }
    }
    throw "Update failed; profile JSON restored from $backupDir. $($_.Exception.Message)"
}

Write-Host "Done: profile=$Profile; site=$TrackerDir\index.html" -ForegroundColor Green
