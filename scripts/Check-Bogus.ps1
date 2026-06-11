Import-Module dbatools -Force

$dbatoolsPath = (Get-Module dbatools -ListAvailable | Select-Object -First 1).ModuleBase
Write-Host "dbatools module: $dbatoolsPath" -ForegroundColor Cyan

# Search for Bogus
$bogusFiles = Get-ChildItem $dbatoolsPath -Recurse -Filter 'Bogus*' -ErrorAction SilentlyContinue
if ($bogusFiles) {
    Write-Host "Found Bogus files:" -ForegroundColor Green
    $bogusFiles | Select-Object FullName
} else {
    Write-Host "Bogus library NOT FOUND in dbatools!" -ForegroundColor Red
    Write-Host ""
    Write-Host "dbatools masking requires Bogus faker library." -ForegroundColor Yellow
    Write-Host "This is a known issue with dbatools masking - the faker library isn't bundled." -ForegroundColor Yellow
}

# List library contents
$libPath = Join-Path $dbatoolsPath 'library'
Write-Host ""
Write-Host "Checking library folder: $libPath" -ForegroundColor Cyan
if (Test-Path $libPath) {
    $libs = Get-ChildItem $libPath | Select-Object Name
    Write-Host "Found $(($libs | Measure-Object).Count) items:"
    $libs
} else {
    Write-Host "Library folder not found" -ForegroundColor Yellow
}
