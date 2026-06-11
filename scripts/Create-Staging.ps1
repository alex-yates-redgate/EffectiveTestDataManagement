# Create-Staging.ps1 - Quick setup for testing

Import-Module dbatools -Force

Write-Host "Creating Northwind_Staging database..." -ForegroundColor Cyan

# Create empty staging database
$newDb = New-DbaDatabase -SqlInstance localhost -Name Northwind_Staging -ErrorAction SilentlyContinue
Write-Host "[OK] Database created" -ForegroundColor Green

# Copy all tables from Prod to Staging
Write-Host "Copying tables from Prod..." -ForegroundColor Yellow
$tables = Get-DbaDbTable -SqlInstance localhost -Database Northwind_Prod
Write-Host "Found $($tables.Count) tables" -ForegroundColor Gray

foreach ($table in $tables) {
    $schema = $table.Schema
    $tableName = $table.Name
    $fullName = "[$schema].[$tableName]"
    $stagingName = "[Northwind_Staging].[$schema].[$tableName]"
    
    Write-Host "  Copying $fullName..." -ForegroundColor Gray
    
    Invoke-DbaQuery -SqlInstance localhost -Database Northwind_Prod -Query @"
IF NOT EXISTS (SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA='$schema' AND TABLE_NAME='$tableName' AND TABLE_CATALOG='Northwind_Staging')
  SELECT * INTO $stagingName FROM $fullName
"@ -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "[OK] Northwind_Staging ready for masking!" -ForegroundColor Green

# Verify
$stagingTables = Get-DbaDbTable -SqlInstance localhost -Database Northwind_Staging
Write-Host "Staging tables: $($stagingTables.Count)" -ForegroundColor Cyan
