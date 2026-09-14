@echo off
setlocal

:: ============================================================
:: SecureNotes Demo Reset Tool
:: Usage: reset-demo.bat <state> [--push]
::
:: States:
::   vulnerable        - Hardcoded secret + python:3.8 (fails SonarCloud + Trivy)
::   fixed             - Clean code + python:3.12-slim (all gates pass)
::   agent-secret-only - Hardcoded secret only (fails SonarCloud, Trivy passes)
::   agent-image-only  - python:3.8 only (SonarCloud passes, Trivy fails)
:: ============================================================

set "STATE=%~1"
set "PUSH_FLAG=%~2"

if "%STATE%"=="" (
    echo.
    echo  Usage: reset-demo.bat ^<state^> [--push]
    echo.
    echo  States:
    echo    vulnerable         Hardcoded secret + python:3.8   ^(fails SonarCloud + Trivy^)
    echo    fixed              Clean code + python:3.12-slim   ^(all gates pass^)
    echo    agent-secret-only  Hardcoded secret only           ^(fails SonarCloud only^)
    echo    agent-image-only   python:3.8 only                 ^(fails Trivy only^)
    echo.
    echo  Add --push to also commit and push to GitHub and trigger the pipeline.
    echo.
    exit /b 1
)

set "STATE_DIR=demo-states\%STATE%"

if not exist "%STATE_DIR%\" (
    echo [ERROR] Unknown state: '%STATE%'
    echo Valid states: vulnerable, fixed, agent-secret-only, agent-image-only
    exit /b 1
)

echo.
echo [INFO] Restoring to state: %STATE%

:: Copy files (only if they exist in the state snapshot)
if exist "%STATE_DIR%\app.py" (
    copy /y "%STATE_DIR%\app.py" "app.py" >nul
    echo [OK]   app.py restored.
) else (
    echo [SKIP] app.py not in this snapshot, keeping current.
)

if exist "%STATE_DIR%\Dockerfile" (
    copy /y "%STATE_DIR%\Dockerfile" "Dockerfile" >nul
    echo [OK]   Dockerfile restored.
) else (
    echo [SKIP] Dockerfile not in this snapshot, keeping current.
)

if "%PUSH_FLAG%"=="--push" (
    echo.
    echo [INFO] Checking for changes to commit...
    git diff --quiet app.py Dockerfile 2>nul
    if errorlevel 1 (
        git add app.py Dockerfile
        git commit -m "demo: reset to %STATE% state"
        git push origin main
        echo [OK]   Pushed to GitHub. Pipeline will trigger shortly.
        echo [INFO] Watch it at: https://github.com/Siddhantshukla1657/SecureNotes_Devops_Miniproject/actions
    ) else (
        echo [INFO] No changes detected — already in '%STATE%' state. Nothing to push.
    )
) else (
    echo.
    echo [INFO] Files updated locally. To push and trigger the pipeline, run:
    echo        reset-demo.bat %STATE% --push
)

echo.
endlocal
