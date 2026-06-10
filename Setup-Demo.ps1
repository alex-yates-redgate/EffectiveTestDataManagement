# Setup-Demo.ps1
# ===========================
# Main setup script for Effective Test Data Management demo
# Data Ceili 2026
# ===========================

param (
    [string]$SqlInstance = "localhost",
    [switch]$SkipPrerequisites,
    [switch]$SkipDatabases,
    [switch]$SkipClassifications
)

$ErrorActionPreference = "Stop"
$scriptRoot = $PSScriptRoot

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Effective Test Data Management - Setup" -ForegroundColor Cyan
Write-Host "  Data Ceili 2026" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Install Prerequisites
if (-not $SkipPrerequisites) {
    Write-Host "Step 1: Installing prerequisites..." -ForegroundColor Yellow
    & "$scriptRoot\scripts\Install-Prerequisites.ps1"
    Write-Host ""
}

# Step 2: Create Databases
if (-not $SkipDatabases) {
    Write-Host "Step 2: Creating Northwind databases..." -ForegroundColor Yellow
    & "$scriptRoot\scripts\Create-Databases.ps1" -SqlInstance $SqlInstance
    Write-Host ""
}

# Step 3: Apply Classifications
if (-not $SkipClassifications) {
    Write-Host "Step 3: Applying data classifications..." -ForegroundColor Yellow
    & "$scriptRoot\scripts\Apply-Classifications.ps1" -SqlInstance $SqlInstance
    Write-Host ""
}

Write-Host "=============================================" -ForegroundColor Green
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Databases created:" -ForegroundColor Cyan
Write-Host "  - Northwind_Dev  (empty schema)" -ForegroundColor White
Write-Host "  - Northwind_Test (empty schema)" -ForegroundColor White
Write-Host "  - Northwind_Prod (with sample data)" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Import this repo into Azure DevOps" -ForegroundColor White
Write-Host "  2. Create pipelines from AzureDevOps/*.yml" -ForegroundColor White
Write-Host "  3. Run the CI/CD pipeline to deploy migrations" -ForegroundColor White
Write-Host ""
