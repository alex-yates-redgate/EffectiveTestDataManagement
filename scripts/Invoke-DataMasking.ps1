# Invoke-DataMasking.ps1
# ===========================
# Applies data masking to the database
# Used in the data refresh pipeline to mask production data for dev/test
#
# Simple SQL-based approach: Replaces sensitive columns with placeholder values
# No external dependencies needed (no dbatools Bogus library required)
# ===========================

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

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Data Masking" -ForegroundColor Cyan
Write-Host "  Database: $Database" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Import-Module dbatools -Force

# Read masking SQL
Write-Host "Loading masking SQL..." -ForegroundColor Yellow
if (-not (Test-Path $MaskingSqlPath)) {
    Write-Host "[ERROR] Masking SQL file not found: $MaskingSqlPath" -ForegroundColor Red
    exit 1
}

$maskingSql = Get-Content $MaskingSqlPath -Raw
Write-Host "  SQL file loaded successfully" -ForegroundColor Green
Write-Host ""

# Execute masking
Write-Host "Executing masking on $Database..." -ForegroundColor Yellow
try {
    Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $maskingSql -ErrorAction Stop | Out-Null
    Write-Host "[SUCCESS] Masking completed!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Masking failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Verifying masked data..." -ForegroundColor Cyan

# Show sample masked data
Write-Host ""
Write-Host "Sample masked records from Sales.Customers:" -ForegroundColor Gray
try {
    $sample = Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query @"
SELECT TOP 3 CustomerID, ContactName, Phone, Email FROM [Sales].[Customers]
"@ -ErrorAction SilentlyContinue
    
    if ($sample) {
        $sample | Format-Table -AutoSize
    }
} catch {
    Write-Host "  (Could not verify - table may be empty or not accessible)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "[SUCCESS] Data masking complete!" -ForegroundColor Green
Write-Host "All sensitive columns have been masked with placeholder values." -ForegroundColor Green
