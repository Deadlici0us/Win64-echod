Write-Host "Building Win64-echod..."
if (!(Test-Path "build")) { mkdir build }
Push-Location build
cmake ..
cmake --build . --config Release
Pop-Location
Write-Host "Build Complete."
