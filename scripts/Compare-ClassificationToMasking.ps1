# Compare-ClassificationToMasking.ps1
# ===========================
# Cross-reference SQL Server classifications against dbatools masking config
# Ensures every classified column has a corresponding masking rule
# ===========================

param (
    [string]$SqlInstance = "localhost",
    [string]$Database = "Northwind_Prod",
    [string]$MaskingConfigPath = "$PSScriptRoot\..\masking\masking-config.json",
    [switch]$FailOnGaps = $true
)

$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Classification vs Masking Cross-Reference" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Import-Module dbatools -Force

# ============================================
# Get classifications from SQL Server
# ============================================
Write-Host "Reading SQL Server classifications from $Database..." -ForegroundColor White

$classificationQuery = @"
SELECT 
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    sc.information_type AS InformationType,
    sc.label AS SensitivityLabel
FROM sys.sensitivity_classifications sc
JOIN sys.columns c ON sc.major_id = c.object_id AND sc.minor_id = c.column_id
JOIN sys.tables t ON c.object_id = t.object_id
ORDER BY SchemaName, TableName, ColumnName
"@

$classifications = Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $classificationQuery

$classifiedColumns = @{}
foreach ($row in $classifications) {
    $key = "$($row.SchemaName).$($row.TableName).$($row.ColumnName)"
    $classifiedColumns[$key] = @{
        InformationType = $row.InformationType
        SensitivityLabel = $row.SensitivityLabel
    }
}

Write-Host "  Found $($classifiedColumns.Count) classified columns" -ForegroundColor Green
Write-Host ""

# ============================================
# Read dbatools masking configuration
# ============================================
Write-Host "Reading masking configuration from $MaskingConfigPath..." -ForegroundColor White

if (-not (Test-Path $MaskingConfigPath)) {
    Write-Host "[ERROR] Masking config file not found: $MaskingConfigPath" -ForegroundColor Red
    exit 1
}

$maskingConfig = Get-Content -Path $MaskingConfigPath -Raw | ConvertFrom-Json

$maskedColumns = @{}
foreach ($table in $maskingConfig.Tables) {
    foreach ($column in $table.Columns) {
        $key = "$($table.Schema).$($table.Name).$($column.Name)"
        $maskedColumns[$key] = @{
            MaskingType = $column.MaskingType
            SubType = $column.SubType
        }
    }
}

Write-Host "  Found $($maskedColumns.Count) columns with masking rules" -ForegroundColor Green
Write-Host ""

# ============================================
# Cross-reference: Find gaps
# ============================================
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Analysis Results" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$classifiedNotMasked = @()
$maskedNotClassified = @()
$bothClassifiedAndMasked = @()

# Check classified columns that aren't masked
foreach ($col in $classifiedColumns.Keys) {
    if ($maskedColumns.ContainsKey($col)) {
        $bothClassifiedAndMasked += $col
    } else {
        $classifiedNotMasked += $col
    }
}

# Check masked columns that aren't classified (might be intentional)
foreach ($col in $maskedColumns.Keys) {
    if (-not $classifiedColumns.ContainsKey($col)) {
        $maskedNotClassified += $col
    }
}

# Report
Write-Host "[OK] Columns both classified AND masked: $($bothClassifiedAndMasked.Count)" -ForegroundColor Green
if ($bothClassifiedAndMasked.Count -gt 0) {
    foreach ($col in $bothClassifiedAndMasked) {
        Write-Host "     $col" -ForegroundColor Gray
    }
}
Write-Host ""

if ($classifiedNotMasked.Count -gt 0) {
    Write-Host "[RISK] Classified but NOT masked: $($classifiedNotMasked.Count)" -ForegroundColor Red
    Write-Host "       These columns contain sensitive data but have no masking rule!" -ForegroundColor Red
    foreach ($col in $classifiedNotMasked) {
        $info = $classifiedColumns[$col]
        Write-Host "       - $col [$($info.InformationType)]" -ForegroundColor Red
    }
    Write-Host ""
}

if ($maskedNotClassified.Count -gt 0) {
    Write-Host "[INFO] Masked but not classified: $($maskedNotClassified.Count)" -ForegroundColor Yellow
    Write-Host "       These have masking rules but no SQL Server classification" -ForegroundColor Yellow
    foreach ($col in $maskedNotClassified) {
        Write-Host "       + $col" -ForegroundColor Yellow
    }
    Write-Host ""
}

# ============================================
# Summary
# ============================================
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total classified:     $($classifiedColumns.Count)" -ForegroundColor White
Write-Host "  Total masking rules:  $($maskedColumns.Count)" -ForegroundColor White
Write-Host "  Coverage:             $($bothClassifiedAndMasked.Count) / $($classifiedColumns.Count)" -ForegroundColor White
Write-Host ""

if ($classifiedNotMasked.Count -eq 0) {
    Write-Host "[PASS] All classified columns have masking rules!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] $($classifiedNotMasked.Count) classified columns have NO masking rules" -ForegroundColor Red
    if ($FailOnGaps) {
        exit 1
    }
}
