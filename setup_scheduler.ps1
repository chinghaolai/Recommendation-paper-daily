# Register a Windows Task Scheduler job to run run_daily.ps1 every day at 10:00 AM
# Run this script ONCE as Administrator to set up the scheduled task

$TaskName    = "ArxivDailyUpdate"
$ScriptPath  = Join-Path $PSScriptRoot "run_daily.ps1"
$TriggerTime = "10:00"

# Check if already registered
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Write-Host "Task '$TaskName' already exists. Removing old task first..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$action  = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NonInteractive -ExecutionPolicy Bypass -File `"$ScriptPath`""

$trigger = New-ScheduledTaskTrigger -Daily -At $TriggerTime

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 30) `
    -RestartCount 2 `
    -RestartInterval (New-TimeSpan -Minutes 5) `
    -StartWhenAvailable   # Run ASAP if the scheduled time was missed

$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

try {
    Register-ScheduledTask `
        -TaskName   $TaskName `
        -Action     $action `
        -Trigger    $trigger `
        -Settings   $settings `
        -Principal  $principal `
        -Description "Daily arXiv recsys paper fetch and git push" `
        -ErrorAction Stop | Out-Null
} catch {
    Write-Host "ERROR: $_"
    exit 1
}

Write-Host "Scheduled task '$TaskName' registered successfully."
Write-Host "It will run every day at $TriggerTime."
Write-Host ""
Write-Host "Useful commands:"
Write-Host "  Run now   : Start-ScheduledTask -TaskName '$TaskName'"
Write-Host "  Check status: Get-ScheduledTask -TaskName '$TaskName' | Get-ScheduledTaskInfo"
Write-Host "  Remove task : Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false"
