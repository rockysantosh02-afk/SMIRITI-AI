@echo off
setlocal
set "BACKEND_DIR=%~dp0.."
pushd "%BACKEND_DIR%"
set "VENV_DIR=venv"
if exist venv312\Scripts\activate.bat set "VENV_DIR=venv312"

if not exist "%VENV_DIR%\Scripts\activate.bat" (
    echo [run] Virtual environment not found. Run scripts\setup.bat first.
    popd
    exit /b 1
)

call "%VENV_DIR%\Scripts\activate.bat"
set "PYTHONPATH=%CD%;%PYTHONPATH%"
echo [run] Starting SMRITI-AI API at http://127.0.0.1:8000
python -m uvicorn app.main:app --reload
set "EXIT_CODE=%errorlevel%"
popd
exit /b %EXIT_CODE%
