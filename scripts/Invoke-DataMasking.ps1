# Invoke-DataMasking.ps1
# ===========================
# Applies data masking using dbatools Invoke-DbaDbDataMasking
# Used in the data refresh pipeline to mask production data for dev/test
#
# REQUIREMENTS:
# - dbatools module (masking feature)
# - Bogus NuGet package (faker library for generating masked values)
#
# KNOWN ISSUE:
# If masking completes but produces empty values (UPDATE SET Column = ISNULL(, '')),
# it means Bogus.dll was not found by dbatools. This is a known dbatools issue.
#
# SOLUTION:
# Option 1: Run Install-BogusLibrary.ps1 with admin privileges
#   This installs Bogus to Program Files\WindowsPowerShell\Modules\dbatools\library
#
# Option 2: Run pipeline agent with admin privileges
#   Self-hosted agents can be configured to run elevated for setup steps
#
# Option 3: Pre-configure Bogus on the build server before masking runs
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

# Pre-load Bogus faker library so dbatools masking can use it
$bogusLibPath = Join-Path $HOME ".dbatools\library"
if (Test-Path $bogusLibPath) {
    Write-Host "Loading Bogus faker library..." -ForegroundColor Gray
    $bogusDll = Join-Path $bogusLibPath "Bogus.dll"
    if (Test-Path $bogusDll) {
        [System.Reflection.Assembly]::LoadFrom($bogusDll) | Out-Null
        Write-Host "[OK] Bogus.dll loaded" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Bogus.dll not found at $bogusDll" -ForegroundColor Yellow
    }
}

# ============================================
# Validate masking config exists
# ============================================
if (-not (Test-Path $MaskingConfigPath)) {
    Write-Host "[ERROR] Masking config not found: $MaskingConfigPath" -ForegroundColor Red
    exit 1
}

Write-Host "Using masking config: $MaskingConfigPath" -ForegroundColor Cyan
Write-Host ""

Write-Host "Using masking config: $MaskingConfigPath" -ForegroundColor White
Write-Host ""

# ============================================
# Normalize and validate masking config for dbatools
# ============================================
$maskingConfig = Get-Content -Path $MaskingConfigPath -Raw | ConvertFrom-Json

# Use the masking config as-is without normalization (normalization was stripping faker parameters)
$normalizedConfigPath = $MaskingConfigPath

try {
    $configValidation = Test-DbaDbDataMaskingConfig -FilePath $normalizedConfigPath -EnableException -ErrorAction Stop
    if ($configValidation) {
        Write-Host "[ERROR] Masking config validation failed:" -ForegroundColor Red
        $configValidation | Format-Table -AutoSize | Out-String | Write-Host
        exit 1
    }
}
catch {
    Write-Host "[ERROR] Masking config is invalid: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Masking config validation passed" -ForegroundColor Green
Write-Host ""

# ============================================
# Show what will be masked
# ============================================
# Reload config for display (already validated)
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
    $WarningPreference = "Stop"

    # Invoke-DbaDbDataMasking with verbose output to debug faker issue
    Invoke-DbaDbDataMasking `
        -SqlInstance $SqlInstance `
        -Database $Database `
        -FilePath $MaskingConfigPath `
        -Locale 'en_US' `
        -Confirm:$false `
        -EnableException `
        -WarningAction Stop `
        -ErrorAction Stop

    # Safety gate: if these known production sentinel values still exist,
    # masking did not actually apply and the pipeline must fail.
    $sentinelCheck = @"
SELECT
    SUM(CASE WHEN EXISTS (SELECT 1 FROM Sales.Customers WHERE CustomerID = 'ALFKI' AND ContactName = 'Maria Anders') THEN 1 ELSE 0 END) AS RawCustomerStillPresent,
    SUM(CASE WHEN EXISTS (SELECT 1 FROM HR.Employees WHERE EmployeeID = 1 AND SSN = '123-45-6789') THEN 1 ELSE 0 END) AS RawEmployeeStillPresent
"@

    $sentinelResult = Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $sentinelCheck
    if ($sentinelResult.RawCustomerStillPresent -gt 0 -or $sentinelResult.RawEmployeeStillPresent -gt 0) {
        Write-Host "[ERROR] Sentinel values indicate masking did not apply. Aborting to protect Dev/Test." -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "[SUCCESS] Data masking completed and sentinel checks passed!" -ForegroundColor Green
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
