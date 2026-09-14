<#
.SYNOPSIS
    SecureNotes Demo Reset Tool (PowerShell)

.DESCRIPTION
    Restores any of the 4 demo states with one command.
    Optionally commits and pushes to GitHub to trigger the CI/CD pipeline.

    Usage:
        .\scripts\reset-demo.ps1 -State <state> [-Push]

    States:
        vulnerable         Hardcoded secret + python:3.8   (fails SonarCloud + Trivy)
        fixed              Clean code + python:3.12-slim   (all gates pass)
        agent-secret-only  Hardcoded secret only           (fails SonarCloud only)
        agent-image-only   python:3.8 only                 (fails Trivy only)

    Examples:
        .\scripts\reset-demo.ps1 -State vulnerable -Push
        .\scripts\reset-demo.ps1 -State fixed
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet("vulnerable", "fixed", "agent-secret-only", "agent-image-only")]
    [string]$State,

    [Parameter()]
    [switch]$Push
)

$ErrorActionPreference = "Stop"

# Resolve repo root whether called from root or scripts/ subdirectory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = if (Test-Path (Join-Path $scriptDir "..\demo-states")) {
    (Resolve-Path (Join-Path $scriptDir "..")).Path
} else {
    (Get-Location).Path
}

$stateDir   = Join-Path $repoRoot "demo-states\$State"
$targetApp  = Join-Path $repoRoot "app.py"
$targetDock = Join-Path $repoRoot "Dockerfile"

if (-not (Test-Path $stateDir)) {
    Write-Error "State directory not found: $stateDir"
    exit 1
}

Write-Host ""
Write-Host "==> Restoring SecureNotes to state: $State" -ForegroundColor Cyan

# Copy files — only if they exist in the snapshot
$appSrc  = Join-Path $stateDir "app.py"
$dockSrc = Join-Path $stateDir "Dockerfile"

if (Test-Path $appSrc) {
    Copy-Item $appSrc -Destination $targetApp -Force
    Write-Host "[OK]   app.py restored." -ForegroundColor Green
} else {
    Write-Host "[SKIP] app.py not in snapshot, keeping current." -ForegroundColor Yellow
}

if (Test-Path $dockSrc) {
    Copy-Item $dockSrc -Destination $targetDock -Force
    Write-Host "[OK]   Dockerfile restored." -ForegroundColor Green
} else {
    Write-Host "[SKIP] Dockerfile not in snapshot, keeping current." -ForegroundColor Yellow
}

if ($Push) {
    Write-Host ""
    Write-Host "==> Checking for changes to commit..." -ForegroundColor Cyan

    Push-Location $repoRoot
    try {
        # Check for actual diff before committing to avoid empty commits
        $diff = git diff --name-only app.py Dockerfile 2>&1
        if ($diff) {
            git add app.py Dockerfile
            git commit -m "demo: reset to $State state"
            git push origin main
            Write-Host ""
            Write-Host "[OK]   Pushed to GitHub. Pipeline will trigger shortly." -ForegroundColor Green
            Write-Host "[INFO] Watch at: https://github.com/Siddhantshukla1657/SecureNotes_Devops_Miniproject/actions" -ForegroundColor Cyan
        } else {
            Write-Host "[INFO] No changes detected — already in '$State' state. Nothing to push." -ForegroundColor Yellow
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host ""
    Write-Host "[INFO] Files updated locally. To push and trigger the pipeline:" -ForegroundColor Yellow
    Write-Host "       .\scripts\reset-demo.ps1 -State $State -Push"
}

Write-Host ""
