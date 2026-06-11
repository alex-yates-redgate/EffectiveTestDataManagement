# AdminSetup-Bogus.ps1
# One-time admin setup script for the build agent
# This script must be run as Administrator to install Bogus to dbatools module folder

# Check admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script requires Administrator privileges" -ForegroundColor Red
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  Right-click PowerShell and select 'Run as administrator'" -ForegroundColor Gray
    Write-Host "  Then run: ..\AdminSetup-Bogus.ps1" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host "===============================================" -ForegroundColor Green
Write-Host "  Bogus Faker Library Setup (Admin)" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""

# Find dbatools module
Import-Module dbatools -Force -ErrorAction Stop
$dbatoolsPath = (Get-Module dbatools -ListAvailable | Select-Object -First 1).ModuleBase
$libraryPath = Join-Path $dbatoolsPath 'library'

Write-Host "dbatools: $dbatoolsPath" -ForegroundColor Gray
Write-Host "Target: $libraryPath" -ForegroundColor Gray
Write-Host ""

# Check if already installed
$bogusDll = Join-Path $libraryPath "Bogus.dll"
if (Test-Path $bogusDll) {
    Write-Host "[OK] Bogus.dll already installed" -ForegroundColor Green
    Get-Item $bogusDll | Select-Object Name, @{Name="Size(KB)";Expression={[math]::Round($_.Length/1KB,2)}}
    Write-Host ""
    Write-Host "Masking is ready to use!" -ForegroundColor Green
    exit 0
}

# Create library folder
Write-Host "Creating library folder..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $libraryPath -Force -ErrorAction Stop | Out-Null

# Download Bogus
$bogusUrl = "https://globalcdn.nuget.org/packages/bogus.35.5.1.nupkg"
$bogusNupkg = Join-Path $env:TEMP "bogus-install.nupkg"
$bogusZip = Join-Path $env:TEMP "bogus-install.zip"
$bogusExtractPath = Join-Path $env:TEMP "bogus-install-extract"

Write-Host ""
Write-Host "Downloading Bogus v35.5.1 from NuGet..." -ForegroundColor Yellow
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $bogusUrl -OutFile $bogusNupkg -ErrorAction Stop | Out-Null
Write-Host "Downloaded!" -ForegroundColor Green

# Extract (.nupkg files are ZIP archives)
Write-Host "Extracting..." -ForegroundColor Yellow
if (Test-Path $bogusExtractPath) { Remove-Item $bogusExtractPath -Recurse -Force }
Rename-Item $bogusNupkg -NewName (Split-Path $bogusZip -Leaf) -Force
Expand-Archive $bogusZip -DestinationPath $bogusExtractPath -Force

# Copy DLLs
Write-Host "Installing to dbatools library folder..." -ForegroundColor Yellow
$sourcePath = Join-Path $bogusExtractPath "lib/netstandard2.1"
if (-not (Test-Path $sourcePath)) {
    $sourcePath = Join-Path $bogusExtractPath "lib/net6.0"
}

$dlls = Get-ChildItem $sourcePath -Filter "*.dll" -ErrorAction Stop
foreach ($dll in $dlls) {
    $target = Join-Path $libraryPath $dll.Name
    Copy-Item $dll.FullName -Destination $target -Force
    Write-Host "  [OK] $($dll.Name)" -ForegroundColor Green
}

# Verify
Write-Host ""
if (Test-Path $bogusDll) {
    Write-Host "[SUCCESS] Bogus installed successfully!" -ForegroundColor Green
    Write-Host ""
    Get-Item $bogusDll | Select-Object Name, @{Name="Size(KB)";Expression={[math]::Round($_.Length/1KB,2)}}
    Write-Host ""
    Write-Host "dbatools masking is now ready for production use." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Restart PowerShell or the pipeline agent" -ForegroundColor Gray
    Write-Host "  2. Run the data-refresh-pipeline" -ForegroundColor Gray
    Write-Host "  3. Masking will now generate real faker data" -ForegroundColor Gray
} else {
    Write-Host "[ERROR] Installation failed!" -ForegroundColor Red
    exit 1
}

# Cleanup
Write-Host ""
Write-Host "Cleaning up temp files..." -ForegroundColor Gray
Remove-Item $bogusZip -Force -ErrorAction SilentlyContinue
Remove-Item $bogusExtractPath -Recurse -Force -ErrorAction SilentlyContinue
