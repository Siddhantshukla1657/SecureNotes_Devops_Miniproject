<#
.SYNOPSIS
    SecureNotes Demo Reset Tool (PowerShell)
    Restores any of the 4 demo states with one command and pushes to main.

.DESCRIPTION
    Usage: .\scripts\reset-demo.ps1 -State <vulnerable|fixed|agent-secret-only|agent-image-only> [-Push]

    States:
      - vulnerable        : Baseline with hardcoded secret + duplicate logic + python:3.8
      - fixed             : Clean code + hardened python:3.12-slim base
      - agent-secret-only : Hardcoded secret on clean base (demo code remediation)
      - agent-image-only  : Clean code on vulnerable python:3.8 (demo image remediation)
#>

[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateSet("vulnerable", "fixed", "agent-secret-only", "agent-image-only")]
    [string]$State,

    [Parameter()]
    [switch]$Push
)

$ErrorActionPreference = "Stop"

$stateDir = Join-Path "demo-states" $State

if (-not (Test-Path $stateDir)) {
    Write-Error "State directory '$stateDir' not found."
    exit 1
}

Write-Host "==> Restoring SecureNotes state to: $State" -ForegroundColor Cyan

# Copy snapshot files
Copy-Item (Join-Path $stateDir "app.py") -Destination "app.py" -Force
Copy-Item (Join-Path $stateDir "Dockerfile") -Destination "Dockerfile" -Force

Write-Host "==> Updated app.py and Dockerfile to match state '$State'." -ForegroundColor Green

if ($Push) {
    Write-Host "==> Committing and pushing state to git..." -ForegroundColor Cyan
    git add app.py Dockerfile
    
    $status = git status --porcelain app.py Dockerfile
    if (-not $status) {
        Write-Host "No changes detected. State is already up to date." -ForegroundColor Yellow
    } else {
        git commit -m "demo(state): switch demo baseline to '$State'"
        git push origin main
        Write-Host "==> Successfully pushed '$State' state to trigger CI/CD pipeline." -ForegroundColor Green
    }
} else {
    Write-Host "==> Local files updated. To push to GitHub and trigger CI/CD, run:" -ForegroundColor Yellow
    Write-Host "    git add app.py Dockerfile; git commit -m `"demo: switch to $State`"; git push origin main"
}
