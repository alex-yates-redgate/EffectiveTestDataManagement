# Validate-Classifications.ps1
# ===========================
# CI/CD validation: Ensures all expected sensitive columns are classified
# This script is called by the Azure DevOps pipeline after migrations
# ===========================

param (
    [string]$SqlInstance = "localhost",
    [string]$Database = "Northwind_Build",
    [switch]$FailOnMissing = $true
)

$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Classification Validation" -ForegroundColor Cyan
Write-Host "  Database: $Database" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Import-Module dbatools -Force

# ============================================
# Define the expected sensitive columns
# This is the "golden list" that must all be classified
# ============================================
$expectedSensitiveColumns = @(
    # Customers
    "Sales.Customers.ContactName",
    "Sales.Customers.Address",
    "Sales.Customers.PostalCode",
    "Sales.Customers.Phone",
    "Sales.Customers.Fax",
    "Sales.Customers.Email",
    
    # Employees
    "HR.Employees.FirstName",
    "HR.Employees.LastName",
    "HR.Employees.BirthDate",
    "HR.Employees.Address",
    "HR.Employees.PostalCode",
    "HR.Employees.HomePhone",
    "HR.Employees.Email",
    "HR.Employees.SSN",
    
    # Suppliers
    "Inventory.Suppliers.ContactName",
    "Inventory.Suppliers.Address",
    "Inventory.Suppliers.PostalCode",
    "Inventory.Suppliers.Phone",
    "Inventory.Suppliers.Fax",
    
    # Orders
    "Sales.Orders.ShipName",
    "Sales.Orders.ShipAddress",
    "Sales.Orders.ShipPostalCode"
)

# ============================================
# Get current classifications from the database
# ============================================
Write-Host "Querying current classifications..." -ForegroundColor White

$classificationQuery = @"
SELECT 
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    sc.information_type AS InformationType,
    sc.label AS SensitivityLabel,
    SCHEMA_NAME(t.schema_id) + '.' + t.name + '.' + c.name AS FullColumnName
FROM sys.sensitivity_classifications sc
JOIN sys.columns c ON sc.major_id = c.object_id AND sc.minor_id = c.column_id
JOIN sys.tables t ON c.object_id = t.object_id
ORDER BY SchemaName, TableName, ColumnName
"@

$currentClassifications = Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $classificationQuery

# Build a list of currently classified columns
$classifiedColumns = @()
foreach ($row in $currentClassifications) {
    $classifiedColumns += $row.FullColumnName
}

Write-Host ""
Write-Host "Found $($classifiedColumns.Count) classified columns" -ForegroundColor Green
Write-Host ""

# ============================================
# Compare expected vs actual
# ============================================
$missingClassifications = @()
$extraClassifications = @()

# Check for missing (expected but not classified)
foreach ($expected in $expectedSensitiveColumns) {
    if ($expected -notin $classifiedColumns) {
        $missingClassifications += $expected
    }
}

# Check for extra (classified but not expected) - these are warnings, not failures
foreach ($classified in $classifiedColumns) {
    if ($classified -notin $expectedSensitiveColumns) {
        $extraClassifications += $classified
    }
}

# ============================================
# Report results
# ============================================
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Validation Results" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

if ($missingClassifications.Count -gt 0) {
    Write-Host "[FAIL] Missing classifications ($($missingClassifications.Count)):" -ForegroundColor Red
    foreach ($missing in $missingClassifications) {
        Write-Host "       - $missing" -ForegroundColor Red
    }
    Write-Host ""
}

if ($extraClassifications.Count -gt 0) {
    Write-Host "[INFO] Additional classifications found ($($extraClassifications.Count)):" -ForegroundColor Yellow
    foreach ($extra in $extraClassifications) {
        Write-Host "       + $extra" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($missingClassifications.Count -eq 0) {
    Write-Host "[PASS] All expected sensitive columns are classified!" -ForegroundColor Green
    Write-Host ""
    
    # Show summary table
    Write-Host "Classified columns:" -ForegroundColor Cyan
    $currentClassifications | Format-Table -Property SchemaName, TableName, ColumnName, InformationType, SensitivityLabel -AutoSize
}

# ============================================
# Exit with appropriate code
# ============================================
if ($missingClassifications.Count -gt 0 -and $FailOnMissing) {
    Write-Host "##vso[task.logissue type=error]Classification validation failed: $($missingClassifications.Count) columns missing classifications" 
    exit 1
}

exit 0
