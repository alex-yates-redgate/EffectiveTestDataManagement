# Invoke-DataMasking.ps1
# ===========================
# Applies data masking using dbatools Invoke-DbaDbDataMasking
# Used in the data refresh pipeline to mask production data for dev/test
# ===========================

param (
    [string]$SqlInstance = "localhost",
    [string]$Database,
    [string]$MaskingConfigPath = "$PSScriptRoot\..\masking\masking-config.json"
)

$ErrorActionPreference = "Stop"

if (-not $Database) {
    Write-Host "[ERROR] Database parameter is required" -ForegroundColor Red
    exit 1
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Data Masking with dbatools" -ForegroundColor Cyan
Write-Host "  Database: $Database" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Import-Module dbatools -Force

# ============================================
# Validate masking config exists
# ============================================
if (-not (Test-Path $MaskingConfigPath)) {
    Write-Host "[ERROR] Masking config not found: $MaskingConfigPath" -ForegroundColor Red
    exit 1
}

Write-Host "Using masking config: $MaskingConfigPath" -ForegroundColor White
Write-Host ""

# ============================================
# Show what will be masked
# ============================================
$maskingConfig = Get-Content -Path $MaskingConfigPath -Raw | ConvertFrom-Json

Write-Host "Tables to be masked:" -ForegroundColor Cyan
foreach ($table in $maskingConfig.Tables) {
    Write-Host "  $($table.Schema).$($table.Name)" -ForegroundColor White
    foreach ($column in $table.Columns) {
        Write-Host "    - $($column.Name): $($column.MaskingType)" -ForegroundColor Gray
    }
}
Write-Host ""

# ============================================
# Perform masking
# ============================================
Write-Host "Starting data masking..." -ForegroundColor Yellow
Write-Host ""

try {
    # Invoke-DbaDbDataMasking applies the masking rules from the JSON config
    Invoke-DbaDbDataMasking -SqlInstance $SqlInstance -Database $Database -FilePath $MaskingConfigPath -Confirm:$false
    
    Write-Host ""
    Write-Host "[SUCCESS] Data masking completed!" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Masking failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ============================================
# Verification: Show sample of masked data
# ============================================
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Verification - Sample Masked Data" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$sampleQuery = @"
SELECT TOP 5 
    CustomerID, 
    CompanyName,
    ContactName AS 'ContactName (Masked)',
    Address AS 'Address (Masked)',
    Phone AS 'Phone (Masked)',
    Email AS 'Email (Masked)'
FROM Sales.Customers
"@

Write-Host "Sample from Sales.Customers:" -ForegroundColor Cyan
Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $sampleQuery | Format-Table -AutoSize

$employeeSample = @"
SELECT TOP 5 
    EmployeeID,
    FirstName AS 'FirstName (Masked)',
    LastName AS 'LastName (Masked)',
    HomePhone AS 'Phone (Masked)',
    SSN AS 'SSN (Masked)'
FROM HR.Employees
"@

Write-Host "Sample from HR.Employees:" -ForegroundColor Cyan
Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $employeeSample | Format-Table -AutoSize
