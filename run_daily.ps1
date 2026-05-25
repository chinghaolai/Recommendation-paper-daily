# Daily arXiv paper fetch and git push
# Run this script manually or via Windows Task Scheduler

# Use the full path to the conda env so Task Scheduler finds the right Python + PyYAML
$PythonExe  = "C:\Users\howard.lai\AppData\Local\anaconda3\envs\rag2\python.exe"
$ProjectDir = $PSScriptRoot
$LogDir     = Join-Path $ProjectDir "logs"
$LogFile    = Join-Path $LogDir "run_daily_$(Get-Date -Format 'yyyyMMdd').log"

$null = New-Item -ItemType Directory -Force -Path $LogDir

# Use Start-Transcript so all output (including Python's stderr) is captured cleanly
Start-Transcript -Path $LogFile -Append | Out-Null

try {
    Set-Location $ProjectDir
    Write-Host "=== Daily arXiv update started: $(Get-Date) ==="

    # Run Python — let it write directly to console (captured by Transcript)
    Write-Host "--- Running daily_arxiv.py ---"
    & $PythonExe daily_arxiv.py --config config.yaml
    if ($LASTEXITCODE -ne 0) {
        throw "Python script failed with exit code $LASTEXITCODE"
    }

    # Git: stage, commit, push
    Write-Host "--- Git: staging changes ---"
    git add README.md docs/

    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        $dateStr = Get-Date -Format "MMM. dd, yyyy"
        Write-Host "--- Git: committing ---"
        git commit -m "Update on $dateStr"

        Write-Host "--- Git: pushing ---"
        git push
        Write-Host "Push successful."
    } else {
        Write-Host "No changes to commit. Skipping push."
    }

    Write-Host "=== Done: $(Get-Date) ==="
}
catch {
    Write-Host "ERROR: $_"
    Stop-Transcript | Out-Null
    exit 1
}

Stop-Transcript | Out-Null
