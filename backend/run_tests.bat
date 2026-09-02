@echo off
setlocal
pushd "%~dp0"
if exist venv312\Scripts\python.exe (set "PYTHON=venv312\Scripts\python.exe") else (set "PYTHON=python")
echo Running all Smriti AI tests...
%PYTHON% run_tests.py
set "CODE=%errorlevel%"
popd
exit /b %CODE%
