# Apply-Classifications.ps1
# ===========================
# Applies SQL Server Data Discovery & Classification labels to sensitive columns
# These classifications are the "source of truth" for what needs masking
# ===========================

param (
    [string]$SqlInstance = "localhost",
    [string]$Database = "Northwind_Prod"
)

$ErrorActionPreference = "Stop"

Write-Host "Applying data classifications to $Database..." -ForegroundColor Cyan

Import-Module dbatools -Force

# ============================================
# Define sensitive columns and their classifications
# Information Types: https://docs.microsoft.com/en-us/sql/relational-databases/security/sql-data-discovery-and-classification
# ============================================
$sensitiveColumns = @(
    # Customers table - PII
    @{ Schema = "Sales"; Table = "Customers"; Column = "ContactName";   InfoType = "Name";           Sensitivity = "Confidential - GDPR" },
    @{ Schema = "Sales"; Table = "Customers"; Column = "Address";       InfoType = "Address";        Sensitivity = "Confidential - GDPR" },
    @{ Schema = "Sales"; Table = "Customers"; Column = "PostalCode";    InfoType = "Address";        Sensitivity = "Confidential - GDPR" },
    @{ Schema = "Sales"; Table = "Customers"; Column = "Phone";         InfoType = "Contact Info";   Sensitivity = "Confidential - GDPR" },
    @{ Schema = "Sales"; Table = "Customers"; Column = "Fax";           InfoType = "Contact Info";   Sensitivity = "Confidential - GDPR" },
    @{ Schema = "Sales"; Table = "Customers"; Column = "Email";         InfoType = "Contact Info";   Sensitivity = "Confidential - GDPR" },
    
    # Employees table - PII including highly sensitive SSN
    @{ Schema = "HR"; Table = "Employees"; Column = "FirstName";   InfoType = "Name";               Sensitivity = "Confidential - GDPR" },
    @{ Schema = "HR"; Table = "Employees"; Column = "LastName";    InfoType = "Name";               Sensitivity = "Confidential - GDPR" },
    @{ Schema = "HR"; Table = "Employees"; Column = "BirthDate";   InfoType = "Date Of Birth";      Sensitivity = "Confidential - GDPR" },
    @{ Schema = "HR"; Table = "Employees"; Column = "Address";     InfoType = "Address";            Sensitivity = "Confidential - GDPR" },
    @{ Schema = "HR"; Table = "Employees"; Column = "PostalCode";  InfoType = "Address";            Sensitivity = "Confidential - GDPR" },
    @{ Schema = "HR"; Table = "Employees"; Column = "HomePhone";   InfoType = "Contact Info";       Sensitivity = "Confidential - GDPR" },
    @{ Schema = "HR"; Table = "Employees"; Column = "Email";       InfoType = "Contact Info";       Sensitivity = "Confidential - GDPR" },
    @{ Schema = "HR"; Table = "Employees"; Column = "SSN";         InfoType = "National ID";        Sensitivity = "Highly Confidential" },
    
    # Suppliers table - PII
    @{ Schema = "Inventory"; Table = "Suppliers"; Column = "ContactName"; InfoType = "Name";        Sensitivity = "Confidential - GDPR" },
    @{ Schema = "Inventory"; Table = "Suppliers"; Column = "Address";     InfoType = "Address";     Sensitivity = "Confidential - GDPR" },
    @{ Schema = "Inventory"; Table = "Suppliers"; Column = "PostalCode";  InfoType = "Address";     Sensitivity = "Confidential - GDPR" },
    @{ Schema = "Inventory"; Table = "Suppliers"; Column = "Phone";       InfoType = "Contact Info"; Sensitivity = "Confidential - GDPR" },
    @{ Schema = "Inventory"; Table = "Suppliers"; Column = "Fax";         InfoType = "Contact Info"; Sensitivity = "Confidential - GDPR" },
    
    # Orders table - Shipping PII
    @{ Schema = "Sales"; Table = "Orders"; Column = "ShipName";       InfoType = "Name";    Sensitivity = "Confidential - GDPR" },
    @{ Schema = "Sales"; Table = "Orders"; Column = "ShipAddress";    InfoType = "Address"; Sensitivity = "Confidential - GDPR" },
    @{ Schema = "Sales"; Table = "Orders"; Column = "ShipPostalCode"; InfoType = "Address"; Sensitivity = "Confidential - GDPR" }
)

# ============================================
# Information Type and Sensitivity Label IDs
# These are the standard Microsoft-defined GUIDs
# ============================================
$infoTypeIds = @{
    "Name"           = "57845286-7598-22f5-9659-15b24aeb125e"
    "Address"        = "C13F7B9A-B516-4F9A-8C34-6D1FB3BDA977"
    "Contact Info"   = "5C503E21-22C6-81FA-620B-F369B8EC38D1"
    "Date Of Birth"  = "3DE7CC52-710D-4E32-B5F3-D7F0C2B15B99"
    "National ID"    = "6F5A11A7-08B1-19C0-05F2-DC6BA7E1A6AC"
    "Financial"      = "C64ABA7B-3A3E-95B6-535D-3BC535DA5A59"
}

$sensitivityIds = @{
    "Confidential - GDPR"  = "989ADC05-3F3F-0588-A635-F475B994915B"
    "Highly Confidential"  = "3302AE7F-B8AC-46BC-97F8-378828781EFD"
    "Public"               = "1866CA45-1973-4C28-9D12-04D407F147AD"
    "General"              = "684A0DB2-D514-49D8-8C0C-DF84A7B083EB"
}

Write-Host "  Applying classifications to $($sensitiveColumns.Count) columns..." -ForegroundColor White

foreach ($col in $sensitiveColumns) {
    $infoTypeId = $infoTypeIds[$col.InfoType]
    $sensitivityId = $sensitivityIds[$col.Sensitivity]
    
    $sql = @"
IF NOT EXISTS (
    SELECT 1 FROM sys.sensitivity_classifications 
    WHERE major_id = OBJECT_ID('$($col.Schema).$($col.Table)') 
    AND minor_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('$($col.Schema).$($col.Table)') AND name = '$($col.Column)')
)
BEGIN
    ADD SENSITIVITY CLASSIFICATION TO [$($col.Schema)].[$($col.Table)].[$($col.Column)]
    WITH (
        LABEL = '$($col.Sensitivity)',
        LABEL_ID = '$sensitivityId',
        INFORMATION_TYPE = '$($col.InfoType)',
        INFORMATION_TYPE_ID = '$infoTypeId'
    )
END
"@
    
    try {
        Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $sql -EnableException
        Write-Host "    [OK] $($col.Schema).$($col.Table).$($col.Column)" -ForegroundColor Green
    }
    catch {
        Write-Host "    [WARN] $($col.Schema).$($col.Table).$($col.Column): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Classifications applied!" -ForegroundColor Green
Write-Host ""
Write-Host "To review in SSMS: Right-click database > Tasks > Data Discovery and Classification > View Report" -ForegroundColor Cyan
