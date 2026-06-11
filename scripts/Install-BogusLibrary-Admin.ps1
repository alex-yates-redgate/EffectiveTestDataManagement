# Install-BogusLibrary-Admin.ps1
# Install Bogus to dbatools module folder (requires admin)
# Run this once on the build agent to set up dbatools masking

param(
    [switch]$Force
)

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "Run as admin to install Bogus to dbatools module folder" -ForegroundColor Yellow
    exit 1
}

Write-Host "Installing Bogus faker library for dbatools (Admin mode)" -ForegroundColor Cyan

Import-Module dbatools -Force

$dbatoolsPath = (Get-Module dbatools -ListAvailable | Select-Object -First 1).ModuleBase
$libraryPath = Join-Path $dbatoolsPath 'library'

Write-Host "Target: $libraryPath" -ForegroundColor Gray

# Create library folder
if (-not (Test-Path $libraryPath)) {
    Write-Host "Creating library folder..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $libraryPath -Force | Out-Null
} elseif (Test-Path (Join-Path $libraryPath "Bogus.dll")) {
    Write-Host "[OK] Bogus.dll already installed" -ForegroundColor Green
    if (-not $Force) {
        Write-Host "Use -Force to reinstall" -ForegroundColor Gray
        exit 0
    }
}

# Download Bogus
$bogusUrl = "https://globalcdn.nuget.org/packages/bogus.35.5.1.nupkg"
$bogusZip = Join-Path $env:TEMP "bogus.35.5.1.nupkg"
$bogusExtractPath = Join-Path $env:TEMP "bogus-extract"

Write-Host ""
Write-Host "Downloading Bogus v35.5.1..." -ForegroundColor Yellow
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $bogusUrl -OutFile $bogusZip -ErrorAction Stop
Write-Host "Downloaded!" -ForegroundColor Green

Write-Host "Extracting..." -ForegroundColor Yellow
if (Test-Path $bogusExtractPath) { Remove-Item $bogusExtractPath -Recurse -Force }
Expand-Archive -Path $bogusZip -DestinationPath $bogusExtractPath -Force

# Copy DLLs
Write-Host "Installing to dbatools library..." -ForegroundColor Yellow

$sourcePath = Join-Path $bogusExtractPath "lib/netstandard2.1"
if (-not (Test-Path $sourcePath)) {
    $sourcePath = Join-Path $bogusExtractPath "lib/net6.0"
}

if (Test-Path $sourcePath) {
    $dlls = Get-ChildItem $sourcePath -Filter "*.dll"
    foreach ($dll in $dlls) {
        $targetPath = Join-Path $libraryPath $dll.Name
        Copy-Item $dll.FullName -Destination $targetPath -Force
        Write-Host "  Copied: $($dll.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "[ERROR] Could not find DLLs in Bogus package" -ForegroundColor Red
    exit 1
}

# Cleanup
Write-Host ""
Write-Host "Cleaning up..." -ForegroundColor Gray
Remove-Item $bogusZip -Force -ErrorAction SilentlyContinue
Remove-Item $bogusExtractPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[SUCCESS] Bogus installed to: $libraryPath" -ForegroundColor Green
Write-Host ""
Write-Host "dbatools masking is now ready!" -ForegroundColor Green
