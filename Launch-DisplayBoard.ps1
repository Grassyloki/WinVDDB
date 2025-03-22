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

# Check for required dependencies
$AhkPath = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
if (-not (Test-Path -Path $AhkPath)) {
    Write-Host "AutoHotkey v2 not found at expected path: $AhkPath"
    Write-Host "Please install AutoHotkey v2 from https://www.autohotkey.com/download/2.0/"
    Write-Host "Aborting launch..."
    Exit 1
}

# Check for VirtualDesktopAccessor.dll
$DllPath = Join-Path -Path $WorkingDirectory -ChildPath "VirtualDesktopAccessor.dll"
if (-not (Test-Path -Path $DllPath)) {
    Write-Host "VirtualDesktopAccessor.dll not found at: $DllPath"
    Write-Host "Please ensure all required files are in the working directory."
    Write-Host "Aborting launch..."
    Exit 1
}

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

# Check for debug settings in config.toml
$DebugEnabled = $false
$KeepWindowsOpen = $false

try {
    # Check for the Powershell-TOML module and install if not present
    if (-not (Get-Module -Name Powershell-TOML -ListAvailable)) {
        Write-Host "Powershell-TOML module not found. Installing..."
        Install-Module -Name Powershell-TOML -Force -Scope CurrentUser
    }
    Import-Module Powershell-TOML
    
    # Load configuration to check for debug settings
    $Config = ConvertFrom-Toml -Path $ConfigPath
    
    # Extract debug settings if they exist
    if ($Config.ContainsKey("debug")) {
        if ($Config.debug.ContainsKey("enabled")) {
            $DebugEnabled = $Config.debug.enabled
        }
        
        if ($DebugEnabled -and $Config.debug.ContainsKey("keep_windows_open")) {
            $KeepWindowsOpen = $Config.debug.keep_windows_open
        }
    }
} catch {
    Write-Host "Warning: Unable to read debug settings from config file. Continuing with default settings."
}

# Launch the main script
Write-Host "Launching Windows Virtual Desktop Display Board..."
$MainScript = Join-Path -Path $WorkingDirectory -ChildPath "Run-VirtualDesktopsDisplayBoard.ps1"

# Set up process parameters
$processParams = @{
    FilePath = "powershell.exe"
    ArgumentList = "-ExecutionPolicy Bypass -File `"$MainScript`" -ConfigPath `"$ConfigPath`""
}

# If debug mode with keep windows open is enabled, use -NoExit
if ($DebugEnabled -and $KeepWindowsOpen) {
    $processParams.ArgumentList = "-NoExit " + $processParams.ArgumentList
    Write-Host "Debug mode with keep windows open is enabled."
}

Start-Process @processParams

Write-Host "Launcher completed."