@echo off
setlocal
set "BACKEND_DIR=%~dp0.."
set "VENV_DIR=venv"
pushd "%BACKEND_DIR%"

if exist venv\Scripts\python.exe (
    venv\Scripts\python.exe -m pip --version >nul 2>nul
    if errorlevel 1 set "VENV_DIR=venv312"
)

echo [setup] Creating or repairing virtual environment: %VENV_DIR%
where py >nul 2>nul
if %errorlevel% equ 0 (
    py -3.12 -m venv "%VENV_DIR%"
) else (
    python -m venv "%VENV_DIR%"
)
if errorlevel 1 goto :error

call "%VENV_DIR%\Scripts\activate.bat"
echo [setup] Installing backend dependencies...
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
if errorlevel 1 goto :error

if not exist .env (
    copy /Y .env.example .env >nul
    echo [setup] Created .env from .env.example. Fill in local values before using Firebase.
) else (
    echo [setup] Existing .env preserved.
)

echo [setup] Setup complete.
echo [setup] Start the API with: scripts\run_dev.bat
popd
exit /b 0

:error
echo [setup] Setup failed. Check the error above.
popd
exit /b 1
