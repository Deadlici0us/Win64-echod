Write-Host "Running Functional Test..."
python test_echo.py
if ($LASTEXITCODE -eq 0) {
    Write-Host "Running Concurrency Test..."
    python test_concurrency.py
}
