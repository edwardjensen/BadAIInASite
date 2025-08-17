#!/usr/bin/env pwsh
# PowerShell script to build and test BadAIInASite container locally
# This script builds the container with custom model configurations and runs it for testing

param(
    [string]$LMStudioModel = "local-model",
    [string]$OpenRouterModel = "google/gemini-2.0-flash-exp:free",
    [string]$LMStudioAddress = "localhost",
    [string]$OpenRouterApiKey = "",
    [int]$Port = 3000,
    [switch]$NoBuild,
    [switch]$Stop,
    [switch]$Logs,
    [switch]$Help
)

$ContainerName = "badaiinasite-test"
$ImageName = "badaiinasite-local-test"

function Show-Help {
    Write-Host @"
BadAIInASite Local Test Script

USAGE:
    ./test-local.ps1 [OPTIONS]

OPTIONS:
    -LMStudioModel <model>      LM Studio model name (default: "local-model")
    -OpenRouterModel <model>    OpenRouter model name (default: "google/gemini-2.0-flash-exp:free")
    -LMStudioAddress <address>  LM Studio server address (default: "localhost")
    -OpenRouterApiKey <key>     OpenRouter API key (optional)
    -Port <port>                Local port to bind (default: 3000)
    -NoBuild                    Skip building, use existing image
    -Stop                       Stop and remove the test container
    -Logs                       Show container logs
    -Help                       Show this help message

EXAMPLES:
    # Build and run with default settings
    ./test-local.ps1

    # Test with specific LM Studio model
    ./test-local.ps1 -LMStudioModel "deepseek-r1-distill-llama-8b"

    # Test with OpenRouter fallback
    ./test-local.ps1 -OpenRouterApiKey "sk-or-..." -OpenRouterModel "deepseek/deepseek-r1-0528:free"

    # Test with remote LM Studio server
    ./test-local.ps1 -LMStudioAddress "192.168.1.100"

    # View logs
    ./test-local.ps1 -Logs

    # Stop test container
    ./test-local.ps1 -Stop

NOTES:
    - Container will be accessible at http://localhost:$Port
    - Use -NoBuild to skip rebuilding when testing configuration changes
    - Set OpenRouterApiKey to test cloud AI fallback functionality
"@
}

function Write-Step {
    param([string]$Message)
    Write-Host "🔄 $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Yellow
}

function Stop-TestContainer {
    Write-Step "Stopping and removing test container..."
    
    # Stop container if running
    $running = docker ps -q -f name=$ContainerName
    if ($running) {
        docker stop $ContainerName | Out-Null
        Write-Success "Container stopped"
    }
    
    # Remove container if exists
    $exists = docker ps -aq -f name=$ContainerName
    if ($exists) {
        docker rm $ContainerName | Out-Null
        Write-Success "Container removed"
    }
}

function Show-ContainerLogs {
    Write-Step "Showing container logs..."
    $exists = docker ps -aq -f name=$ContainerName
    if ($exists) {
        docker logs $ContainerName
    } else {
        Write-Error "Test container '$ContainerName' not found"
        exit 1
    }
}

function Build-Image {
    Write-Step "Building Docker image with custom model configuration..."
    Write-Info "LM Studio Model: $LMStudioModel"
    Write-Info "OpenRouter Model: $OpenRouterModel"
    
    $buildArgs = @(
        "--build-arg", "DEFAULT_LMSTUDIO_MODEL=$LMStudioModel",
        "--build-arg", "DEFAULT_OPENROUTER_MODEL=$OpenRouterModel",
        "--build-arg", "BUILD_VERSION=local-test",
        "--build-arg", "BUILD_DATE=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')",
        "--build-arg", "BUILD_COMMIT=local-test"
    )
    
    $buildCommand = @("docker", "build") + $buildArgs + @("-t", $ImageName, ".")
    
    Write-Host "Running: $($buildCommand -join ' ')" -ForegroundColor Gray
    
    & docker build $buildArgs -t $ImageName .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker build failed"
        exit 1
    }
    
    Write-Success "Image built successfully: $ImageName"
}

function Start-Container {
    Write-Step "Starting test container..."
    
    # Prepare environment variables
    $envVars = @(
        "-e", "NODE_ENV=development",
        "-e", "LM_STUDIO_ADDRESS=$LMStudioAddress",
        "-e", "DEFAULT_LMSTUDIO_MODEL=$LMStudioModel",
        "-e", "DEFAULT_OPENROUTER_MODEL=$OpenRouterModel"
    )
    
    # Add OpenRouter API key if provided
    if ($OpenRouterApiKey) {
        $envVars += @("-e", "OPENROUTER_API_KEY=$OpenRouterApiKey")
        Write-Info "OpenRouter API key configured"
    } else {
        Write-Info "No OpenRouter API key provided (local-only mode)"
    }
    
    # Run container
    $runCommand = @("docker", "run", "-d") + $envVars + @(
        "--name", $ContainerName,
        "-p", "${Port}:3000",
        "--restart", "no",
        $ImageName
    )
    
    Write-Host "Running: $($runCommand -join ' ')" -ForegroundColor Gray
    
    $containerId = & docker run -d $envVars --name $ContainerName -p "${Port}:3000" --restart no $ImageName
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start container"
        exit 1
    }
    
    Write-Success "Container started with ID: $($containerId.Substring(0,12))"
    
    # Wait a moment for container to start
    Start-Sleep -Seconds 3
    
    # Check if container is running
    $running = docker ps -q -f name=$ContainerName
    if ($running) {
        Write-Success "Container is running successfully"
        Write-Info "🌐 Access the application at: http://localhost:$Port"
        Write-Info "🔍 View logs with: ./test-local.ps1 -Logs"
        Write-Info "⏹️  Stop container with: ./test-local.ps1 -Stop"
        
        # Show initial logs
        Write-Host "`n📋 Initial container logs:" -ForegroundColor Magenta
        docker logs $ContainerName
    } else {
        Write-Error "Container failed to start"
        Write-Host "`n📋 Container logs:" -ForegroundColor Red
        docker logs $ContainerName
        exit 1
    }
}

# Main script logic
if ($Help) {
    Show-Help
    exit 0
}

if ($Stop) {
    Stop-TestContainer
    exit 0
}

if ($Logs) {
    Show-ContainerLogs
    exit 0
}

Write-Host "🤖 BadAIInASite Local Test Script" -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta

# Stop any existing test container
Stop-TestContainer

# Build image unless -NoBuild is specified
if (-not $NoBuild) {
    Build-Image
} else {
    Write-Info "Skipping build (using existing image: $ImageName)"
    
    # Check if image exists
    $imageExists = docker images -q $ImageName
    if (-not $imageExists) {
        Write-Error "Image '$ImageName' not found. Run without -NoBuild to build it first."
        exit 1
    }
}

# Start the container
Start-Container

Write-Host "`n🎉 Test environment ready!" -ForegroundColor Green
Write-Host "   Application: http://localhost:$Port" -ForegroundColor Green
Write-Host "   LM Studio: http://${LMStudioAddress}:1234" -ForegroundColor Green
