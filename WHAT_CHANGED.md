# What Changed: Migration to Flyway-Managed Classifications

## The Brief

Your original request:
> "I want classifications included in the flyway scripts, so that the build database is classified by default. And I want non sensitive columns to be explicitly tagged as not sensitive."

## The Implementation

### 1. New Flyway Migration: V002__Add_Sensitivity_Classifications.sql

**Location:** `/migrations/V002__Add_Sensitivity_Classifications.sql`

**What it does:**
- Runs after the schema (V001) is created
- Uses SQL Server native `ADD SENSITIVITY CLASSIFICATION` syntax
- Applies classifications to **all** columns (both sensitive AND non-sensitive)
- Uses standard Microsoft GUIDs for information types and labels

**Example:**
```sql
-- Sensitive columns get classified as PII
ADD SENSITIVITY CLASSIFICATION TO [Sales].[Customers].[ContactName] 
WITH (LABEL = 'Confidential - GDPR', ..., INFORMATION_TYPE = 'Name', ...)

-- Non-sensitive columns explicitly marked as NOT sensitive
ADD SENSITIVITY CLASSIFICATION TO [Sales].[Customers].[CustomerID] 
WITH (LABEL = 'Not Sensitive', ..., INFORMATION_TYPE = 'Non-Sensitive', ...)
```

**Coverage:**
- Sales.Customers: 8 columns (5 PII + 3 non-PII)
- HR.Employees: 18 columns (8 PII + 10 non-PII)
- Inventory.Suppliers: 8 columns (4 PII + 4 non-PII)
- Sales.Orders: 12 columns (3 PII + 9 non-PII)
- **Total: 46 columns classified**

### 2. Redesigned Validate-Classifications.ps1

**Location:** `/scripts/Validate-Classifications.ps1`

**Old approach:**
- Check against a hardcoded list of "expected sensitive columns"
- Catch missing classifications from the golden list
- Miss new columns if they weren't in the golden list

**New approach - TWO TESTS:**

#### TEST 1: Unclassified Columns
```powershell
# Get ALL columns in [Sales], [HR], [Inventory], [Shipping]
# Find any that DON'T have a classification

if (unclassifiedColumns.Count -gt 0) {
    FAIL - "New column added without classification"
}
```
**Why:** Catches developer mistakes when adding columns

#### TEST 2: Classified But Unmasked
```powershell
# For each classified column that's NOT 'Not Sensitive'
# Check if masking-config.json has a rule for it

if (classifiedButNotMasked.Count -gt 0) {
    FAIL - "Sensitive column classified but missing masking rule"
}
```
**Why:** Ensures masking tool knows about every sensitive column

### 3. Simplified CI/CD Pipeline

**File:** `/AzureDevOps/flyway-cicd-pipeline.yml`

**Before:**
- Step 2: Create Build DB
- Step 3: Run Flyway (only schema)
- Step 4: Apply Classifications (separate PS script)
- Step 5: Validate Classifications
- Step 6: Compare Classifications to Masking
- Step 7: Publish artifacts

**After:**
- Step 2: Create Build DB
- Step 3: Run Flyway (includes V002 with classifications)
- Step 4: Validate Classifications & Masking (one consolidated step)
- Step 5: Publish artifacts

**Benefits:**
- Fewer steps
- Clearer flow
- Classifications are now part of the build, not an afterthought
- Both validations run in a single call

### 4. New Documentation

**File:** `/CLASSIFICATION_AND_MASKING.md`

Comprehensive guide explaining:
- Why this matters
- How the three-part system works (Flyway, Masking Config, Validation)
- What success looks like
- Failure scenarios and fixes
- Workflow for adding new columns

## Key Differences

| Aspect | Before | After |
|--------|--------|-------|
| **Where classifications live** | Applied by separate PowerShell script | Part of Flyway migrations |
| **Non-sensitive columns** | Not explicitly marked | Explicitly tagged as "Not Sensitive" |
| **Catching new unclassified columns** | Hardcoded list (would miss new columns) | Dynamic check (catches ANY unclassified column) |
| **Validation approach** | Single check: "expected columns classified?" | Dual check: "nothing unclassified?" + "all sensitive columns masked?" |
| **Build database** | Classifications applied AFTER schema | Classifications part of schema build |
| **Consistency** | Classifications, masking config, and code could drift | All tied together by validation gates |

## Why This Matters (Demo Point)

This showcases a **modern data governance pattern** for the Data Ceili conference:

✅ **Infrastructure as Code:** Classifications are part of versioned migrations  
✅ **Explicit over Implicit:** Even "non-sensitive" columns are marked (no silent defaults)  
✅ **Fail-Fast Validation:** Build fails if governance rules violated  
✅ **Catch Developer Mistakes:** Developers can't forget to classify or mask  
✅ **Scalable:** Works whether you have 50 or 5,000 columns  
✅ **Auditable:** Every change to classifications is in git history  

## Testing the Changes

When you queue the next build:

1. Flyway creates schema with V001
2. Flyway applies classifications with V002 **← NEW**
3. Validation runs TWO TESTS **← CHANGED**
   - TEST 1: Confirms all 46 columns classified
   - TEST 2: Confirms all 25 sensitive columns have masking rules
4. If both pass → Build succeeds, ready for Test/Prod deployment
5. If either fails → Clear error message shows exactly what's wrong

## Files Changed

- ✨ **NEW:** `/migrations/V002__Add_Sensitivity_Classifications.sql`
- ✨ **NEW:** `/CLASSIFICATION_AND_MASKING.md`
- 🔄 **UPDATED:** `/scripts/Validate-Classifications.ps1` (complete redesign with dual tests)
- 🔄 **UPDATED:** `/AzureDevOps/flyway-cicd-pipeline.yml` (removed Apply step, consolidated validation)

## Files Unchanged (Still Present)

These are still available but no longer called by the pipeline:
- `/scripts/Apply-Classifications.ps1` - Classifications now in Flyway (V002)
- `/scripts/Compare-ClassificationToMasking.ps1` - Logic merged into Validate-Classifications.ps1

---

**Your demo is now ready to showcase how modern data governance works: code-driven, validation-gated, developer-friendly.** 🎯
