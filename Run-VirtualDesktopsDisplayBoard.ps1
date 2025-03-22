# Run-VirtualDesktopsDisplayBoard.ps1
# Main script for Windows Virtual Desktop Display Board

param (
    [string]$ConfigPath = "config.toml"
)

# Debug variables
$DebugEnabled = $false
$TranscriptLogging = $false
$LogPath = ""
$KeepWindowsOpen = $false
$VerboseOutput = $false

Write-Host "Starting Windows Virtual Desktop Display Board"

# Function to manually extract value from TOML for basic settings
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

# Check for VirtualDesktop module - but we won't use it directly for desktop count
# We'll use ahk instead
$VirtualDesktopModuleAvailable = $false
try {
    if (Get-Module -Name VirtualDesktop -ListAvailable) {
        Import-Module VirtualDesktop -ErrorAction SilentlyContinue
        $VirtualDesktopModuleAvailable = $true
    } else {
        Write-Host "VirtualDesktop module not available. Will use alternative methods."
    }
} catch {
    Write-Host "Error loading VirtualDesktop module: $_"
}

# Check for PowerShell-TOML module
$TomlModuleAvailable = $false
try {
    if (Get-Module -Name PowerShell-TOML -ListAvailable) {
        Import-Module PowerShell-TOML -ErrorAction SilentlyContinue
        $TomlModuleAvailable = $true
    } else {
        Write-Host "PowerShell-TOML module not available. Will use simple parsing."
    }
} catch {
    Write-Host "Error loading PowerShell-TOML module: $_"
}

