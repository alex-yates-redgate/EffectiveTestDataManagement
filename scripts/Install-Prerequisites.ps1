# Install-Prerequisites.ps1
# ===========================
# Installs Flyway Community and dbatools if not already present
# ===========================

$ErrorActionPreference = "Stop"

Write-Host "Checking prerequisites..." -ForegroundColor Cyan

# ============================================
# Check/Install dbatools
# ============================================
Write-Host "  Checking dbatools module..." -ForegroundColor White

$dbatools = Get-Module -ListAvailable -Name dbatools
if ($dbatools) {
    Write-Host "  [OK] dbatools v$($dbatools.Version) is installed" -ForegroundColor Green
} else {
    Write-Host "  [INSTALLING] dbatools module..." -ForegroundColor Yellow
    
    # Check if running as admin for system-wide install
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin) {
        Install-Module -Name dbatools -Force -AllowClobber -Scope AllUsers
    } else {
        Install-Module -Name dbatools -Force -AllowClobber -Scope CurrentUser
    }
    
    Write-Host "  [OK] dbatools installed successfully" -ForegroundColor Green
}

# Import dbatools for this session
Import-Module dbatools -Force

# ============================================
# Check/Install Flyway Community
# ============================================
Write-Host "  Checking Flyway CLI..." -ForegroundColor White

$flywayCmd = Get-Command flyway -ErrorAction SilentlyContinue
if ($flywayCmd) {
    $flywayVersion = & flyway --version 2>&1 | Select-Object -First 1
    Write-Host "  [OK] Flyway is installed: $flywayVersion" -ForegroundColor Green
} else {
    Write-Host "  [INSTALLING] Flyway CLI..." -ForegroundColor Yellow
    
    # Download and install Flyway
    $flywayVersion = "11.0.0"  # Update as needed
    $flywayUrl = "https://download.red-gate.com/maven/release/com/redgate/flyway/flyway-commandline/$flywayVersion/flyway-commandline-$flywayVersion-windows-x64.zip"
    $flywayInstallDir = "C:\Flyway"
    $flywayZip = "$env:TEMP\flyway.zip"
    
    Write-Host "    Downloading Flyway $flywayVersion..." -ForegroundColor White
    Invoke-WebRequest -Uri $flywayUrl -OutFile $flywayZip -UseBasicParsing
    
    Write-Host "    Extracting to $flywayInstallDir..." -ForegroundColor White
    if (Test-Path $flywayInstallDir) {
        Remove-Item -Path $flywayInstallDir -Recurse -Force
    }
    Expand-Archive -Path $flywayZip -DestinationPath "C:\" -Force
    Rename-Item -Path "C:\flyway-$flywayVersion" -NewName "Flyway"
    
    # Add to PATH for this session
    $env:PATH = "$flywayInstallDir;$env:PATH"
    
    # Add to PATH permanently (user level)
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$flywayInstallDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$flywayInstallDir;$currentPath", "User")
    }
    
    # Cleanup
    Remove-Item -Path $flywayZip -Force
    
    Write-Host "  [OK] Flyway installed to $flywayInstallDir" -ForegroundColor Green
}

Write-Host ""
Write-Host "Prerequisites check complete!" -ForegroundColor Green
