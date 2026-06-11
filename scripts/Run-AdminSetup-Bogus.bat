@echo off
REM Run PowerShell as Administrator and execute AdminSetup-Bogus.ps1

powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoExit', '-File', '%~dp0AdminSetup-Bogus.ps1'"
pause
