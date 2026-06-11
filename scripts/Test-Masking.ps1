Import-Module dbatools -Force

# Read the actual masking config
$configPath = "$PSScriptRoot\..\masking\masking-config.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json

# Add some debugging to see what columns are being processed
Write-Host "Config loaded. Tables: $($config.Tables.Count)" -ForegroundColor Cyan
foreach ($table in $config.Tables) {
    Write-Host "  $($table.Schema).$($table.Name): $($table.Columns.Count) columns" -ForegroundColor Gray
    foreach ($col in $table.Columns) {
        Write-Host "    - $($col.Name) ($($col.MaskingType)/$($col.SubType))" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Testing masking config validation..." -ForegroundColor Yellow
$validation = Test-DbaDbDataMaskingConfig -FilePath $configPath -EnableException -ErrorAction Stop
if ($validation) {
    Write-Host "Validation errors found:" -ForegroundColor Red
    Write-Output $validation
} else {
    Write-Host "Validation passed!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Invoking masking with verbose output..." -ForegroundColor Yellow

# Try masking with verbose output
try {
    Invoke-DbaDbDataMasking `
        -SqlInstance 'localhost' `
        -Database 'Northwind_Staging' `
        -FilePath $configPath `
        -Locale 'en_US' `
        -Confirm:$false `
        -Verbose `
        -ErrorAction Stop
    
    Write-Host "[SUCCESS] Masking completed!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Masking failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error:" -ForegroundColor Red
    Write-Output $_
}

# Check if data was actually masked
Write-Host ""
Write-Host "Checking masked data..." -ForegroundColor Cyan
$query = "SELECT TOP 3 CustomerID, ContactName, Phone FROM Sales.Customers"
Write-Host "Query: $query" -ForegroundColor Gray
$result = Invoke-DbaQuery -SqlInstance 'localhost' -Database 'Northwind_Staging' -Query $query
$result | Format-Table
