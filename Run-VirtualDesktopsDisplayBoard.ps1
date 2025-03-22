# Run-VirtualDesktopsDisplayBoard.ps1
# Main script for Windows Virtual Desktop Display Board

param (
    [string]$ConfigPath = "config.toml"
)

Write-Host "Starting Windows Virtual Desktop Display Board"

# Import required modules
if (-not (Get-Module -Name VirtualDesktop -ListAvailable)) {
    Write-Host "VirtualDesktop module not found. Installing..."
    Install-Module -Name VirtualDesktop -Force -Scope CurrentUser
}
Import-Module VirtualDesktop

# Check for the Powershell-TOML module and install if not present
if (-not (Get-Module -Name Powershell-TOML -ListAvailable)) {
    Write-Host "Powershell-TOML module not found. Installing..."
    Install-Module -Name Powershell-TOML -Force -Scope CurrentUser
}
Import-Module Powershell-TOML

# Load configuration
try {
    Write-Host "Loading configuration from $ConfigPath"
    $Config = ConvertFrom-Toml -Path $ConfigPath
    
    # Extract general settings
    $WorkingDirectory = $Config.general.working_directory
    $TotalDisplays = $Config.general.total_displays
    $StartingDisplay = $Config.general.starting_display
    $DllPath = $Config.general.dll_path
    $AhkPath = $Config.general.ahk_path
    
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
        
        if ($Config.ContainsKey($desktopKey)) {
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
            # Default empty action for desktops without configuration
            $desktopActionsContent += "    Map('count', 0, 'action', ''),`n"
        }
    }
    
    # Close the array
    $desktopActionsContent += "]`n"
    
    # Save desktop actions to a file
    Set-Content -Path "$WorkingDirectory\WinVDDB_actions.ahk" -Value $desktopActionsContent
    
} catch {
    Write-Host "Error loading configuration: $_"
    exit 1
}

# Start daily reboot task if enabled
if ($Config.reboot.enabled -eq $true) {
    $rebootParams = @{
        RebootHour = $Config.reboot.reboot_hour
        RunWingetUpgrade = $Config.reboot.run_winget_upgrade
        WingetTimeout = $Config.reboot.winget_timeout_minutes
    }
    
    $rebootScript = "$WorkingDirectory\DailySystemReboot.ps1"
    $rebootArgsList = "-RebootHour $($rebootParams.RebootHour) -RunWingetUpgrade $($rebootParams.RunWingetUpgrade) -WingetTimeout $($rebootParams.WingetTimeout)"
    
    Write-Host "Starting daily reboot task with parameters: $rebootArgsList"
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File ""$rebootScript"" $rebootArgsList"
    
    # Wait for the reboot script to initialize
    Start-Sleep 5
}

# Ensure the required number of virtual desktops exists
function Ensure-VirtualDesktops {
    param ([int]$requiredCount)

    $currentCount = (Get-DesktopCount)
    Write-Host "Initial desktop count: $currentCount"
    
    while ($currentCount -lt $requiredCount) {
        Write-Host "Creating new desktop. Current count: $currentCount"
        New-Desktop
        Start-Sleep -Seconds 2 # Allow time for the desktop to initialize
        $currentCount = (Get-DesktopCount)
    }
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
    $keysJson = ConvertTo-Json -Compress $postLaunchKeys
    $cmdArgs = "$desktop ""$program"" ""$arguments"" ""$keysJson"""

    Start-Process -FilePath $AhkPath -ArgumentList """$ahkScript"" $cmdArgs"
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
    
    if ($Config.ContainsKey($desktopKey)) {
        $desktopConfig = $Config[$desktopKey]
        
        # Skip disabled desktops or desktop 1 (if starting from 2)
        if (($desktopConfig.ContainsKey("enabled") -and $desktopConfig.enabled -eq $false) -or 
            ($i -eq 1 -and $StartingDisplay -gt 1)) {
            Write-Host "Skipping desktop $i - disabled or excluded from rotation"
            continue
        }
        
        if ($desktopConfig.ContainsKey("program") -and $desktopConfig.program -ne "") {
            $program = $desktopConfig.program
            $arguments = ""
            $postLaunchKeys = @()
            
            if ($desktopConfig.ContainsKey("arguments")) {
                $arguments = $desktopConfig.arguments
            }
            
            if ($desktopConfig.ContainsKey("post_launch_keys")) {
                $postLaunchKeys = $desktopConfig.post_launch_keys
            }
            
            OpenOnDesktop -desktop $i -program $program -arguments $arguments -postLaunchKeys $postLaunchKeys
        }
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
Start-Process -FilePath $AhkPath -ArgumentList """$WorkingDirectory\DesktopSwitchingFunctions.ahk"""