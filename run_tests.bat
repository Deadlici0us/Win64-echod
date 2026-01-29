@echo off
echo Starting Echo Server tests...

echo Running functional test...
python test_echo.py

echo Running concurrency stress test...
python test_concurrency.py

echo Tests finished.
pause