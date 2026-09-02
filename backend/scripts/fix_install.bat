@echo off
setlocal EnableExtensions
set "BACKEND_DIR=%~dp0.."
pushd "%BACKEND_DIR%"

set "VENV_DIR=venv"
if exist venv312\Scripts\activate.bat set "VENV_DIR=venv312"

if not exist "%VENV_DIR%\Scripts\activate.bat" (
    echo =============================================
    echo Smriti AI Backend - Fix Installation
    echo =============================================
    echo.
    echo No virtual environment found. Run scripts\setup.bat first.
    popd
    exit /b 1
)

call "%VENV_DIR%\Scripts\activate.bat"
set "PYTHONPATH=%CD%;%PYTHONPATH%"

echo =============================================
echo Smriti AI Backend - Fix Installation
echo =============================================
echo Using virtual environment: %VENV_DIR%
echo.

echo Step 1: Repairing pip...
python -m ensurepip --upgrade
if errorlevel 1 goto :error
python -m pip install --upgrade pip
if errorlevel 1 goto :error

echo.
echo Step 2: Removing problematic packages...
python -m pip uninstall firebase-admin uvicorn fastapi -y
if errorlevel 1 goto :error

echo.
echo Step 3: Installing project requirements...
python -m pip install -r requirements.txt
if errorlevel 1 goto :error

echo.
echo Step 4: Verifying installation...
python -c "import firebase_admin; import uvicorn; import uvicorn.middleware; import fastapi; print('All imports successful!')"
if errorlevel 1 goto :error

echo.
echo =============================================
echo Installation Complete!
echo =============================================
echo.
echo Next steps:
echo 1. Check your .env file has the correct Firebase settings.
echo 2. Place service-account-key.json in the backend folder.
echo 3. Run: python test_firebase.py
echo 4. Run: python test_firestore_service.py
echo 5. Start the API: scripts\run_dev.bat
popd
exit /b 0

:error
echo.
echo =============================================
echo Installation failed. Check the error above.
echo =============================================
popd
exit /b 1
