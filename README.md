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
-   Debug mode with logging and window persistence

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

The main configuration is in the config.toml file. This file controls all aspects of WinVDDB through a structured format:

### General Settings
```toml
[general]
total_displays = 6  # Total number of displays (including desktop 1)
starting_display = 2  # First display to start cycling from (usually 2 to skip desktop 1)
display_time = 120000  # Duration for each desktop in milliseconds
dll_path = "C:\\Scripts\\VirtualDesktopAccessor.dll"
ahk_path = "C:\\Program Files\\AutoHotkey\\v2\\AutoHotkey64.exe"
working_directory = "C:\\Scripts"
```

### Debug Settings
```toml
[debug]
enabled = false  # Master switch for debug mode
transcript_logging = false  # Enable PowerShell transcript logging
log_path = ""  # Custom log file path (leave empty for default)
keep_windows_open = false  # Keep PowerShell windows open after execution
verbose = false  # Show verbose output
```

### Reboot Settings
```toml
[reboot]
enabled = true
reboot_hour = 8
run_winget_upgrade = true
winget_timeout_minutes = 60
```

### Desktop-Specific Settings
Each desktop has its own configuration table with the format `[desktop.N]` where N is the desktop number:

```toml
[desktop.4]
enabled = true
program = "firefox.exe"
arguments = "-new-window --kiosk https://www.windy.com/-Radar+-radarPlus"
post_launch_keys = []
action_count = 8  # Execute every 8 rotations
action = "{F5}"  # Refresh the page with F5
```

#### Available Desktop Options:
- `enabled`: Whether this desktop should be included in rotation
- `program`: The program to launch on this desktop
- `arguments`: Command-line arguments for the program
- `post_launch_keys`: Array of key sequences to send after launching the program
  - Format: `[{keys = "key combination", delay = delay_in_ms}, ...]`
- `action_count`: How many rotations before triggering the periodic action
- `action`: The AutoHotkey key sequence to send periodically

## Debugging:

The debug settings in config.toml allow you to troubleshoot issues:

- **enabled**: Master switch for debug mode
- **transcript_logging**: Records all PowerShell commands and output to a log file
- **log_path**: Specify a custom log file location
- **keep_windows_open**: Prevents PowerShell windows from closing, allowing you to see output
- **verbose**: Shows additional information during execution

To enable debugging:

1. Edit config.toml and set debug.enabled = true
2. Enable other debug options as needed (transcript_logging, keep_windows_open, etc.)
3. Run Launch-DisplayBoard.ps1
4. PowerShell windows will stay open if keep_windows_open is enabled
5. Check log files if transcript_logging is enabled

Example log file names:
- WinVDDB_YYYYMMDD_HHMMSS.log (main script)
- WinVDDB_Reboot_YYYYMMDD_HHMMSS.log (reboot script)

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

## Configuration Examples:

### Login Form Automation
```toml
[desktop.7]
enabled = true
program = "chrome.exe"
arguments = "--start-fullscreen https://example.com/login"
post_launch_keys = [
  # Wait 3 seconds, then press Tab to focus on a field
  {keys = "{Tab}", delay = 3000},
  # Wait 500ms, then type a username
  {keys = "username", delay = 500},
  # Wait 500ms, then press Tab to move to password field
  {keys = "{Tab}", delay = 500},
  # Wait 500ms, then type a password
  {keys = "password", delay = 500},
  # Wait 500ms, then press Enter to submit
  {keys = "{Enter}", delay = 500}
]
# Press F5 to refresh every 5 rotations
action_count = 5
action = "{F5}"
```

### Running Multiple Applications on One Desktop
```toml
[desktop.8]
enabled = true
program = "cmd.exe"
arguments = "/c start notepad.exe && start mspaint.exe"
post_launch_keys = [
  # Activate Notepad window
  {keys = "!{Tab}", delay = 2000},
  # Type some text
  {keys = "This is an example text", delay = 500},
  # Switch to Paint
  {keys = "!{Tab}", delay = 1000}
]
# Every 6 rotations, press Ctrl+S to save
action_count = 6
action = "^s"
```

## Troubleshooting:

-   Ensure all scripts are in C:\Scripts
-   Check Windows PowerShell execution policy
-   Verify AutoHotkey v2 is installed correctly
-   Ensure VirtualDesktopAccessor.dll is present and accessible
-   Make sure the Powershell-TOML module is installed
-   Enable debug mode in config.toml to keep windows open and enable logging
-   Check transcript logs for detailed error information

## Limitations:

-   Designed for Windows 10/11 with virtual desktop support
-   Requires AutoHotkey v2
-   May interfere with normal desktop usage when active

## Contributing:

Contributions are welcome. Please submit pull requests or open issues on
the project repository.

## License:

GPL 3.0