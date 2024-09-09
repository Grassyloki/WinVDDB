# WinVDK - Windows Virtual Desktop Kiosk

WinVDK is a system for creating a multi-display kiosk experience using
Windows virtual desktops. It automates setting up virtual desktops,
launching applications, and cycling through them at regular intervals.

## Features:

-   Automatic creation and management of multiple virtual desktops
-   Customizable program launching on each virtual desktop
-   Automated cycling through virtual desktops at configurable intervals
-   Ability to pause and resume desktop rotation
-   Custom actions for each desktop (e.g., refreshing a webpage
    periodically)
-   Taskbar auto-hide during rotation
-   Daily system reboot for maintenance
-   Easy configuration and customization

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

Run Run-VirtualDesktopsDisplayBoard.ps1 in PowerShell to start manually.

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
2.  Create new task
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

In DesktopSwitchingFunctions.ahk, the desktopActions array defines
actions for each desktop:

    global desktopActions := []
    desktopActions.Push({count: 0, action: ""})  ; Desktop 1: No action
    desktopActions.Push({count: 0, action: ""})  ; Desktop 2: No action
    desktopActions.Push({count: 0, action: ""})  ; Desktop 3: No action
    desktopActions.Push({count: 8, action: "Send, {F5}"})  ; Desktop 4: Press F5 every 8 switches
    desktopActions.Push({count: 0, action: ""})  ; Desktop 5: No action
    desktopActions.Push({count: 0, action: ""})  ; Desktop 6: No action

This array initializes actions for each desktop. Each entry represents a
desktop and specifies:

-   `count`: How many rotations before the action is triggered (0 means
    no action)
-   `action`: The AutoHotkey command to execute when triggered

In the example, Desktop 4 is set to press F5 (refresh) every 8
rotations. You can customize these actions for each desktop as needed.

## Troubleshooting:

-   Ensure all scripts are in C:\Scripts
-   Check Windows PowerShell execution policy
-   Verify AutoHotkey is installed correctly
-   Ensure VirtualDesktopAccessor.dll is present and accessible

## Limitations:

-   Designed for Windows 10/11 with virtual desktop support
-   May interfere with normal desktop usage when active

## Contributing:

Contributions are welcome. Please submit pull requests or open issues on
the project repository.

## License:

GPL 3.9

## Acknowledgements:

-   AutoHotkey community
-   Microsoft Sysinternals
-   Powershell