# Load configuration
try {
    Write-Host "Loading configuration from $ConfigPath"
    
    if ($TomlModuleAvailable) {
        $Config = ConvertFrom-Toml -Path $ConfigPath
        
        # Extract general settings
        $WorkingDirectory = $Config.general.working_directory
        $TotalDisplays = $Config.general.total_displays
        $StartingDisplay = $Config.general.starting_display
        $DllPath = $Config.general.dll_path
        $AhkPath = $Config.general.ahk_path
        
        # Extract debug settings if they exist
        if ($Config.ContainsKey("debug")) {
            if ($Config.debug.ContainsKey("enabled")) {
                $DebugEnabled = $Config.debug.enabled
            }
            
            if ($DebugEnabled -and $Config.debug.ContainsKey("transcript_logging")) {
                $TranscriptLogging = $Config.debug.transcript_logging
            }
            
            if ($DebugEnabled -and $Config.debug.ContainsKey("log_path")) {
                $LogPath = $Config.debug.log_path
            }
            
            if ($DebugEnabled -and $Config.debug.ContainsKey("keep_windows_open")) {
                $KeepWindowsOpen = $Config.debug.keep_windows_open
            }
            
            if ($DebugEnabled -and $Config.debug.ContainsKey("verbose")) {
                $VerboseOutput = $Config.debug.verbose
            }
        }
    } else {
        # Use simple parsing
        $WorkingDirectory = Get-SimpleTomlValue -FilePath $ConfigPath -Key "general.working_directory" -DefaultValue "C:\Scripts"
        $TotalDisplays = Get-SimpleTomlValue -FilePath $ConfigPath -Key "general.total_displays" -DefaultValue 6
        $StartingDisplay = Get-SimpleTomlValue -FilePath $ConfigPath -Key "general.starting_display" -DefaultValue 2
        $DllPath = Get-SimpleTomlValue -FilePath $ConfigPath -Key "general.dll_path" -DefaultValue "C:\Scripts\VirtualDesktopAccessor.dll"
        $AhkPath = Get-SimpleTomlValue -FilePath $ConfigPath -Key "general.ahk_path" -DefaultValue "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
        
        # Extract debug settings
        $DebugEnabled = Get-SimpleTomlValue -FilePath $ConfigPath -Key "debug.enabled" -DefaultValue $false
        if ($DebugEnabled) {
            $TranscriptLogging = Get-SimpleTomlValue -FilePath $ConfigPath -Key "debug.transcript_logging" -DefaultValue $false
            $LogPath = Get-SimpleTomlValue -FilePath $ConfigPath -Key "debug.log_path" -DefaultValue ""
            $KeepWindowsOpen = Get-SimpleTomlValue -FilePath $ConfigPath -Key "debug.keep_windows_open" -DefaultValue $false
            $VerboseOutput = Get-SimpleTomlValue -FilePath $ConfigPath -Key "debug.verbose" -DefaultValue $false
        }
    }
    
    # If working directory is not the current directory, update it
    if ($WorkingDirectory -ne (Get-Location).Path) {
        try {
            if (Test-Path -Path $WorkingDirectory) {
                Set-Location -Path $WorkingDirectory
                Write-Host "Changed working directory to: $WorkingDirectory"
            } else {
                Write-Host "Warning: Configured working directory '$WorkingDirectory' does not exist. Using current directory."
                $WorkingDirectory = (Get-Location).Path
            }
        } catch {
            Write-Host "Error changing working directory: $_"
            $WorkingDirectory = (Get-Location).Path
        }
    }
    
    # Start transcript logging if enabled
    if ($TranscriptLogging) {
        $TranscriptPath = if ($LogPath -ne "") { $LogPath } else { "$WorkingDirectory\WinVDDB_$(Get-Date -Format 'yyyyMMdd_HHmmss').log" }
        Start-Transcript -Path $TranscriptPath -Append
        Write-Host "Transcript logging started. Log file: $TranscriptPath"
    }
    
    # Log debug status
    if ($DebugEnabled) {
        Write-Host "Debug mode enabled"
        if ($VerboseOutput) {
            Write-Host "Verbose output enabled"
            Write-Host "Configuration loaded successfully"
            Write-Host "Total Displays: $TotalDisplays"
            Write-Host "Starting Display: $StartingDisplay"
            Write-Host "Working Directory: $WorkingDirectory"
            Write-Host "DLL Path: $DllPath"
            Write-Host "AHK Path: $AhkPath"
        }
    }
    
    # Create a script-specific config file for AHK v2
    $ahkConfigContent = @"
; AHK v2 Configuration generated from TOML
global totalDisplays := $TotalDisplays
global startingDisplay := $StartingDisplay
global displayTime := $($Config.general.display_time)
global dllPath := "$DllPath"
global desktopIndex := startingDisplay
"@
    
    Set-Content -Path "$WorkingDirectory\WinVDDB_config.ahk" -Value $ahkConfigContent
    
    # Create desktop actions array for AHK v2
    $desktopActionsContent = "global desktopActions := [`n"
    
    # Process desktop configs
    for ($i = 1; $i -le $TotalDisplays; $i++) {
        $desktopKey = "desktop.$i"
        
        if ($TomlModuleAvailable -and $Config.ContainsKey($desktopKey)) {
            $desktopConfig = $Config[$desktopKey]
            $actionCount = 0
            $action = ""
            
            if ($desktopConfig.ContainsKey("action_count")) {
                $actionCount = $desktopConfig.action_count
            }
            
            if ($desktopConfig.ContainsKey("action")) {
                $action = $desktopConfig.action
            }
            
            $desktopActionsContent += "    Map('count', $actionCount, 'action', '$action'),`n"
        } else {
            # Use simple parsing for desktop action
            $actionCount = Get-SimpleTomlValue -FilePath $ConfigPath -Key "desktop.$i.action_count" -DefaultValue 0
            $action = Get-SimpleTomlValue -FilePath $ConfigPath -Key "desktop.$i.action" -DefaultValue ""
            $desktopActionsContent += "    Map('count', $actionCount, 'action', '$action'),`n"
        }
    }
    
    # Close the array
    $desktopActionsContent += "]`n"
    
    # Save desktop actions to a file
    Set-Content -Path "$WorkingDirectory\WinVDDB_actions.ahk" -Value $desktopActionsContent
    
} catch {
    Write-Host "Error loading configuration: $_"
    if ($TranscriptLogging) {
        Stop-Transcript
    }
    
    if ($KeepWindowsOpen) {
        Write-Host "Press any key to continue..."
        [void][System.Console]::ReadKey($true)
    }
    
    exit 1
}

# Start daily reboot task if enabled
$RebootEnabled = $false
if ($TomlModuleAvailable -and $Config.ContainsKey("reboot") -and $Config.reboot.ContainsKey("enabled")) {
    $RebootEnabled = $Config.reboot.enabled
} else {
    $RebootEnabled = Get-SimpleTomlValue -FilePath $ConfigPath -Key "reboot.enabled" -DefaultValue $false
}

