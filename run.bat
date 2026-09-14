@echo off
setlocal EnableDelayedExpansion

title SecureNotes - DevSecOps Demo Application
cls

echo =====================================================================
echo    SecureNotes - DevSecOps Demo Application Launcher
echo =====================================================================
echo.

:: Detect Python executable (try python, then py launcher)
set "PY_CMD="
python --version >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "PY_CMD=python"
) else (
    py --version >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        set "PY_CMD=py"
    )
)

if "%PY_CMD%"=="" (
    echo [ERROR] Python was not found on your system PATH.
    echo Please install Python 3.8+ from https://www.python.org/ or Microsoft Store.
    echo Make sure to check "Add Python to PATH" during installation.
    echo.
    pause
    exit /b 1
)

echo [OK] Detected Python executable: %PY_CMD%

:: Check and activate virtual environment if present
if exist "venv\Scripts\activate.bat" (
    echo [INFO] Activating virtual environment: venv
    call venv\Scripts\activate.bat
    set "PY_CMD=python"
) else if exist ".venv\Scripts\activate.bat" (
    echo [INFO] Activating virtual environment: .venv
    call .venv\Scripts\activate.bat
    set "PY_CMD=python"
)

:: Quick dependency check: test if flask is importable
%PY_CMD% -c "import flask, dotenv" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [INFO] Installing required packages from requirements.txt...
    %PY_CMD% -m pip install -r requirements.txt
    if %ERRORLEVEL% neq 0 (
        echo [WARNING] Pip install returned an error. Attempting to start anyway...
    )
)

echo.
echo [INFO] Starting SecureNotes Flask Server on http://localhost:5000
echo [INFO] Press CTRL+C at any time in this window to stop the server.
echo =====================================================================
echo.

:: Launch browser in background after short delay
start "" cmd /c "timeout /t 2 /nobreak >nul && start http://localhost:5000"

:: Run the Flask server
%PY_CMD% app.py

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Application exited with error code %ERRORLEVEL%.
    pause
)
