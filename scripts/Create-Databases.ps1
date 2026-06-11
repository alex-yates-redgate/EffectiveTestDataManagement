# Create-Databases.ps1
# ===========================
# Creates Northwind_Dev, Northwind_Test, and Northwind_Prod databases
# ===========================

param (
    [string]$SqlInstance = "localhost"
)

$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $PSScriptRoot

Write-Host "Creating Northwind databases on $SqlInstance..." -ForegroundColor Cyan

# Import dbatools
Import-Module dbatools -Force

# Database names
$databases = @(
    @{ Name = "Northwind_Dev";  LoadData = $false },
    @{ Name = "Northwind_Test"; LoadData = $false },
    @{ Name = "Northwind_Prod"; LoadData = $true }
)

# Find flyway on PATH
$flywayCmd = Get-Command flyway -ErrorAction SilentlyContinue
if (-not $flywayCmd) {
    Write-Host "WARNING: flyway not found in PATH - skipping baseline stamping" -ForegroundColor Yellow
    Write-Host "         Run Install-Prerequisites.ps1 first if you want baseline stamping." -ForegroundColor Yellow
}

foreach ($db in $databases) {
    $dbName = $db.Name
    
    Write-Host "  Creating $dbName..." -ForegroundColor White
    
    # Drop if exists
    $existingDb = Get-DbaDatabase -SqlInstance $SqlInstance -Database $dbName -ErrorAction SilentlyContinue
    if ($existingDb) {
        Write-Host "    Dropping existing database..." -ForegroundColor Yellow
        Remove-DbaDatabase -SqlInstance $SqlInstance -Database $dbName -Confirm:$false
    }
    
    # Create database
    New-DbaDatabase -SqlInstance $SqlInstance -Name $dbName | Out-Null
    
    # Apply schema
    Write-Host "    Applying schema..." -ForegroundColor White
    $schemaScript = Get-Content -Path "$scriptRoot\database\Northwind-Schema.sql" -Raw
    Invoke-DbaQuery -SqlInstance $SqlInstance -Database $dbName -Query $schemaScript
    
    # Load data for Prod only
    if ($db.LoadData) {
        Write-Host "    Loading production data..." -ForegroundColor White
        $dataScript = Get-Content -Path "$scriptRoot\database\Northwind-Data.sql" -Raw
        Invoke-DbaQuery -SqlInstance $SqlInstance -Database $dbName -Query $dataScript
    }
    
    # Stamp the Flyway schema history table at version 001 so the pipeline
    # knows the schema already exists and won't try to re-run V001
    if ($flywayCmd) {
        Write-Host "    Baselining Flyway history at version 001..." -ForegroundColor White
        $environment = $dbName -replace 'Northwind_', '' | ForEach-Object { $_.ToLower() }
        & flyway baseline `
            -environment="$environment" `
            -configFiles="$scriptRoot\flyway.toml" `
            -locations="filesystem:$scriptRoot\migrations" `
            -baselineVersion="001" `
            -baselineDescription="Baseline"
    }
    
    Write-Host "  [OK] $dbName created" -ForegroundColor Green
}

Write-Host ""
Write-Host "All databases created successfully!" -ForegroundColor Green
