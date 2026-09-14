@echo off
setlocal

set "STATE=%~1"
set "PUSH_FLAG=%~2"

if "%STATE%"=="" (
    echo Usage: reset-demo.bat ^<vulnerable^|fixed^|agent-secret-only^|agent-image-only^> [--push]
    exit /b 1
)

set "STATE_DIR=demo-states\%STATE%"

if not exist "%STATE_DIR%" (
    echo [ERROR] State directory '%STATE_DIR%' not found.
    echo Valid states: vulnerable, fixed, agent-secret-only, agent-image-only
    exit /b 1
)

echo [INFO] Restoring SecureNotes state to: %STATE%
copy /y "%STATE_DIR%\app.py" "app.py" >nul
copy /y "%STATE_DIR%\Dockerfile" "Dockerfile" >nul
echo [OK] Overwrote app.py and Dockerfile with snapshot from '%STATE%'.

if "%PUSH_FLAG%"=="--push" (
    echo [INFO] Staging, committing, and pushing to origin main...
    git add app.py Dockerfile
    git commit -m "demo(state): switch demo baseline to '%STATE%'"
    git push origin main
    echo [OK] Pushed to GitHub main branch!
) else (
    echo.
    echo [INFO] Files updated locally. To push to GitHub, run:
    echo        git add app.py Dockerfile ^&^& git commit -m "demo: reset to %STATE%" ^&^& git push origin main
)
