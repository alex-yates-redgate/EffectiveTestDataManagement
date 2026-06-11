# Install Bogus to user folder (doesn't require admin access)

Import-Module dbatools -Force

$userLibPath = Join-Path $HOME ".dbatools\library"

Write-Host "Installing Bogus faker library to: $userLibPath" -ForegroundColor Cyan

# Create user library folder
if (-not (Test-Path $userLibPath)) {
    New-Item -ItemType Directory -Path $userLibPath -Force | Out-Null
}

# Download Bogus NuGet package
$bogusUrl = "https://globalcdn.nuget.org/packages/bogus.35.5.1.nupkg"
$bogusNupkg = Join-Path $env:TEMP "bogus.35.5.1.nupkg"
$bogusZip = Join-Path $env:TEMP "bogus.35.5.1.zip"  # Rename for extraction
$bogusExtractPath = Join-Path $env:TEMP "bogus-extract"

Write-Host "Downloading Bogus v35.5.1..." -ForegroundColor Yellow
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $bogusUrl -OutFile $bogusNupkg -ErrorAction Stop
Write-Host "Downloaded!" -ForegroundColor Green

# Rename .nupkg to .zip for extraction (they're the same format)
Write-Host "Preparing for extraction..." -ForegroundColor Yellow
Rename-Item -Path $bogusNupkg -NewName (Split-Path $bogusZip -Leaf) -Force

Write-Host "Extracting..." -ForegroundColor Yellow
if (Test-Path $bogusExtractPath) {
    Remove-Item $bogusExtractPath -Recurse -Force
}
Expand-Archive -Path $bogusZip -DestinationPath $bogusExtractPath -Force

# Find and copy DLLs
Write-Host "Copying DLLs to user library..." -ForegroundColor Yellow

# Try netstandard2.1 first
$sourcePath = Join-Path $bogusExtractPath "lib/netstandard2.1"
if (-not (Test-Path $sourcePath)) {
    # Fallback to net6.0
    $sourcePath = Join-Path $bogusExtractPath "lib/net6.0"
}

if (Test-Path $sourcePath) {
    $dlls = Get-ChildItem $sourcePath -Filter "*.dll"
    foreach ($dll in $dlls) {
        Copy-Item $dll.FullName -Destination (Join-Path $userLibPath $dll.Name) -Force
        Write-Host "  Copied: $($dll.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "ERROR: Could not find netstandard2.1 or net6.0 in Bogus package" -ForegroundColor Red
    exit 1
}

# Cleanup
Remove-Item $bogusZip -Force -ErrorAction SilentlyContinue
Remove-Item $bogusExtractPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[SUCCESS] Bogus installed to: $userLibPath" -ForegroundColor Green
Write-Host ""
Write-Host "Contents:" -ForegroundColor Cyan
Get-ChildItem $userLibPath | Select-Object Name
