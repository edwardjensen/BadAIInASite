# Testing Scripts

This folder contains scripts for testing the BadAIInASite application in Docker containers.

## Files

- **`test-local.sh`** - Unix/Linux/macOS testing script
- **`test-local.ps1`** - PowerShell testing script (cross-platform)
- **`test-local.bat`** - Windows batch testing script

## Purpose

These scripts allow you to:

1. **Build Docker images** of the application
2. **Test containerized deployments** locally
3. **Configure different AI models** and settings
4. **Simulate production environments**

## Usage

### macOS/Linux

```bash
cd testing
./test-local.sh
```

### Windows PowerShell

```powershell
cd testing
./test-local.ps1
```

### Windows Command Prompt

```cmd
cd testing
test-local.bat
```

## Configuration

The scripts support various configuration options:

- LM Studio model selection
- OpenRouter API key configuration
- Custom port binding
- Environment variable overrides

See each script's help output for detailed options:

```bash
./test-local.sh --help
./test-local.ps1 -Help
```

## Note

These scripts are designed for testing containerized deployments. For local development, use `npm start` from the project root.
