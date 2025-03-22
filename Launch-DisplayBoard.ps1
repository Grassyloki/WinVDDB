# Launch-DisplayBoard.ps1
# Launcher script for the Windows Virtual Desktop Display Board
# This script activates on Virtual Desktop 1 and launches the main script

# Import required modules
Import-Module VirtualDesktop

# Ensure we're on desktop 1
Write-Host "Switching to Virtual Desktop 1..."
Set-DesktopIndex -Index 0  # Desktop index is 0-based, so 0 is the first desktop

# Set the working directory
$WorkingDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $WorkingDirectory
Write-Host "Working directory set to: $WorkingDirectory"

# Check for config file
$ConfigPath = Join-Path -Path $WorkingDirectory -ChildPath "config.toml"
if (-not (Test-Path -Path $ConfigPath)) {
    $ConfigExamplePath = Join-Path -Path $WorkingDirectory -ChildPath "config.toml.example"
    if (Test-Path -Path $ConfigExamplePath) {
        Write-Host "Configuration file not found. Creating from example..."
        Copy-Item -Path $ConfigExamplePath -Destination $ConfigPath
        Write-Host "Created config.toml from example. Please update with your settings and restart."
        Start-Process -FilePath "notepad.exe" -ArgumentList $ConfigPath
        Exit
    } else {
        Write-Host "Error: Configuration file not found and example not available."
        Write-Host "Please create a config.toml file based on documentation."
        Exit 1
    }
}

# Launch the main script
Write-Host "Launching Windows Virtual Desktop Display Board..."
$MainScript = Join-Path -Path $WorkingDirectory -ChildPath "Run-VirtualDesktopsDisplayBoard.ps1"
Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$MainScript`" -ConfigPath `"$ConfigPath`""

Write-Host "Launcher completed."