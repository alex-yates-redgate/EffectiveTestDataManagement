# Bogus Faker Library Setup for dbatools Masking

## Problem

dbatools masking requires the **Bogus** NuGet package (faker library) to generate randomized masked values.  Without Bogus, masking runs but produces empty values:

```
UPDATE [Sales].[Customers] SET [ContactName] = ISNULL(, '')  -- Empty value!
```

This happens even when masking config is valid and dbatools completes successfully.

## Root Cause

The Bogus library must be installed in dbatools' library folder:
- **Required path**: `C:\Program Files\WindowsPowerShell\Modules\dbatools\<version>\library\`
- **Issue**: This path requires **Administrator privileges** to write to

## Solution

### Option 1: Install as Administrator (Recommended)

1. **One-time setup** on the build agent:
   ```powershell
   # Run as Administrator
   .\scripts\Install-BogusLibrary-Admin.ps1
   ```

2. **Verify installation**:
   ```powershell
   ls "C:\Program Files\WindowsPowerShell\Modules\dbatools\library\"
   ```
   Should show `Bogus.dll`

3. **Masking will now work** with faker data generation

### Option 2: Configure Pipeline to Run Setup Step as Admin

Edit `AzureDevOps/data-refresh-pipeline.yml`:

```yaml
jobs:
  - job: SetupBogus
    displayName: Setup Bogus Faker Library
    pool:
      name: Default  # Or your self-hosted pool
    steps:
      - task: PowerShell@2
        displayName: Install Bogus
        inputs:
          targetType: 'filePath'
          filePath: 'scripts/Install-BogusLibrary-Admin.ps1'
          pwshModule: true
        condition: succeeded()

  - job: CreateStaging
    displayName: Create Staging DB
    dependsOn: SetupBogus
    # ... rest of pipeline
```

### Option 3: Pre-configure on Build Agent

If using a self-hosted agent:

1. Install Bogus once manually with admin privileges
2. Add to agent startup script to verify it's present

## Verification

After installation, run the test:

```powershell
cd scripts
pwsh -File Test-Masking.ps1
```

Check output - should show masked data like:
```
CustomerID  ContactName        Phone       
-----------  ---------------    -----------
ALFKI        Dr. Ulises Cronin  (123) 456-7890
```

NOT empty values with ISNULL errors.

## Temporary Workaround

If Bogus setup is delayed, the masking pipeline will:
1. Run without errors ✓
2. Generate empty UPDATE statements ✗
3. Fail sentinel check (detects unmasked data) ✓
4. Block restore to Dev/Test ✓

This is **fail-safe design** - prevents unmasked data leaks even if faker library isn't available.

## Troubleshooting

**Error: "Access to the path denied"**
- Install script must run with Administrator privileges
- Use `Run as administrator` option for PowerShell

**Error: "Bogus.dll not found after installation"**
- Verify path: `C:\Program Files\WindowsPowerShell\Modules\dbatools\<version>\library\Bogus.dll`
- dbatools version must match the path (e.g., `2.1.18`)

**Masking still produces empty values**
- Try restarting PowerShell or the pipeline agent
- Clear PowerShell module cache: `Remove-Module dbatools -Force`

## Related Files

- `scripts/Install-BogusLibrary.ps1` - User-level install (no admin needed)
- `scripts/Install-BogusLibrary-Admin.ps1` - System-level install (admin required)
- `scripts/Test-Masking.ps1` - Verify masking works
- `scripts/Invoke-DataMasking.ps1` - Main masking script (used in pipeline)
