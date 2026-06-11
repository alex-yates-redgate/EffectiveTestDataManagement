# Bogus Faker Library Setup for dbatools Masking

## ⚠️ CRITICAL REQUIREMENT

**dbatools masking REQUIRES Administrator privileges to set up.**

The Bogus faker library must be installed to:
```
C:\Program Files\WindowsPowerShell\Modules\dbatools\<version>\library\Bogus.dll
```

This is a **system-protected folder** that requires admin access.

## Problem Without Bogus

Without Bogus installed, masking runs but produces empty values:

```
UPDATE [Sales].[Customers] SET [ContactName] = ISNULL(, '')  -- Empty value!
```

This happens even when:
- Masking config validates successfully ✓
- dbatools completes without errors ✓
- Test-DbaDbDataMaskingConfig passes ✓

The issue only appears at runtime when dbatools tries to generate faker data.

## Setup Instructions

### Step 1: Run Admin Setup Script (One-Time)

On your build agent or local machine, run PowerShell **as Administrator**:

```powershell
# Right-click PowerShell → Run as administrator
cd c:\git\EffectiveTestDataManagement\scripts
.\AdminSetup-Bogus.ps1
```

**Output should show:**
```
[SUCCESS] Bogus installed successfully!
Name         Size(KB)
----         --------
Bogus.dll    1234.56

dbatools masking is now ready for production use.
```

### Step 2: Verify Installation

```powershell
ls "C:\Program Files\WindowsPowerShell\Modules\dbatools\2.1.18\library\" | ls Bogus.dll
```

Should return the Bogus.dll file.

### Step 3: Restart Services

After installation:
- Close and reopen PowerShell
- Restart the Azure DevOps agent (if using self-hosted)

### Step 4: Run Masking Pipeline

Masking will now generate real faker data like:
```
CustomerID  ContactName              Phone
-----------  -----------------------  ----------------
ALFKI        Dr. Ulises Cronin       (123) 456-7890
ANATR        Ms. Ava Breitling       (987) 654-3210
```

## Test the Installation

After restarting PowerShell, verify masking works:

```powershell
cd c:\git\EffectiveTestDataManagement\scripts
.\Test-Masking.ps1
```

**Success looks like:**
```
Testing masking config validation...
Validation passed!

Invoking masking with verbose output...
[SUCCESS] Masking completed!

Checking masked data...
CustomerID  ContactName              Phone           Email
-----------  -----------------------  ---------------  -------------------------
ALFKI        Dr. Ulises Cronin       (123) 456-7890   ava.gibson@example.com
ANATR        Ms. Ava Breitling       (987) 654-3210   mason.smith@example.com
```

**NOT like:**
```
[WARNING] Failure | The system cannot find the file specified
UPDATE [Sales].[Customers] SET [ContactName] = ISNULL(, '')  -- Empty!
```

## Fail-Safe Design (If Bogus Not Available)

Even without Bogus, the pipeline is designed safely:

| Stage | Outcome |
|-------|---------|
| Masking runs | ✓ No errors |
| Generates UPDATE statements | ✗ Empty values |
| Sentinel check validates data | ✓ Detects unmasked |
| Restore to Dev/Test blocked | ✓ Prevents data leak |

This ensures **zero risk of unmasked production data** reaching development environments.

## Azure DevOps Pipeline Integration

To include the setup in your CI/CD pipeline, edit `AzureDevOps/data-refresh-pipeline.yml`:

```yaml
jobs:
  - job: SetupBogus
    displayName: Setup Bogus Faker Library
    pool:
      name: Default  # Your self-hosted agent pool
    steps:
      - checkout: self
      - task: PowerShell@2
        displayName: Install Bogus (Admin)
        inputs:
          targetType: 'filePath'
          filePath: 'scripts/AdminSetup-Bogus.ps1'
          pwshModule: true

  - job: CreateStaging
    displayName: Create Staging Database
    dependsOn: SetupBogus
    # ... rest of data refresh jobs
```

**Note:** Self-hosted agents can run with admin context using agent configuration. Contact your DevOps team if this isn't available.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Access to the path denied" | Run PowerShell as Administrator |
| Script blocked by execution policy | `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| "Bogus.dll not found" after install | Restart PowerShell and pipeline agent |
| Masking still shows empty values | Verify: `ls C:\Program Files\WindowsPowerShell\Modules\dbatools\2.1.18\library\Bogus.dll` |
| dbatools version mismatch | Check dbatools version: `Get-Module dbatools -ListAvailable` |

## Scripts

- **AdminSetup-Bogus.ps1** - Main setup (run as admin once)
- **Install-BogusLibrary.ps1** - Alternative user-level install (won't help for dbatools)
- **Install-BogusLibrary-Admin.ps1** - Legacy admin installer
- **Test-Masking.ps1** - Verify masking produces real faker data
- **Invoke-DataMasking.ps1** - Main masking script (called by pipeline)

## Related Documentation

- [dbatools Data Masking](https://docs.dbatools.io/#Invoke-DbaDbDataMasking)
- [Bogus Faker Library](https://github.com/bchavez/Bogus)
- See `PIPELINE.md` for complete data-refresh-pipeline flow
