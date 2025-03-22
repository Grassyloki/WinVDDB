# DailySystemReboot.ps1
# Script to handle daily system updates and reboot

param (
    [int]$RebootHour = 8,
    [bool]$RunWingetUpgrade = $true,
    [int]$WingetTimeout = 60,
    [bool]$DebugEnabled = $false,
    [bool]$TranscriptLogging = $false,
    [string]$LogPath = "",
    [bool]$KeepWindowOpen = $false,
    [bool]$Verbose = $false
)

# Start transcript logging if enabled
if ($DebugEnabled -and $TranscriptLogging) {
    $workingDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $TranscriptPath = if ($LogPath -ne "") { $LogPath } else { "$workingDir\WinVDDB_Reboot_$(Get-Date -Format 'yyyyMMdd_HHmmss').log" }
    Start-Transcript -Path $TranscriptPath -Append
    Write-Host "Transcript logging started. Log file: $TranscriptPath"
}

if ($DebugEnabled -and $Verbose) {
    Write-Host "Debug mode enabled with verbose output"
    Write-Host "Parameters:"
    Write-Host "  Reboot Hour: $RebootHour"
    Write-Host "  Run Winget Upgrade: $RunWingetUpgrade"
    Write-Host "  Winget Timeout: $WingetTimeout minutes"
    Write-Host "  Keep Window Open: $KeepWindowOpen"
}

# Calculate the target reboot time (next occurrence of the specified hour)
$now = Get-Date
$rebootTime = Get-Date -Hour $RebootHour -Minute 0 -Second 0

# If the specified hour has already passed today, set for tomorrow
if ($now -gt $rebootTime) {
    $rebootTime = $rebootTime.AddDays(1)
}

if ($DebugEnabled -and $Verbose) {
    Write-Host "Current time: $now"
    Write-Host "Target reboot time: $rebootTime"
}

# Function to display the countdown
function Show-Countdown {
    param (
        [DateTime]$TargetTime
    )
    
    $remainingTime = $TargetTime - (Get-Date)
    $days = $remainingTime.Days
    $hours = $remainingTime.Hours
    $minutes = $remainingTime.Minutes
    
    Clear-Host
    Write-Host "System will reboot at $($TargetTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    if ($RunWingetUpgrade) {
        Write-Host "Winget upgrade will run before reboot"
    }
    Write-Host "Time remaining: $days days, $hours hours, $minutes minutes"
    Write-Host "Press Ctrl+C to cancel the reboot."

    if ($DebugEnabled) {
        Write-Host ""
        Write-Host "Debug mode enabled" -ForegroundColor Yellow
        if ($Verbose) {
            Write-Host "Verbose output enabled" -ForegroundColor Yellow
        }
        if ($KeepWindowOpen) {
            Write-Host "Window will remain open after script completion" -ForegroundColor Yellow
        }
        if ($TranscriptLogging) {
            Write-Host "Transcript logging enabled: $TranscriptPath" -ForegroundColor Yellow
        }
    }
}

# Function to run winget upgrade with timeout
function Invoke-WingetUpgrade {
    param (
        [int]$TimeoutMinutes
    )
    
    Write-Host "Starting winget upgrade... (Timeout: $TimeoutMinutes minutes)"
    
    # Define the script block to run in a job
    $scriptBlock = {
        try {
            # Execute winget upgrade command
            if ($using:Verbose) {
                Write-Host "Running: winget upgrade --all"
            }
            winget upgrade --all --silent
            return $true
        } catch {
            Write-Error "Winget upgrade failed: $_"
            return $false
        }
    }
    
    # Start the job with the script block
    $job = Start-Job -ScriptBlock $scriptBlock
    
    # Wait for the job to complete with a timeout
    $jobResult = Wait-Job -Job $job -Timeout ($TimeoutMinutes * 60)
    
    # Check the job status
    if ($jobResult.State -eq 'Completed') {
        $result = Receive-Job -Job $job
        Remove-Job -Job $job
        
        if ($result -eq $true) {
            Write-Host "Winget upgrade completed successfully"
        } else {
            Write-Host "Winget upgrade completed with errors"
        }
    } else {
        Write-Host "Winget upgrade timed out after $TimeoutMinutes minutes"
        Stop-Job -Job $job
        Remove-Job -Job $job
    }
}

# Debug: Simulate short timeout for testing
if ($DebugEnabled -and $Verbose) {
    # Calculate a short countdown interval for testing
    $debugIntervalSeconds = 10  # 10 seconds between countdown updates for testing
    Write-Host "Debug mode: Using $debugIntervalSeconds seconds between countdown updates for testing"
} else {
    $debugIntervalSeconds = 60  # 1 minute between countdown updates for normal operation
}

# Main script execution
try {
    # Wait until the reboot time (or Ctrl+C is pressed)
    while ((Get-Date) -lt $rebootTime) {
        Show-Countdown -TargetTime $rebootTime
        Start-Sleep -Seconds $debugIntervalSeconds  # Update every minute (or faster in debug mode)
    }
    
    Write-Host "Preparing for system reboot..."
    
    # Run winget upgrade if enabled
    if ($RunWingetUpgrade) {
        Invoke-WingetUpgrade -TimeoutMinutes $WingetTimeout
    }
    
    # In debug mode with KeepWindowOpen, don't actually reboot
    if ($DebugEnabled -and $KeepWindowOpen) {
        Write-Host "Debug mode with KeepWindowOpen enabled. System reboot simulation completed."
        Write-Host "In normal mode, the system would reboot now."
    } else {
        Write-Host "Initiating system reboot..."
        Start-Sleep -Seconds 5
        
        # Only actually reboot if not in debug mode
        if (-not $DebugEnabled) {
            Restart-Computer -Force
        } else {
            Write-Host "Debug mode: System reboot simulated (not actually rebooting)"
        }
    }
}
catch {
    Write-Host "`nReboot cancelled." -ForegroundColor Yellow
    Write-Host "Error: $_" -ForegroundColor Red
}
finally {
    if ($TranscriptLogging) {
        Stop-Transcript
    }
    
    if ($DebugEnabled -and $KeepWindowOpen) {
        Write-Host ""
        Write-Host "Debug mode: Window will remain open. Press any key to exit..."
        [void][System.Console]::ReadKey($true)
    }
}