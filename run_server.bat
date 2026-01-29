@echo off
if exist build\echod.exe (
    build\echod.exe
) else (
    echo Error: echod.exe not found. Please run build.bat first.
)