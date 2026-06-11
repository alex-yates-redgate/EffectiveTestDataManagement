# Check Bogus dependencies
Import-Module dbatools

$bogusUrl = 'https://globalcdn.nuget.org/packages/bogus.35.5.1.nupkg'
$bogusZip = Join-Path $env:TEMP 'bogus-check.nupkg'
$bogusExtractPath = Join-Path $env:TEMP 'bogus-check'

Write-Host 'Downloading Bogus...' -ForegroundColor Cyan
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $bogusUrl -OutFile $bogusZip -ErrorAction Stop

Write-Host 'Extracting...' -ForegroundColor Cyan
if (Test-Path $bogusExtractPath) { Remove-Item $bogusExtractPath -Recurse -Force }
Expand-Archive -Path $bogusZip -DestinationPath $bogusExtractPath -Force

Write-Host ''
Write-Host 'Bogus DLLs in netstandard2.1:' -ForegroundColor Yellow
Get-ChildItem "$bogusExtractPath/lib/netstandard2.1" -Filter '*.dll' -ErrorAction SilentlyContinue | Select-Object Name

Write-Host ''
Write-Host 'Checking for other DLLs...' -ForegroundColor Yellow
Get-ChildItem $bogusExtractPath -Recurse -Filter '*.dll' | Select-Object FullName

# Cleanup
Remove-Item $bogusZip -Force -ErrorAction SilentlyContinue
