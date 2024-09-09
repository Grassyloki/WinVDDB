# WinVDK - Windows Virtual Desktop Kiosk

WinVDK is a system for creating a multi-display kiosk experience using
Windows virtual desktops. It automates setting up virtual desktops,
launching applications, and cycling through them at regular intervals.

## Installation:

1.  Create C:\Scripts folder
2.  Copy these files into C:\Scripts:
    -   Run-VirtualDesktopsDisplayBoard.ps1
    -   DesktopSwitchingFunctions.ahk
    -   Setup-ProgramsOnVirtualDesktops.ahk
    -   DailySystemReboot.ps1
    -   VirtualDesktopAccessor.dll
3.  Install AutoHotkey v1.1 or later from
    [autohotkey.com](https://www.autohotkey.com)

## Usage:

Run Run-VirtualDesktopsDisplayBoard.ps1 in PowerShell (admin) to start
manually.

-   F2: Pause/resume desktop rotation
-   Taskbar auto-hides during rotation, shows when paused

## Adding/Removing Programs:

Edit Run-VirtualDesktopsDisplayBoard.ps1:

    OpenOnDesktop -desktop 2 -program "firefox.exe" -arguments "-new-window --kiosk https://example.com"

## Adjusting Total Desktops:

1.  Edit DesktopSwitchingFunctions.ahk
2.  Change totalDisplays variable
3.  Update desktopActions array
4.  Modify OpenOnDesktop calls in Run-VirtualDesktopsDisplayBoard.ps1

## Auto-Start Setup:

1.  Open Task Scheduler
2.  Create new task, run with highest privileges
3.  Trigger: At log on
4.  Action:
    -   Program: powershell.exe
    -   Arguments: -ExecutionPolicy Bypass -File
        "C:\Scripts\Run-VirtualDesktopsDisplayBoard.ps1"

## Auto Login Setup:

1.  Download Autologon from Sysinternals
2.  Run Autologon.exe
3.  Enter domain/computer name, username, password
4.  Click Enable

**Note:** Use auto-login cautiously on unsecured systems.

## Configuration:

Main configuration is in Run-VirtualDesktopsDisplayBoard.ps1. This
script sets up virtual desktops and launches programs.

## File Descriptions:

1.  Run-VirtualDesktopsDisplayBoard.ps1: Main script that initializes
    the system, creates virtual desktops, and launches programs.
2.  DesktopSwitchingFunctions.ahk: Handles desktop rotation,
    pause/resume functionality, and custom actions per desktop.
3.  Setup-ProgramsOnVirtualDesktops.ahk: Helper script to launch
    programs on specific virtual desktops.
4.  DailySystemReboot.ps1: Manages daily system reboot for maintenance.
5.  VirtualDesktopAccessor.dll: Required DLL for interacting with
    Windows virtual desktops.

## Customization:

### Changing Rotation Interval:

In DesktopSwitchingFunctions.ahk, modify:

    global displayTime := 120000  ; Time in milliseconds (120000 = 2 minutes)

### Custom Actions Per Desktop:

In DesktopSwitchingFunctions.ahk, edit the desktopActions array:

    desktopActions.Push({count: 8, action: "Send, {F5}"})  ; Refresh every 8 rotations

## Troubleshooting:

-   Ensure all scripts are in C:\Scripts
-   Check Windows PowerShell execution policy
-   Verify AutoHotkey is installed correctly
-   Ensure VirtualDesktopAccessor.dll is present and accessible

## Limitations:

-   Designed for Windows 10/11 with virtual desktop support
-   Requires administrator privileges to run
-   May interfere with normal desktop usage when active

## Contributing:

Contributions are welcome. Please submit pull requests or open issues on
the project repository.

## License:

\[Specify your chosen license here\]

## Acknowledgements:

-   AutoHotkey community
-   Microsoft Sysinternals
-   \[Any other acknowledgements\]
