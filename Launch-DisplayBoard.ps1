# Launch-DisplayBoard.ps1
# Launcher script for the Windows Virtual Desktop Display Board
# This script activates on Virtual Desktop 1 and launches the main script

param (
    [string]$ConfigPath = "config.toml",
    [switch]$Debug = $false
)

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

# Check if PowerShell-TOML module can be installed
$ModuleInstalled = $false
try {
    # Try to install the module if not already available
    if (-not (Get-Module -Name PowerShell-TOML -ListAvailable)) {
        Write-Host "PowerShell-TOML module not found. Attempting to install..."
        
        # Check if PSGallery is available and registered
        $repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
        if (-not $repo) {
            Write-Host "PSGallery not found. Registering PSGallery..."
            Register-PSRepository -Default -ErrorAction SilentlyContinue
        }
        
        # Install the module
        Install-Module -Name PowerShell-TOML -Scope CurrentUser -Force -AllowClobber -ErrorAction SilentlyContinue
        
        if (Get-Module -Name PowerShell-TOML -ListAvailable) {
            $ModuleInstalled = $true
            Write-Host "PowerShell-TOML module installed successfully."
        } else {
            Write-Host "Unable to install PowerShell-TOML module. Will use manual TOML parsing."
        }
    } else {
        $ModuleInstalled = $true
        Write-Host "PowerShell-TOML module already installed."
    }
} catch {
    Write-Host "Error during module installation: $_"
    Write-Host "Will use manual TOML parsing instead."
}

# Function to manually extract value from TOML for basic debug settings
function Get-SimpleTomlValue {
    param (
        [string]$FilePath,
        [string]$Key,
        [object]$DefaultValue = $null
    )
    
    try {
        $content = Get-Content -Path $FilePath -Raw
        $pattern = "(?m)^\s*$Key\s*=\s*(true|false|\d+|""[^""]*"")"
        if ($content -match $pattern) {
            $value = $matches[1]
            
            # Convert string to appropriate type
            if ($value -eq "true") { return $true }
            elseif ($value -eq "false") { return $false }
            elseif ($value -match '^\d+$') { return [int]$value }
            elseif ($value -match '^"(.*)"$') { return $matches[1] }
            else { return $value }
        }
        return $DefaultValue
    } catch {
        Write-Host "Error reading TOML value: $_"
        return $DefaultValue
    }
}

# Check for config file
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
$DebugEnabled = $Debug.IsPresent
$KeepWindowsOpen = $false
$TranscriptLogging = $false
$LogPath = ""
$VerboseOutput = $false

try {
    # Try using PowerShell-TOML if installed
    if ($ModuleInstalled) {
        Import-Module PowerShell-TOML
        $Config = ConvertFrom-Toml -Path $ConfigPath
        
        # Extract debug settings if they exist
        if ($Config.ContainsKey("debug")) {
            if ($Config.debug.ContainsKey("enabled") -and !$Debug.IsPresent) {
                $DebugEnabled = $Config.debug.enabled
            }
            
            if ($DebugEnabled -and $Config.debug.ContainsKey("keep_windows_open")) {
                $KeepWindowsOpen = $Config.debug.keep_windows_open
            }
            
            if ($DebugEnabled -and $Config.debug.ContainsKey("transcript_logging")) {
                $TranscriptLogging = $Config.debug.transcript_logging
            }
            
            if ($DebugEnabled -and $Config.debug.ContainsKey("log_path")) {
                $LogPath = $Config.debug.log_path
            }
            
            if ($DebugEnabled -and $Config.debug.ContainsKey("verbose")) {
                $VerboseOutput = $Config.debug.verbose
            }
        }
    } else {
        # Fall back to basic parsing
        if (!$Debug.IsPresent) {
            $DebugEnabled = Get-SimpleTomlValue -FilePath $ConfigPath -Key "debug.enabled" -DefaultValue $false
        }
        
        if ($DebugEnabled) {
            $KeepWindowsOpen = Get-SimpleTomlValue -FilePath $ConfigPath -Key "debug.keep_windows_open" -DefaultValue $false
            $TranscriptLogging = Get-SimpleTomlValue -FilePath $ConfigPath -Key "debug.transcript_logging" -DefaultValue $false
            $LogPath = Get-SimpleTomlValue -FilePath $ConfigPath -Key "debug.log_path" -DefaultValue ""
            $VerboseOutput = Get-SimpleTomlValue -FilePath $ConfigPath -Key "debug.verbose" -DefaultValue $false
        }
    }
} catch {
    Write-Host "Warning: Unable to read debug settings from config file. Continuing with default settings."
}

if ($DebugEnabled) {
    Write-Host "Debug mode is enabled."
    if ($TranscriptLogging) {
        $TranscriptPath = if ($LogPath -ne "") { $LogPath } else { "$WorkingDirectory\WinVDDB_Launch_$(Get-Date -Format 'yyyyMMdd_HHmmss').log" }
        try {
            Start-Transcript -Path $TranscriptPath -Append
            Write-Host "Transcript logging started. Log file: $TranscriptPath"
        } catch {
            Write-Host "Error starting transcript: $_"
        }
    }
    
    if ($VerboseOutput) {
        Write-Host "Verbose output enabled."
        Write-Host "Debug settings: KeepWindowsOpen=$KeepWindowsOpen, TranscriptLogging=$TranscriptLogging"
        if ($LogPath -ne "") {
            Write-Host "Log path: $LogPath"
        }
    }
}

# Launch the main script
Write-Host "Launching Windows Virtual Desktop Display Board..."
$MainScript = Join-Path -Path $WorkingDirectory -ChildPath "Run-VirtualDesktopsDisplayBoard.ps1"

# Set up process parameters
$processParams = @{
    FilePath = "powershell.exe"
    ArgumentList = "-ExecutionPolicy Bypass -File `"$MainScript`" -ConfigPath `"$ConfigPath`""
}

# Add debug parameters if debug is enabled
if ($DebugEnabled) {
    $processParams.ArgumentList += " -DebugEnabled"
    
    if ($TranscriptLogging) {
        $processParams.ArgumentList += " -TranscriptLogging"
    }
    
    if ($LogPath -ne "") {
        $processParams.ArgumentList += " -LogPath `"$LogPath`""
    }
    
    if ($KeepWindowsOpen) {
        $processParams.ArgumentList += " -KeepWindowsOpen"
    }
    
    if ($VerboseOutput) {
        $processParams.ArgumentList += " -VerboseOutput"
    }
}

# If debug mode with keep windows open is enabled, use -NoExit
if ($DebugEnabled -and $KeepWindowsOpen) {
    $processParams.ArgumentList = "-NoExit " + $processParams.ArgumentList
    Write-Host "Debug mode with keep windows open is enabled."
}

Start-Process @processParams

Write-Host "Launcher completed."

if ($TranscriptLogging) {
    try {
        Stop-Transcript
    } catch {
        # Transcript might not be started
    }
}

if ($KeepWindowsOpen) {
    Write-Host ""
    Write-Host "Debug mode: Window will remain open. Press any key to exit..."
    [void][System.Console]::ReadKey($true)
}