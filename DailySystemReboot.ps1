# Set the target reboot time to 8AM tomorrow
$rebootTime = (Get-Date).Date.AddDays(1).AddHours(8)

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
    Write-Host "Time remaining: $days days, $hours hours, $minutes minutes"
    Write-Host "Press Ctrl+C to cancel the reboot."
}

# Main script execution
try {
    while ((Get-Date) -lt $rebootTime) {
        Show-Countdown -TargetTime $rebootTime
        Start-Sleep -Seconds 60  # Update every minute
    }

    Write-Host "Initiating system reboot..."
    Start-Sleep -Seconds 5
    Restart-Computer -Force
}
catch {
    Write-Host "`nReboot cancelled." -ForegroundColor Yellow
}
