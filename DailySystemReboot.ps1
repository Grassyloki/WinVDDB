# DailySystemReboot.ps1
# Script to handle daily system updates and reboot

param (
    [int]$RebootHour = 8,
    [bool]$RunWingetUpgrade = $true,
    [int]$WingetTimeout = 60
)

# Calculate the target reboot time (next occurrence of the specified hour)
$now = Get-Date
$rebootTime = Get-Date -Hour $RebootHour -Minute 0 -Second 0

# If the specified hour has already passed today, set for tomorrow
if ($now -gt $rebootTime) {
    $rebootTime = $rebootTime.AddDays(1)
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

# Main script execution
try {
    # Wait until the reboot time
    while ((Get-Date) -lt $rebootTime) {
        Show-Countdown -TargetTime $rebootTime
        Start-Sleep -Seconds 60  # Update every minute
    }
    
    Write-Host "Preparing for system reboot..."
    
    # Run winget upgrade if enabled
    if ($RunWingetUpgrade) {
        Invoke-WingetUpgrade -TimeoutMinutes $WingetTimeout
    }
    
    Write-Host "Initiating system reboot..."
    Start-Sleep -Seconds 5
    Restart-Computer -Force
}
catch {
    Write-Host "`nReboot cancelled." -ForegroundColor Yellow
}