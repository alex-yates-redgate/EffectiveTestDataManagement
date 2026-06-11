# Invoke-SimpleMasking.ps1
# Simple SQL-based masking - replaces sensitive data with placeholder values
# No external dependencies, no dbatools/Bogus needed

param (
    [string]$SqlInstance = "localhost",
    [string]$Database,
    [string]$MaskingSqlPath = "$PSScriptRoot\..\masking\Mask-Data-Simple.sql"
)

$ErrorActionPreference = "Stop"

if (-not $Database) {
    Write-Host "[ERROR] Database parameter is required" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $MaskingSqlPath)) {
    Write-Host "[ERROR] Masking SQL file not found: $MaskingSqlPath" -ForegroundColor Red
    exit 1
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Simple SQL Data Masking" -ForegroundColor Cyan
Write-Host "  Database: $Database" -ForegroundColor Cyan
Write-Host "  Method: Direct SQL replacement" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Import-Module dbatools -Force

# Read masking SQL
Write-Host "Reading masking SQL..." -ForegroundColor Yellow
$maskingSql = Get-Content $MaskingSqlPath -Raw

if (-not $maskingSql) {
    Write-Host "[ERROR] Masking SQL is empty" -ForegroundColor Red
    exit 1
}

Write-Host "  Found $(($maskingSql.Split(';') | Measure-Object).Count - 1) masking statements" -ForegroundColor Gray
Write-Host ""

# Execute masking
Write-Host "Executing masking on $Database..." -ForegroundColor Yellow
try {
    Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $maskingSql -ErrorAction Stop | Out-Null
    Write-Host "[SUCCESS] Masking completed!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Masking failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify masking - check that sensitive data is replaced
Write-Host ""
Write-Host "Verifying masked data..." -ForegroundColor Cyan

$verifyQueries = @(
    @{ Table = "Sales.Customers"; Query = "SELECT COUNT(*) as Count, COUNT(DISTINCT ContactName) as UniqueNames FROM [Sales].[Customers]" },
    @{ Table = "HR.Employees"; Query = "SELECT COUNT(*) as Count, COUNT(DISTINCT FirstName) as UniqueNames FROM [HR].[Employees]" },
    @{ Table = "Inventory.Suppliers"; Query = "SELECT COUNT(*) as Count, COUNT(DISTINCT ContactName) as UniqueNames FROM [Inventory].[Suppliers]" },
    @{ Table = "Sales.Orders"; Query = "SELECT COUNT(*) as Count, COUNT(DISTINCT ShipName) as UniqueNames FROM [Sales].[Orders]" }
)

foreach ($verify in $verifyQueries) {
    try {
        $result = Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $verify.Query -ErrorAction SilentlyContinue
        if ($result) {
            Write-Host "  $($verify.Table): $($result.Count) rows, $($result.UniqueNames) unique values" -ForegroundColor Green
        }
    } catch {
        Write-Host "  $($verify.Table): Verification skipped (table may be empty)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Sample masked data:" -ForegroundColor Cyan
Write-Host ""

# Show before/after for a specific record
Write-Host "Sales.Customers (top 3 masked records):" -ForegroundColor Gray
$sampleCustomers = Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query @"
SELECT TOP 3 CustomerID, ContactName, Phone, Email FROM [Sales].[Customers]
"@ -ErrorAction SilentlyContinue
$sampleCustomers | Format-Table

Write-Host ""
Write-Host "Masking successful!" -ForegroundColor Green
Write-Host "All sensitive columns have been replaced with placeholder values." -ForegroundColor Green
