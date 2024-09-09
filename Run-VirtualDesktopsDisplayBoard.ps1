Write-Host "Starting Virtual Destop Display Board"

# Sleep to allow computer to finish booting
Start-Sleep 15

#Start daily reboot task
Start-Process powershell.exe -ArgumentList "C:\Scripts\DailySystemReboot.ps1"

#Wait 
Start-Sleep 5

# Import VirtualDesktop module
Import-Module VirtualDesktop

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

# Set the number of required virtual desktops
$numberOfDesktops = 6
Ensure-VirtualDesktops -requiredCount $numberOfDesktops

function OpenOnDesktop {
    param (
        [int]$desktop,
        [string]$program,
        [string]$arguments
    )

    $ahkPath = "C:\Program Files\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe"
    $ahkScript = "C:\Scripts\Setup-ProgramsOnVirtualDesktops.ahk"
    $cmdArgs = "$desktop `"$program`" `"$arguments`""

    Start-Process -FilePath $ahkPath -ArgumentList $ahkScript, $cmdArgs
    Write-Host "Launching $program with arguments '$arguments' on desktop $desktop"
}

# Example usage: Open Firefox in kiosk mode on desktop 2 with a specific URL: OpenOnDesktop -desktop 2 -program "firefox.exe" -arguments "-kiosk https://example.com"
# Make sure to disable "Share any window from my taskbar" in taskbar settings else firefox wont open new instances! 
OpenOnDesktop -desktop 2 -program "firefox.exe" -arguments "-new-window --kiosk https://ha.com/lovelace/default_view"
start-sleep 15
OpenOnDesktop -desktop 3 -program "firefox.exe" -arguments "-new-window --kiosk http://grafana"
start-sleep 15
OpenOnDesktop -desktop 4 -program "firefox.exe" -arguments "-new-window --kiosk https://www.windy.com/-Radar+-radarPlus"
start-sleep 15
OpenOnDesktop -desktop 5 -program "powershell.exe" -arguments "C:\Scripts\Start-MyRadar.ps1"
#OpenOnDesktop -desktop 5 -program "firefox.exe" -arguments "-new-window https://www.windy.com/-Weather-radar-radar"
# Sleep for 20 seconds because myradar is slow 
Start-Sleep 25 
OpenOnDesktop -desktop 6 -program "firefox.exe" -arguments "-new-window --kiosk https://www.flightradar24.com/"
Start-Sleep 15 

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
# Set-TaskbarAutoHide -Action Disable


Write-Host "Handoff to Auto HotKey Switch script"
C:\Scripts\DesktopSwitchingFunctions.ahk
