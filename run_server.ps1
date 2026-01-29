if (Test-Path "build\echod.exe") {
    Write-Host "Starting Server..."
    & "build\echod.exe"
} elseif (Test-Path "build\Release\echod.exe") {
    Write-Host "Starting Server..."
    & "build\Release\echod.exe"
} else {
    Write-Host "Executable not found. Please run build.ps1 first."
}
