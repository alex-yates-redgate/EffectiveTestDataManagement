# Quick Start: Running the Build Pipeline

## One-Minute Overview

Your demo now shows:

1. **Flyway creates schema** with V001 (tables)
2. **Flyway applies classifications** with V002 (SQL Server tags all columns as sensitive/non-sensitive)
3. **Validation gates check TWO things:**
   - ✓ All columns classified (catches new untagged columns)
   - ✓ All sensitive columns have masking rules (catches incomplete masking)

## Queue the Next Build

In Azure DevOps:

1. Go to **Pipelines** → **flyway-cicd-pipeline**
2. Click **Run Pipeline**
3. Wait for **Build stage** to complete

## Expected Results

### Success ✅
```
Build stage:
  ✓ Verify Flyway Installation
  ✓ Create Build Database
  ✓ Flyway Migrate (includes V002 classifications)
  ✓ Validate Classifications & Masking
    - [PASS] All 46 columns are classified!
    - [PASS] All 25 sensitive columns have masking rules!
    [SUCCESS] All validation tests passed!

  Next: Proceed to Test stage (manual approval)
```

### Failure Cases

**Scenario A: Unclassified Column**
```
  ✗ Validate Classifications & Masking
    [FAIL] Found 1 unclassified columns:
           - Sales.Customers.NewColumn

Fix: Add to migrations/V002 or create V003 migration
```

**Scenario B: No Masking Rule**
```
  ✗ Validate Classifications & Masking
    [FAIL] Found 1 classified but unmasked columns:
           - HR.Employees.EmergencyContact [Confidential - GDPR]

Fix: Add to masking/masking-config.json
```

## For Demo Day

### The Story

"Here's how we implement modern data governance with Flyway and dbatools:

1. **All columns are classified as code** - Part of version control
2. **Non-sensitive columns explicitly tagged** - No silent defaults
3. **Build gates enforce policy** - Catches developer mistakes:
   - 'I added a column but forgot to classify it' → Build fails
   - 'I classified the column but forgot the masking rule' → Build fails

This ensures sensitive data is always properly tagged AND properly protected."

### Show Them

1. **Open migrations/V002:** Show 46 ADD SENSITIVITY classifications
   - Point out mix of sensitive (Name, Address, SSN) and non-sensitive
   - Explain the Microsoft GUIDs for interoperability

2. **Open scripts/Validate-Classifications.ps1:** Show the two tests
   - TEST 1: "Did someone add a column without classifying it?"
   - TEST 2: "Is every sensitive column actually masked?"

3. **Queue build:** Watch validation pass
   - All 46 columns classified ✓
   - All 25 sensitive columns have masking ✓

4. **Optional: Break it on purpose**
   - Add new column to schema but NOT to V002
   - Queue build → See TEST 1 fail with clear diagnostic
   - Remove masking rule from config
   - Queue build → See TEST 2 fail with clear diagnostic

## Key Files for Demo

| File | Purpose |
|------|---------|
| `migrations/V002__Add_Sensitivity_Classifications.sql` | All 46 classifications |
| `scripts/Validate-Classifications.ps1` | Two-test validation logic |
| `masking/masking-config.json` | 25 sensitive column masking rules |
| `AzureDevOps/flyway-cicd-pipeline.yml` | Build pipeline with V002 + validation |

## Demo Talking Points

✅ **Infrastructure as Code:** Classifications are versioned migrations, not manual scripts  
✅ **Explicit is Better:** Even "not sensitive" columns are tagged  
✅ **Fail-Fast:** Build fails if governance violated  
✅ **Developer-Friendly:** Clear diagnostic messages tell exactly what's wrong  
✅ **Auditable:** Every classification change in git history  
✅ **Scalable:** Same pattern works for 50 or 5,000 columns  

## Questions You'll Get

**Q: Why mark non-sensitive columns?**
A: "If I only mark sensitive columns, adding a new column means 'by default it's non-sensitive until I remember to classify it.' With explicit marking, any new column triggers build failure until it's classified. Developer mistake turned into build failure = policy enforcement."

**Q: Doesn't this add overhead?**
A: "46 classifications + 25 masking rules is a one-time investment per table. After that, the build validation ensures anything new is caught. Compare to the cost of a data breach or compliance violation."

**Q: How does this scale?**
A: "Same approach works for 50 tables, 500 tables. The validation is dynamic - it finds any unclassified column in any table, any sensitive column without a masking rule. No maintenance to the validation script."

---

**You're ready to demo! 🎯**