if ($RebootEnabled) {
    $rebootParams = @{}
    
    if ($TomlModuleAvailable) {
        $rebootParams.Add("RebootHour", $Config.reboot.reboot_hour)
        $rebootParams.Add("RunWingetUpgrade", $Config.reboot.run_winget_upgrade)
        $rebootParams.Add("WingetTimeout", $Config.reboot.winget_timeout_minutes)
    } else {
        $rebootParams.Add("RebootHour", (Get-SimpleTomlValue -FilePath $ConfigPath -Key "reboot.reboot_hour" -DefaultValue 8))
        $rebootParams.Add("RunWingetUpgrade", (Get-SimpleTomlValue -FilePath $ConfigPath -Key "reboot.run_winget_upgrade" -DefaultValue $true))
        $rebootParams.Add("WingetTimeout", (Get-SimpleTomlValue -FilePath $ConfigPath -Key "reboot.winget_timeout_minutes" -DefaultValue 60))
    }
    
    # Add debug parameters if debug is enabled
    if ($DebugEnabled) {
        $rebootParams.Add("DebugEnabled", $true)
        $rebootParams.Add("TranscriptLogging", $TranscriptLogging)
        
        if ($LogPath -ne "") {
            $rebootParams.Add("LogPath", $LogPath)
        }
        
        if ($KeepWindowsOpen) {
            $rebootParams.Add("KeepWindowOpen", $true)
        }
        
        if ($VerboseOutput) {
            $rebootParams.Add("Verbose", $true)
        }
    }
    
    $rebootScript = "$WorkingDirectory\DailySystemReboot.ps1"
    $rebootArgsList = "-RebootHour $($rebootParams.RebootHour) -RunWingetUpgrade $($rebootParams.RunWingetUpgrade) -WingetTimeout $($rebootParams.WingetTimeout)"
    
    # Add debug arguments
    if ($DebugEnabled) {
        $rebootArgsList += " -DebugEnabled $true"
        $rebootArgsList += " -TranscriptLogging $($rebootParams.TranscriptLogging)"
        
        if ($rebootParams.ContainsKey("LogPath")) {
            $rebootArgsList += " -LogPath `"$($rebootParams.LogPath)`""
        }
        
        if ($rebootParams.ContainsKey("KeepWindowOpen")) {
            $rebootArgsList += " -KeepWindowOpen $true"
        }
        
        if ($rebootParams.ContainsKey("Verbose")) {
            $rebootArgsList += " -Verbose $true"
        }
    }
    
    Write-Host "Starting daily reboot task with parameters: $rebootArgsList"
    
    # Set up process parameters
    $processParams = @{
        FilePath = "powershell.exe"
        ArgumentList = "-ExecutionPolicy Bypass -File ""$rebootScript"" $rebootArgsList"
    }
    
    # If debug mode with keep windows open is enabled, use -NoExit
    if ($DebugEnabled -and $KeepWindowsOpen) {
        $processParams.ArgumentList = "-NoExit " + $processParams.ArgumentList
    }
    
    Start-Process @processParams
    
    # Wait for the reboot script to initialize
    Start-Sleep 5
}

# We'll use AHK to create virtual desktops since the module might not be available
# This function creates a simple AHK script to create virtual desktops
function Ensure-VirtualDesktops {
    param ([int]$requiredCount)

    Write-Host "Creating $requiredCount virtual desktops using AutoHotkey"
    
    # Create a temporary AHK script to create desktops
    $tempAhkPath = "$WorkingDirectory\temp_create_desktops.ahk"
    $createDesktopsScript = @"
#SingleInstance Force

; Load the VirtualDesktopAccessor.dll
dllPath := "$DllPath"
if !DllCall("LoadLibrary", "Str", dllPath) {
    MsgBox "Failed to load VirtualDesktopAccessor.dll"
    ExitApp
}

; Get current desktop count
currentCount := DllCall("VirtualDesktopAccessor\GetDesktopCount")
requiredCount := $requiredCount

; Create new desktops if needed
Loop (requiredCount - currentCount) {
    if (A_Index <= 0)
        break
    DllCall("VirtualDesktopAccessor\CreateDesktop")
    Sleep 500
}

; Get final count and report
finalCount := DllCall("VirtualDesktopAccessor\GetDesktopCount")
FileAppend "Desktop count: " . finalCount . "`n", "*"
ExitApp
"@
    
    Set-Content -Path $tempAhkPath -Value $createDesktopsScript
    
    # Run the AHK script
    $output = & $AhkPath $tempAhkPath
    Write-Host $output
    
    # Clean up the temporary script
    Remove-Item -Path $tempAhkPath -ErrorAction SilentlyContinue
}

# Set the number of required virtual desktops based on config
$numberOfDesktops = $TotalDisplays
Ensure-VirtualDesktops -requiredCount $numberOfDesktops

function OpenOnDesktop {
    param (
        [int]$desktop,
        [string]$program,
        [string]$arguments,
        [array]$postLaunchKeys = @()
    )

    $ahkScript = "$WorkingDirectory\Setup-ProgramsOnVirtualDesktops.ahk"
    
    # Convert post-launch keys to JSON string for passing to AHK
    $keysJson = if ($postLaunchKeys.Count -gt 0) {
        ConvertTo-Json -Compress $postLaunchKeys
    } else {
        '[]'
    }
    $cmdArgs = "$desktop ""$program"" ""$arguments"" ""$keysJson"""

    if ($VerboseOutput) {
        Write-Host "Launching program on desktop $desktop with command: $AhkPath ""$ahkScript"" $cmdArgs"
    }

    # Set up process parameters
    $processParams = @{
        FilePath = $AhkPath
        ArgumentList = """$ahkScript"" $cmdArgs"
    }
    
    Start-Process @processParams
    Write-Host "Launching $program with arguments '$arguments' on desktop $desktop"
    
    # Base sleep time for program initialization
    Start-Sleep 10
    
    # Additional sleep for programs known to be slower
    if ($program -like "*myradar*" -or $program -eq "powershell.exe") {
        Write-Host "Adding extra initialization time for $program"
        Start-Sleep 15
    }
}

# Launch programs on each desktop based on configuration
for ($i = 1; $i -le $TotalDisplays; $i++) {
    $desktopKey = "desktop.$i"
    $desktopEnabled = $true
    $program = ""
    $arguments = ""
    $postLaunchKeys = @()
    
    if ($TomlModuleAvailable -and $Config.ContainsKey($desktopKey)) {
        $desktopConfig = $Config[$desktopKey]
        
        # Check if desktop is enabled
        if ($desktopConfig.ContainsKey("enabled")) {
            $desktopEnabled = $desktopConfig.enabled
        }
        
        # Skip disabled desktops or desktop 1 (if starting from 2)
        if (!$desktopEnabled -or ($i -eq 1 -and $StartingDisplay -gt 1)) {
            Write-Host "Skipping desktop $i - disabled or excluded from rotation"
            continue
        }
        
        if ($desktopConfig.ContainsKey("program")) {
            $program = $desktopConfig.program
        }
        
        if ($desktopConfig.ContainsKey("arguments")) {
            $arguments = $desktopConfig.arguments
        }
        
        if ($desktopConfig.ContainsKey("post_launch_keys")) {
            $postLaunchKeys = $desktopConfig.post_launch_keys
        }
    } else {
        # Use simple parsing
        $desktopEnabled = Get-SimpleTomlValue -FilePath $ConfigPath -Key "desktop.$i.enabled" -DefaultValue $true
        
        # Skip disabled desktops or desktop 1 (if starting from 2)
        if (!$desktopEnabled -or ($i -eq 1 -and $StartingDisplay -gt 1)) {
            Write-Host "Skipping desktop $i - disabled or excluded from rotation"
            continue
        }
        
        $program = Get-SimpleTomlValue -FilePath $ConfigPath -Key "desktop.$i.program" -DefaultValue ""
        $arguments = Get-SimpleTomlValue -FilePath $ConfigPath -Key "desktop.$i.arguments" -DefaultValue ""
        
        # We can't easily parse arrays with simple regex, so just use empty array
        $postLaunchKeys = @()
    }
    
    if ($program -ne "") {
        OpenOnDesktop -desktop $i -program $program -arguments $arguments -postLaunchKeys $postLaunchKeys
    }
}

# Enable Taskbar auto-hide
# Load necessary types
Add-Type @"
    using System;
    using System.Runtime.InteropServices;

    public class Taskbar
    {
        [DllImport("shell32.dll", SetLastError = true)]
        private static extern IntPtr SHAppBarMessage(uint dwMessage, ref APPBARDATA pData);

        [StructLayout(LayoutKind.Sequential)]
        private struct APPBARDATA
        {
            public int cbSize;
            public IntPtr hWnd;
            public uint uCallbackMessage;
            public uint uEdge;
            public RECT rc;
            public IntPtr lParam;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct RECT
        {
            public int left;
            public int top;
            public int right;
            public int bottom;
        }

        private const int ABM_SETSTATE = 0x0000000A;
        private const int ABS_AUTOHIDE = 0x0000001;

        public static void SetAutoHide(bool hide)
        {
            APPBARDATA abd = new APPBARDATA();
            abd.cbSize = Marshal.SizeOf(abd);
            IntPtr retval = SHAppBarMessage(ABM_SETSTATE, ref abd);
            abd.lParam = hide ? (IntPtr)ABS_AUTOHIDE : IntPtr.Zero;
            retval = SHAppBarMessage(ABM_SETSTATE, ref abd);
        }
    }
"@

function Set-TaskbarAutoHide {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Enable", "Disable")]
        [string]$Action
    )

    switch ($Action) {
        "Enable" {
            [Taskbar]::SetAutoHide($true)
            Write-Host "Taskbar auto-hide has been enabled."
        }
        "Disable" {
            [Taskbar]::SetAutoHide($false)
            Write-Host "Taskbar auto-hide has been disabled."
        }
    }
}

Set-TaskbarAutoHide -Action Enable

Write-Host "Handoff to Auto HotKey v2 Switch script"
# Set up process parameters
$processParams = @{
    FilePath = $AhkPath
    ArgumentList = """$WorkingDirectory\DesktopSwitchingFunctions.ahk"""
}

Start-Process @processParams

if ($TranscriptLogging) {
    Stop-Transcript
}

if ($KeepWindowsOpen) {
    Write-Host ""
    Write-Host "Debug mode: Window will remain open. Press any key to exit..."
    [void][System.Console]::ReadKey($true)
}