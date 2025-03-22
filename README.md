# WinVDDB - Windows Virtual Desktop Display Board

WinVDDB is a system for creating a multi-display board experience using
Windows virtual desktops. It automates setting up virtual desktops,
launching applications, and cycling through them at regular intervals.

## Features:

-   Automatic creation and management of multiple virtual desktops
-   Customizable program launching on each virtual desktop
-   Automated cycling through virtual desktops at configurable intervals
-   Ability to pause and resume desktop rotation
-   Custom actions for each desktop (e.g., refreshing a webpage
    periodically)
-   Post-launch key sequences for applications
-   Manual desktop selection with auto-timeout
-   Taskbar auto-hide during rotation
-   Daily system reboot with automatic updates via winget
-   Easy configuration via TOML configuration file

## Installation:

1.  Create C:\Scripts folder
2.  Copy all files into C:\Scripts:
    -   Launch-DisplayBoard.ps1 (main launcher script)
    -   Run-VirtualDesktopsDisplayBoard.ps1
    -   DesktopSwitchingFunctions.ahk
    -   Setup-ProgramsOnVirtualDesktops.ahk
    -   DailySystemReboot.ps1
    -   VirtualDesktopAccessor.dll
    -   JSON.ahk
    -   config.toml (copied and configured from config.toml.example)
3.  Install AutoHotkey v2 from
    [autohotkey.com](https://www.autohotkey.com)
4.  Install required PowerShell modules: VirtualDesktop and Powershell-TOML

## Usage:

Run Launch-DisplayBoard.ps1 in PowerShell to start manually.

-   F2: Pause/resume desktop rotation
-   2-9: Manually switch to a specific desktop for 1 hour, then resume
    automatic rotation
-   Taskbar auto-hides during rotation, shows when paused

## Configuration:

The main configuration is in the config.toml file. This file controls:

-   Total number of desktops
-   Display time per desktop
-   Programs to launch on each desktop
-   Post-launch key sequences for each program
-   Custom actions per desktop (like refreshing)
-   Daily reboot settings including winget upgrades

Example configuration (config.toml.example):

```toml
# General Settings
[general]
total_displays = 5
starting_display = 2
display_time = 120000  # milliseconds
dll_path = "C:\\Scripts\\VirtualDesktopAccessor.dll"
ahk_path = "C:\\Program Files\\AutoHotkey\\v2\\AutoHotkey64.exe"
working_directory = "C:\\Scripts"

# Daily Reboot Settings
[reboot]
enabled = true
reboot_hour = 8
run_winget_upgrade = true
winget_timeout_minutes = 60

# Example Desktop Configuration
[[desktop]]
number = 2
program = "firefox.exe"
arguments = "-new-window --kiosk https://example.com"
post_launch_keys = [
  {keys = "{F11}", delay = 3000}
]
action_count = 8
action = "{F5}"
```

## Auto-Start Setup:

1.  Open Task Scheduler
2.  Create new task
3.  Trigger: At log on
4.  Action:
    -   Program: powershell.exe
    -   Arguments: -ExecutionPolicy Bypass -File
        "C:\Scripts\Launch-DisplayBoard.ps1"

## Auto Login Setup:

1.  Download Autologon from Sysinternals
2.  Run Autologon.exe
3.  Enter domain/computer name, username, password
4.  Click Enable

**Note:** Use auto-login cautiously on unsecured systems.

## File Descriptions:

1.  Launch-DisplayBoard.ps1: Launcher script that switches to desktop 1
    and starts the main script.
2.  Run-VirtualDesktopsDisplayBoard.ps1: Main script that initializes
    the system, creates virtual desktops, and launches programs.
3.  DesktopSwitchingFunctions.ahk: Handles desktop rotation,
    pause/resume functionality, and custom actions per desktop.
4.  Setup-ProgramsOnVirtualDesktops.ahk: Helper script to launch
    programs on specific virtual desktops and execute post-launch key
    sequences.
5.  DailySystemReboot.ps1: Manages daily system updates via winget and
    reboots for maintenance.
6.  VirtualDesktopAccessor.dll: Required DLL for interacting with
    Windows virtual desktops.
7.  JSON.ahk: JSON parsing library for AutoHotkey v2.
8.  config.toml: Configuration file for all settings.

## AutoHotkey v2 Usage:

This project utilizes AutoHotkey v2, which has several syntax differences compared to v1:

- Function calls now use parentheses: `FunctionName(param1, param2)` instead of commas
- Object syntax has changed, using standard `obj.prop` notation
- Cleaner error handling with `try`/`catch Error as e`
- Commands (like Send, MsgBox) are now functions - no more comma parameters
- New Buffer class replaces VarSetCapacity
- Maps are used instead of objects for associative arrays

## Troubleshooting:

-   Ensure all scripts are in C:\Scripts
-   Check Windows PowerShell execution policy
-   Verify AutoHotkey v2 is installed correctly
-   Ensure VirtualDesktopAccessor.dll is present and accessible
-   Make sure the Powershell-TOML module is installed

## Limitations:

-   Designed for Windows 10/11 with virtual desktop support
-   Requires AutoHotkey v2
-   May interfere with normal desktop usage when active

## Contributing:

Contributions are welcome. Please submit pull requests or open issues on
the project repository.

## License:

GPL 3.0