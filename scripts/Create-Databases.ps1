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
    
    Write-Host "  [OK] $dbName created" -ForegroundColor Green
}

Write-Host ""
Write-Host "All databases created successfully!" -ForegroundColor Green
