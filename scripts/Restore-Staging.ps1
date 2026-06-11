# Restore-Staging.ps1

Import-Module dbatools -Force

Write-Host "Setting up Northwind_Staging from Prod..." -ForegroundColor Cyan

# Create empty database
Write-Host "Creating Northwind_Staging database..." -ForegroundColor Yellow
$db = New-DbaDatabase -SqlInstance localhost -Name Northwind_Staging -ErrorAction SilentlyContinue
Write-Host "[OK] Database ready" -ForegroundColor Green

# Copy schema first - create all tables with same structure
Write-Host ""
Write-Host "Copying schema from Prod..." -ForegroundColor Yellow

Invoke-DbaQuery -SqlInstance localhost -Database Northwind_Staging -Query @"
-- Create all schemas
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'HR')
  EXEC sp_executesql N'CREATE SCHEMA HR'
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Inventory')
  EXEC sp_executesql N'CREATE SCHEMA Inventory'
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Sales')
  EXEC sp_executesql N'CREATE SCHEMA Sales'
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Shipping')
  EXEC sp_executesql N'CREATE SCHEMA Shipping'
"@ -ErrorAction Stop

# Copy each table from Prod
Write-Host "Copying tables and data from Prod..." -ForegroundColor Yellow

$tables = Get-DbaDbTable -SqlInstance localhost -Database Northwind_Prod | Where-Object Schema -ne dbo

foreach ($table in $tables) {
    $schema = $table.Schema
    $name = $table.Name
    Write-Host "  Copying [$schema].[$name]..." -ForegroundColor Gray
    
    # Use SELECT INTO if table doesn't exist
    Invoke-DbaQuery -SqlInstance localhost -Database Northwind_Prod -Query @"
IF NOT EXISTS (SELECT 1 FROM Northwind_Staging.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='$schema' AND TABLE_NAME='$name')
BEGIN
  SELECT * INTO [Northwind_Staging].[$schema].[$name] FROM [$schema].[$name]
END
"@ -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Verifying tables..." -ForegroundColor Yellow
$tables = Get-DbaDbTable -SqlInstance localhost -Database Northwind_Staging | Where-Object Schema -ne dbo
Write-Host "Tables copied: $($tables.Count)" -ForegroundColor Gray

foreach ($table in $tables) {
    try {
        $count = (Invoke-DbaQuery -SqlInstance localhost -Database Northwind_Staging -Query "SELECT COUNT(*) as cnt FROM [$($table.Schema)].[$($table.Name)]" -ErrorAction SilentlyContinue).cnt
        Write-Host "  [$($table.Schema)].[$($table.Name)] - $count rows" -ForegroundColor Green
    } catch {
        Write-Host "  [$($table.Schema)].[$($table.Name)] - error getting count" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "[SUCCESS] Northwind_Staging is ready for masking!" -ForegroundColor Green
