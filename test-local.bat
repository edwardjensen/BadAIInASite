@echo off
REM Windows batch script to build and test BadAIInASite container locally
REM This is a simplified version - use test-local.ps1 for full functionality

setlocal enabledelayedexpansion

set CONTAINER_NAME=badaiinasite-test
set IMAGE_NAME=badaiinasite-local-test
set LM_STUDIO_MODEL=local-model
set OPENROUTER_MODEL=google/gemini-2.0-flash-exp:free
set LM_STUDIO_ADDRESS=localhost
set PORT=3000

if "%1"=="--help" goto :help
if "%1"=="-h" goto :help
if "%1"=="help" goto :help
if "%1"=="stop" goto :stop
if "%1"=="logs" goto :logs

echo 🤖 BadAIInASite Local Test Script
echo =================================

REM Stop and remove existing container
echo 🔄 Stopping any existing test container...
docker stop %CONTAINER_NAME% 2>nul >nul
docker rm %CONTAINER_NAME% 2>nul >nul

REM Build the image
echo 🔄 Building Docker image...
docker build ^
  --build-arg DEFAULT_LMSTUDIO_MODEL=%LM_STUDIO_MODEL% ^
  --build-arg DEFAULT_OPENROUTER_MODEL=%OPENROUTER_MODEL% ^
  --build-arg BUILD_VERSION=local-test ^
  --build-arg BUILD_DATE=%date%T%time% ^
  --build-arg BUILD_COMMIT=local-test ^
  -t %IMAGE_NAME% .

if errorlevel 1 (
    echo ❌ Docker build failed
    exit /b 1
)

echo ✅ Image built successfully

REM Start the container
echo 🔄 Starting test container...
docker run -d ^
  --name %CONTAINER_NAME% ^
  -p %PORT%:3000 ^
  -e NODE_ENV=development ^
  -e LM_STUDIO_ADDRESS=%LM_STUDIO_ADDRESS% ^
  -e DEFAULT_LMSTUDIO_MODEL=%LM_STUDIO_MODEL% ^
  -e DEFAULT_OPENROUTER_MODEL=%OPENROUTER_MODEL% ^
  %IMAGE_NAME%

if errorlevel 1 (
    echo ❌ Failed to start container
    exit /b 1
)

timeout /t 3 /nobreak >nul

REM Check if container is running
docker ps -q -f name=%CONTAINER_NAME% >nul 2>nul
if errorlevel 1 (
    echo ❌ Container failed to start
    echo 📋 Container logs:
    docker logs %CONTAINER_NAME%
    exit /b 1
)

echo ✅ Container is running successfully
echo 🌐 Access the application at: http://localhost:%PORT%
echo ℹ️  View logs with: test-local.bat logs
echo ⏹️  Stop container with: test-local.bat stop

echo.
echo 📋 Initial container logs:
docker logs %CONTAINER_NAME%

echo.
echo 🎉 Test environment ready!
echo    Application: http://localhost:%PORT%
echo    LM Studio: http://%LM_STUDIO_ADDRESS%:1234
goto :end

:stop
echo 🔄 Stopping test container...
docker stop %CONTAINER_NAME% 2>nul
docker rm %CONTAINER_NAME% 2>nul
echo ✅ Test container stopped and removed
goto :end

:logs
echo 📋 Container logs:
docker logs %CONTAINER_NAME%
goto :end

:help
echo BadAIInASite Local Test Script (Windows Batch Version)
echo.
echo USAGE:
echo     test-local.bat [command]
echo.
echo COMMANDS:
echo     (none)    Build and run the test container
echo     stop      Stop and remove the test container
echo     logs      Show container logs
echo     help      Show this help message
echo.
echo CONFIGURATION:
echo     Edit the variables at the top of this script to customize:
echo     - LM_STUDIO_MODEL (default: local-model)
echo     - OPENROUTER_MODEL (default: google/gemini-2.0-flash-exp:free)
echo     - LM_STUDIO_ADDRESS (default: localhost)
echo     - PORT (default: 3000)
echo.
echo NOTE: For advanced options, use test-local.ps1 with PowerShell
goto :end

:end
