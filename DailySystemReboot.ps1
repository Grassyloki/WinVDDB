# DailySystemReboot.ps1
# Script to perform daily system reboots with optional winget upgrades

param (
    [int]$RebootHour = 8,
    [bool]$RunWingetUpgrade = $true,
    [int]$WingetTimeout = 60,
    [switch]$DebugEnabled = $false,
    [switch]$TranscriptLogging = $false,
    [string]$LogPath = "",
    [switch]$KeepWindowOpen = $false,
    [switch]$Verbose = $false
)

# Start transcript logging if enabled
if ($DebugEnabled -and $TranscriptLogging) {
    $WorkingDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
    $TranscriptPath = if ($LogPath -ne "") { $LogPath } else { "$WorkingDirectory\Logs\WinVDDB_Reboot_$(Get-Date -Format 'yyyyMMdd_HHmmss').log" }
    
    # Ensure Logs directory exists
    $LogDir = Split-Path -Parent $TranscriptPath
    if (-not (Test-Path -Path $LogDir)) {
        try {
            New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
            Write-Host "Created logs directory: $LogDir"
        } catch {
            Write-Host "Error creating logs directory: $_"
        }
    }
    
    try {
        Start-Transcript -Path $TranscriptPath -Append
        Write-Host "Transcript logging started. Log file: $TranscriptPath"
    } catch {
        Write-Host "Error starting transcript: $_"
    }
}

# Log debug status
if ($DebugEnabled) {
    Write-Host "Debug mode enabled"
    if ($Verbose) {
        Write-Host "Verbose output enabled"
        Write-Host "Reboot Hour: $RebootHour"
        Write-Host "Run Winget Upgrade: $RunWingetUpgrade"
        Write-Host "Winget Timeout: $WingetTimeout minutes"
    }
}

Write-Host "Daily System Reboot script started"
Write-Host "System will reboot at $RebootHour:00 every day"

if ($RunWingetUpgrade) {
    Write-Host "Winget package upgrades will be performed before reboot"
    Write-Host "Winget timeout set to $WingetTimeout minutes"
}

# Function to perform winget upgrade
function Invoke-WingetUpgrade {
    param (
        [int]$TimeoutMinutes
    )

    try {
        Write-Host "Starting winget upgrade of all packages..."
        
        # Create process to run winget upgrade with a timeout
        $process = Start-Process -FilePath "winget" -ArgumentList "upgrade --all --accept-source-agreements --accept-package-agreements" -NoNewWindow -PassThru
        
        # Wait for process to complete with timeout
        $timeoutMs = $TimeoutMinutes * 60 * 1000
        if ($process.WaitForExit($timeoutMs)) {
            Write-Host "Winget upgrade completed successfully"
            return $true
        } else {
            Write-Host "Winget upgrade timed out after $TimeoutMinutes minutes"
            try {
                $process.Kill()
                Write-Host "Terminated winget process"
            } catch {
                Write-Host "Failed to terminate winget process: $_"
            }
            return $false
        }
    } catch {
        Write-Host "Error during winget upgrade: $_"
        return $false
    }
}

# Main loop
while ($true) {
    $now = Get-Date
    if ($now.Hour -eq $RebootHour) {
        Write-Host "Reboot time reached: $($now.ToString())"
        
        if ($RunWingetUpgrade) {
            Write-Host "Running winget upgrade before reboot..."
            $upgradeSuccess = Invoke-WingetUpgrade -TimeoutMinutes $WingetTimeout
            
            if ($upgradeSuccess) {
                Write-Host "Winget upgrade completed, proceeding with reboot..."
            } else {
                Write-Host "Winget upgrade failed or timed out, proceeding with reboot anyway..."
            }
            
            # Add a small delay to make sure logs are flushed and processes complete
            Start-Sleep -Seconds 10
        }
        
        Write-Host "Initiating system reboot at $($now.ToString())"
        if ($TranscriptLogging) {
            try {
                Stop-Transcript
            } catch {
                # Transcript might not be started
            }
        }
        
        # Only reboot if not in debug mode with keep window open
        if (!($DebugEnabled -and $KeepWindowOpen)) {
            Restart-Computer -Force
        } else {
            Write-Host "Debug mode with keep window open is enabled - system would be rebooted here"
        }
        
        # End script or break out of loop if in debug mode
        if ($DebugEnabled -and $KeepWindowOpen) {
            Write-Host "Press any key to exit..."
            [void][System.Console]::ReadKey($true)
            break
        } else {
            exit
        }
    } else {
        # Calculate time until next reboot
        $nextReboot = Get-Date -Hour $RebootHour -Minute 0 -Second 0
        if ($nextReboot -lt $now) {
            $nextReboot = $nextReboot.AddDays(1)
        }
        $timeUntilReboot = $nextReboot - $now
        
        if ($Verbose) {
            Write-Host "Current time: $($now.ToString())"
            Write-Host "Next reboot scheduled for: $($nextReboot.ToString())"
            Write-Host "Time until reboot: $($timeUntilReboot.ToString())"
        }
        
        # Sleep for an appropriate interval (60 minutes by default, 5 minutes when getting close)
        $sleepMinutes = if ($timeUntilReboot.TotalHours -le 1) { 5 } else { 60 }
        
        if ($Verbose) {
            Write-Host "Sleeping for $sleepMinutes minutes..."
        }
        
        Start-Sleep -Seconds ($sleepMinutes * 60)
    }
}