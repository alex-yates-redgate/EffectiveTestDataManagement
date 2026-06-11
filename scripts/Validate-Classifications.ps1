# Validate-Classifications.ps1
# ===========================
# CI/CD validation with two critical checks:
# 1. No unclassified columns (catches new columns that weren't tagged)
# 2. All classified sensitive columns have masking rules (catches incomplete masking config)
# This script is called by the Azure DevOps pipeline after migrations
# ===========================

param (
    [string]$SqlInstance = "localhost",
    [string]$Database = "Northwind_Build",
    [string]$MaskingConfigPath = "$PSScriptRoot\..\masking\masking-config.json",
    [switch]$FailOnIssues = $true
)

$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Classification & Masking Validation" -ForegroundColor Cyan
Write-Host "  Database: $Database" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Import-Module dbatools -Force

# ============================================
# TEST 1: Check for UNCLASSIFIED columns
# ============================================
Write-Host "[TEST 1] Checking for unclassified columns..." -ForegroundColor White

$allColumnsQuery = @"
SELECT 
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    SCHEMA_NAME(t.schema_id) + '.' + t.name + '.' + c.name AS FullColumnName
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
WHERE SCHEMA_NAME(t.schema_id) IN ('Sales', 'HR', 'Inventory', 'Shipping')
ORDER BY SchemaName, TableName, ColumnName
"@

$allColumns = Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $allColumnsQuery

# Get classified columns
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

$classifiedColumns = Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $classificationQuery

# Build classified set
$classifiedSet = @{}
foreach ($row in $classifiedColumns) {
    $classifiedSet[$row.FullColumnName] = @{
        InformationType = $row.InformationType
        SensitivityLabel = $row.SensitivityLabel
    }
}

Write-Host "  Total columns in schema: $($allColumns.Count)"
Write-Host "  Classified columns: $($classifiedSet.Count)"
Write-Host ""

# Find unclassified
$unclassifiedColumns = @()
foreach ($col in $allColumns) {
    if ($col.FullColumnName -notin $classifiedSet.Keys) {
        $unclassifiedColumns += $col
    }
}

$test1Pass = $unclassifiedColumns.Count -eq 0

if ($test1Pass) {
    Write-Host "[PASS] All $($allColumns.Count) columns are classified!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Found $($unclassifiedColumns.Count) unclassified columns:" -ForegroundColor Red
    foreach ($col in $unclassifiedColumns) {
        Write-Host "       - $($col.FullColumnName)" -ForegroundColor Red
    }
}
Write-Host ""

# ============================================
# TEST 2: Check for CLASSIFIED but UNMASKED columns
# ============================================
Write-Host "[TEST 2] Checking for classified columns without masking rules..." -ForegroundColor White

# Load masking config
if (-not (Test-Path $MaskingConfigPath)) {
    Write-Host "[FAIL] Masking config not found at $MaskingConfigPath" -ForegroundColor Red
    exit 1
}

$maskingConfig = Get-Content $MaskingConfigPath | ConvertFrom-Json

# Build masking coverage set
$maskedColumns = @{}
foreach ($table in $maskingConfig.Tables) {
    $schema = $table.Schema
    $tableName = $table.Name
    
    foreach ($column in $table.Columns) {
        $fullName = "$schema.$tableName.$($column.Name)"
        $maskedColumns[$fullName] = $true
    }
}

Write-Host "  Masking config covers: $($maskedColumns.Count) columns"
Write-Host ""

# Find classified but not masked
$classifiedButNotMasked = @()
foreach ($fullName in $classifiedSet.Keys) {
    $classification = $classifiedSet[$fullName]
    
    # Only check "sensitive" classifications (excluding "Not Sensitive")
    if ($classification.SensitivityLabel -ne "Not Sensitive" -and -not $maskedColumns.ContainsKey($fullName)) {
        $classifiedButNotMasked += @{
            Column = $fullName
            Label = $classification.SensitivityLabel
            InformationType = $classification.InformationType
        }
    }
}

$test2Pass = $classifiedButNotMasked.Count -eq 0

if ($test2Pass) {
    Write-Host "[PASS] All sensitive classified columns have masking rules!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Found $($classifiedButNotMasked.Count) classified but unmasked columns:" -ForegroundColor Red
    foreach ($item in $classifiedButNotMasked) {
        Write-Host "       - $($item.Column) [$($item.Label)]" -ForegroundColor Red
    }
}
Write-Host ""

# ============================================
# Summary
# ============================================
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Validation Summary" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

if ($test1Pass -and $test2Pass) {
    Write-Host "[SUCCESS] All validation tests passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your data is appropriately tagged and masking rules are complete." -ForegroundColor Green
    Write-Host ""
    exit 0
} else {
    Write-Host "[FAILURE] Validation issues found:" -ForegroundColor Red
    if (-not $test1Pass) {
        Write-Host "  • Unclassified columns detected (new column added without classification?)" -ForegroundColor Red
    }
    if (-not $test2Pass) {
        Write-Host "  • Sensitive columns classified but no masking rule (incomplete masking config?)" -ForegroundColor Red
    }
    Write-Host ""
    if ($FailOnIssues) {
        Write-Host "##vso[task.logissue type=error]Validation failed - see details above"
        exit 1
    }
}
