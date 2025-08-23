@echo off
setlocal

:: Check if Ollama is installed
where ollama >nul 2>nul
if %errorlevel% neq 0 (
    echo Ollama not found. Installing Ollama...

    :: Download Ollama installer (for Windows) and run it
    powershell -Command "Invoke-WebRequest -Uri https://ollama.com/download/OllamaSetup.exe -OutFile OllamaSetup.exe"
    start /wait OllamaSetup.exe /SILENT

    :: Cleanup installer
    del OllamaSetup.exe
) else (
    echo Ollama is already installed.
)

:: Ensure Python is installed
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo Python not found. Please install Python 3.9+ and rerun this script.
    exit /b 1
)

:: Create venv if not exists
if not exist venv (
    echo Creating virtual environment...
    python -m venv venv
)

:: Activate venv
call venv\Scripts\activate

:: Upgrade pip
python -m pip install --upgrade pip

:: Install requirements
if exist requirements.txt (
    echo Installing requirements...
    pip install -r requirements.txt
) else (
    echo requirements.txt not found!
)

echo Setup completed successfully!
endlocal
pause
