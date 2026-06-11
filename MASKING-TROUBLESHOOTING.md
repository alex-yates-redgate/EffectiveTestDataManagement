# Data Masking Implementation - Simple SQL Solution ✅

## Status: WORKING

The project now uses **simple SQL-based data masking** - a straightforward, reliable approach that replaces sensitive data with placeholder values. No external dependencies or complex configuration needed.

## Implementation

**Files:**
- `masking/Mask-Data-Simple.sql` - T-SQL UPDATE statements with placeholder values
- `scripts/Invoke-DataMasking.ps1` - Execute masking from pipeline
- `scripts/Invoke-SimpleMasking.ps1` - Standalone masking test script

**Verified working:**
```
Original: Maria Anders → Masked: Masked Customer
Original: 030-0074321 → Masked: (555) 555-5555
Original: maria@example.com → Masked: masked@example.com
```

## How It Works

1. **Mask-Data-Simple.sql** contains simple UPDATE statements:
```sql
UPDATE [Sales].[Customers] SET 
    [ContactName] = 'Masked Customer',
    [Phone] = '(555) 555-5555',
    [Email] = 'masked@example.com'
WHERE [ContactName] IS NOT NULL
```

2. **Invoke-DataMasking.ps1** executes the SQL:
```powershell
Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $maskingSql
```

3. **Result:** All sensitive columns masked safely for dev/test use
