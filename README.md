# Windows Virtual Desktop Display Board (WinVDDB)

A Windows application that manages and rotates between virtual desktops to create a dynamic information display board. Perfect for kiosk systems, dashboards, monitoring stations, and information radiators.

## Features

- **Desktop Rotation**: Automatically switches between multiple virtual desktops at configurable intervals
- **Application Management**: Opens and manages specific applications on each virtual desktop
- **TOML Configuration**: Easy configuration via TOML files
- **Post-Launch Actions**: Sends custom key sequences after launching applications
- **Periodic Actions**: Performs configurable actions on each desktop after specified rotation counts
- **Manual Control**: Press F2 to pause/resume rotation, or number keys (2-9) to stay on a specific desktop for an hour
- **Daily System Maintenance**: Optionally performs daily winget upgrades and system reboots
- **Debug Features**: Comprehensive logging and debugging capabilities

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1+
- [AutoHotkey v2](https://www.autohotkey.com/) (v2.0 or greater)
- [VirtualDesktopAccessor.dll](https://github.com/Ciantic/VirtualDesktopAccessor) (included in release)

## Installation

1. Clone or download this repository
2. Place the files in a directory (e.g., `C:\Scripts\WinVDDB`)
3. Copy `config.toml.example` to `config.toml` and customize settings
4. Run the launcher script via PowerShell:
   ```
   powershell.exe -ExecutionPolicy Bypass -File "Launch-DisplayBoard.ps1"
   ```

## Configuration

Edit `config.toml` to configure:

### General Settings

```toml
[general]
total_displays = 6              # Total number of displays (including desktop 1)
starting_display = 2            # First display number to start cycling from
display_time = 120000           # Duration each desktop is shown (ms)
dll_path = "C:\\Path\\VirtualDesktopAccessor.dll"  # Path to VirtualDesktop DLL
ahk_path = "C:\\Program Files\\AutoHotkey\\v2\\AutoHotkey64.exe"  # Path to AHK
working_directory = "C:\\Scripts"  # Working directory for scripts
```

### Desktop Configuration

Each desktop has its own configuration table:

```toml
[desktop.2]
enabled = true
program = "firefox.exe"
arguments = "-new-window --kiosk https://example.com"
post_launch_keys = [
  {keys = "{Tab}", delay = 3000},
  {keys = "username", delay = 500},
  {keys = "{Tab}", delay = 500},
  {keys = "password", delay = 500},
  {keys = "{Enter}", delay = 500}
]
action_count = 10       # Perform action every 10 rotations
action = "{F5}"         # Refresh the page (F5 key)
```

### Debug Features

```toml
[debug]
enabled = false               # Enable debug mode
transcript_logging = false    # Enable PowerShell transcript logging
log_path = ""                 # Log file location (empty = default)
keep_windows_open = false     # Keep PowerShell windows open
verbose = false               # Show verbose output
```

### Daily Reboot Settings

```toml
[reboot]
enabled = true               # Enable/disable daily system reboot
reboot_hour = 8              # Hour to perform reboot (24-hour format)
run_winget_upgrade = true    # Run winget upgrade before reboot
winget_timeout_minutes = 60  # Maximum time for winget upgrade
```

## Usage

- Press `F2` to pause/resume desktop rotation
- Press a number key (2-9) to go to that desktop and stay there for 60 minutes
- When paused, the taskbar auto-hide feature is disabled for easier navigation

## Files and Components

- `Launch-DisplayBoard.ps1`: Launcher script that activates on Desktop 1
- `Run-VirtualDesktopsDisplayBoard.ps1`: Main script that sets up desktops and applications
- `DesktopSwitchingFunctions.ahk`: AutoHotkey script for desktop rotation
- `Setup-ProgramsOnVirtualDesktops.ahk`: Program launcher with post-launch key sequences
- `DailySystemReboot.ps1`: System maintenance with winget upgrades and scheduled reboots
- `JSON.ahk`: JSON library for AutoHotkey v2
- `config.toml`: User configuration file

## Troubleshooting

- **Virtual Desktop Switching Issues**: Ensure VirtualDesktopAccessor.dll is properly placed
- **Program Launch Issues**: Check program paths and arguments
- **Debug Mode**: Enable debug features in config.toml for detailed logging
- **AutoHotkey Errors**: Ensure you have v2.0+ installed, not v1.1

## License

This project is released under the MIT License - see LICENSE file for details.

## Credits

- Uses VirtualDesktopAccessor.dll from https://github.com/Ciantic/VirtualDesktopAccessor