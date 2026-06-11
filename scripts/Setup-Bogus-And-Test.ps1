# Ensure Bogus is available to dbatools by adding it to multiple potential loading locations

Import-Module dbatools -Force

$bogusUserLib = Join-Path $HOME ".dbatools\library\Bogus.dll"

Write-Host "Checking Bogus availability..." -ForegroundColor Cyan
Write-Host "User library: $bogusUserLib" -ForegroundColor Gray

if (-not (Test-Path $bogusUserLib)) {
    Write-Host "[ERROR] Bogus.dll not found at $bogusUserLib" -ForegroundColor Red
    Write-Host "Run Install-BogusLibrary.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Try to make the DLL available to dbatools by adding to AppDomain
try {
    Write-Host "Pre-loading Bogus.dll into AppDomain..." -ForegroundColor Yellow
    [System.Reflection.Assembly]::LoadFrom($bogusUserLib) | Out-Null
    Write-Host "[OK] Bogus loaded" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Could not pre-load Bogus: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Copy to current working directory so .NET can find it
$localCopy = Join-Path $PWD "Bogus.dll"
if (-not (Test-Path $localCopy)) {
    Write-Host "Copying Bogus to working directory..." -ForegroundColor Yellow
    Copy-Item $bogusUserLib $localCopy -Force
    Write-Host "[OK] Copied to: $localCopy" -ForegroundColor Green
}

# Test masking
Write-Host ""
Write-Host "Testing masking with Bogus available..." -ForegroundColor Cyan

$configPath = "$PSScriptRoot\..\masking\masking-config.json"

# Create temp test database
Write-Host "Creating temp test database..." -ForegroundColor Yellow
$createDb = @"
IF DB_ID('Northwind_Masking_Test') IS NOT NULL
    DROP DATABASE Northwind_Masking_Test
CREATE DATABASE Northwind_Masking_Test
"@

Invoke-DbaQuery -SqlInstance 'localhost' -Query $createDb -ErrorAction Stop

# Create simple test table
$createTable = @"
USE Northwind_Masking_Test
CREATE TABLE dbo.TestCustomer (
    ID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Phone NVARCHAR(20)
)
INSERT INTO dbo.TestCustomer VALUES (1, 'John Smith', '555-1234')
"@

Invoke-DbaQuery -SqlInstance 'localhost' -Query $createTable -ErrorAction Stop

# Create minimal test config
$testConfig = @{
    Name = 'Test Masking'
    Type = 'DataMaskingConfiguration'
    Tables = @(
        @{
            Schema = 'dbo'
            Name = 'TestCustomer'
            Columns = @(
                @{
                    Name = 'Name'
                    ColumnType = 'nvarchar'
                    MaskingType = 'Name'
                    SubType = 'FirstName'
                    Nullable = $true
                    KeepNull = $true
                }
            )
        }
    )
}

$testConfigPath = Join-Path $env:TEMP 'test-masking.json'
$testConfig | ConvertTo-Json -Depth 10 | Set-Content $testConfigPath

Write-Host "Running test masking..." -ForegroundColor Yellow
try {
    Invoke-DbaDbDataMasking `
        -SqlInstance 'localhost' `
        -Database 'Northwind_Masking_Test' `
        -FilePath $testConfigPath `
        -Locale 'en_US' `
        -Confirm:$false `
        -Verbose `
        -ErrorAction Stop
    
    Write-Host "[OK] Masking completed!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

# Check results
Write-Host ""
Write-Host "Checking masked data..." -ForegroundColor Cyan
$result = Invoke-DbaQuery -SqlInstance 'localhost' -Database 'Northwind_Masking_Test' -Query "SELECT * FROM dbo.TestCustomer"
$result | Format-Table

# Cleanup
Write-Host ""
Write-Host "Cleaning up..." -ForegroundColor Gray
Invoke-DbaQuery -SqlInstance 'localhost' -Query "DROP DATABASE Northwind_Masking_Test" -ErrorAction SilentlyContinue
Remove-Item $testConfigPath -Force -ErrorAction SilentlyContinue
Remove-Item $localCopy -Force -ErrorAction SilentlyContinue
