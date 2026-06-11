# Classification & Masking Workflow

## Overview

This demo implements a **unified approach** to data classification and masking where:

1. **Classifications are part of the database schema** (Flyway migrations)
2. **All columns are explicitly tagged** (sensitive columns marked with classification labels, non-sensitive columns also tagged)
3. **Validation gates ensure consistency** (two critical checks to prevent data governance gaps)

## The Three-Part System

### Part 1: Flyway Migrations for Classifications

**File:** `/migrations/V002__Add_Sensitivity_Classifications.sql`

All columns in the core tables are classified using SQL Server's native `ADD SENSITIVITY CLASSIFICATION` syntax:

**Sensitive columns** get:
- **Label:** `Confidential - GDPR` or `Highly Confidential`
- **Information Type:** `Name`, `Address`, `Contact Info`, `Date Of Birth`, or `National ID`
- Standard Microsoft GUIDs for interoperability

**Non-sensitive columns** get:
- **Label:** `Not Sensitive`
- **Information Type:** `Non-Sensitive`
- Explicit tagging ensures any new column added without classification will be caught

**Tables covered:**
- `Sales.Customers` (8 columns: 5 PII + 3 non-PII)
- `HR.Employees` (18 columns: 8 PII + 10 non-PII)
- `Inventory.Suppliers` (8 columns: 4 PII + 4 non-PII)
- `Sales.Orders` (12 columns: 3 PII shipping fields + 9 non-PII)

### Part 2: dbatools Masking Configuration

**File:** `/masking/masking-config.json`

JSON configuration that defines how each sensitive column should be masked:

```json
{
  "Schema": "Sales",
  "Name": "Customers",
  "Columns": [
    {
      "Name": "ContactName",
      "MaskingType": "Name",
      "SubType": "FullName"
    },
    ...
  ]
}
```

**Coverage:** 25 columns with masking rules
- Must cover all columns classified as `Confidential - GDPR` or `Highly Confidential`
- Non-sensitive columns should NOT have masking rules

### Part 3: Dual-Test Validation

**File:** `/scripts/Validate-Classifications.ps1`

Runs **two critical tests** during the CI/CD Build stage:

#### TEST 1: Unclassified Columns
```
Query all columns in [Sales], [HR], [Inventory], [Shipping] schemas
Find any column missing a classification
FAIL if: Any column is unclassified
CATCH: New columns added without proper tagging
```

**Why this matters:** Developers often add new columns and forget to classify them. This catches that immediately during build validation.

#### TEST 2: Classified Columns Without Masking Rules
```
For each classified column with label NOT 'Not Sensitive':
  Check if it has a masking rule in masking-config.json
FAIL if: Sensitive column classified but no masking rule
CATCH: Incomplete masking configuration
```

**Why this matters:** Data classification without masking is incomplete. This ensures your masking tool knows about every sensitive column.

## CI/CD Pipeline Integration

**File:** `/AzureDevOps/flyway-cicd-pipeline.yml`

Build Stage Flow:

1. **Verify Flyway** - Ensures Flyway is in PATH
2. **Create Build Database** - Fresh DB created via dbatools
3. **Flyway Migrate (Build)** - Runs all migrations including V002__Add_Sensitivity_Classifications.sql
4. **Validate Classifications & Masking** - Runs both validation tests
   - Passes only if: All columns classified AND all sensitive columns have masking rules
   - Fails if: Unclassified columns found OR classified columns missing masking rules
5. **Publish Artifacts** - Copy migrations/config/scripts for Test/Prod stages

## Success Scenario

When the Build stage succeeds:

✅ All columns are explicitly classified  
✅ Sensitive columns are properly tagged  
✅ Non-sensitive columns explicitly marked as non-sensitive  
✅ All sensitive columns have corresponding masking rules  
✅ Masking tool is ready for data refresh pipeline  

**Your data governance is complete and validated.**

## Failure Scenarios

### Scenario A: Unclassified Column Found

```
[FAIL] Found 1 unclassified columns:
       - Sales.Customers.CustomerRating
```

**Cause:** Developer added new column without classification

**Fix:** 
1. Add classification to V002 (or new migration)
2. Commit and re-queue build

### Scenario B: Classified But Unmasked Column

```
[FAIL] Found 1 classified but unmasked columns:
       - HR.Employees.EmergencyContact [Confidential - GDPR]
```

**Cause:** Developer classified new column but forgot masking rule

**Fix:**
1. Add column to masking-config.json with appropriate MaskingType
2. Commit and re-queue build

### Scenario C: Both Issues

Build fails with clearer diagnostics showing exactly what needs to be fixed.

## New Column Workflow

When adding a **new PII column** (e.g., `SocialSecurityNumber`):

1. Add column to schema migration (V001, V003, etc.)
2. Add classification to V002 (or new migration):
   ```sql
   ADD SENSITIVITY CLASSIFICATION TO [HR].[Employees].[SocialSecurityNumber] 
   WITH (LABEL = 'Highly Confidential', ..., INFORMATION_TYPE = 'National ID', ...)
   ```
3. Add masking rule to masking-config.json:
   ```json
   {
     "Name": "SocialSecurityNumber",
     "MaskingType": "RandomString",
     "Format": "###-##-####"
   }
   ```
4. Run build - Validation tests confirm both are in place

If you skip step 2 or 3 → Build fails with clear diagnostic message.

## Key Benefits

| Aspect | Without This | With This |
|--------|-------------|----------|
| New unclassified columns | Silently make it to production | Caught at build validation |
| Classification without masking | Incomplete data protection | Caught at build validation |
| Masking rule coverage | Manual verification needed | Automatically verified |
| Audit trail | Spreadsheet or manual notes | Part of version-controlled migrations |
| New team member onboarding | "Don't forget to..." | Automated checks enforce policy |

## Technical Details

**SQL Server Classifications:**
- Uses `sys.sensitivity_classifications` DMV
- Standard Microsoft Information Type GUIDs for interoperability
- Label field controls sensitivity level
- Native to SQL Server 2019+, Azure SQL

**Validation Query Pattern:**
```sql
-- Find all columns (sensitive or not)
SELECT ... FROM sys.columns ...

-- Find classified columns
SELECT ... FROM sys.sensitivity_classifications ...

-- Compare to find gaps
```

**Masking Configuration:**
- dbatools compatible JSON format
- Supports 8+ masking types (Name, Address, Email, Phone, SSN, Date, etc.)
- Column-level granularity for masking strategy
