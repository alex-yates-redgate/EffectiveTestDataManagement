# Effective Test Data Management

**Demo repo for Data Ceili 2026** — *"Effective Test Data Management, in an era of AI and DevOps"*

This repo demonstrates how to manage sensitive data in DevOps workflows using free/open source tools:
- **Flyway Community** for database migrations
- **dbatools** for data masking
- **SQL Server Data Classification** for identifying sensitive columns
- **Azure DevOps** for CI/CD pipelines

## Quick Start

### Prerequisites
- Windows machine with PowerShell 5.1+
- SQL Server instance (localhost or specify your instance)
- Git

### Setup

```powershell
# Clone the repo
git clone https://github.com/alex-yates-redgate/EffectiveTestDataManagement.git
cd EffectiveTestDataManagement

# Run the setup script (installs prerequisites, creates databases)
.\Setup-Demo.ps1
```

This will:
1. Install Flyway Community (if not already installed)
2. Install dbatools PowerShell module (if not already installed)
3. Create three Northwind databases: `Northwind_Dev`, `Northwind_Test`, `Northwind_Prod`
4. Apply initial data classifications to sensitive columns

## Demo Flow

### Session 1: Free/Open Source Approach

1. **Vibe-code a migration** — Use AI to generate a SQL migration script
2. **Run CI/CD pipeline** — Flyway builds from scratch, validates all columns are classified
3. **Review classifications** — Use SSMS to review/update `sys.sensitivity_classifications`
4. **Deploy to production** — Pipeline promotes validated changes
5. **Refresh dev/test data** — Mask production data on the way down using dbatools

## Repo Structure

```
├── Setup-Demo.ps1                    # Main setup script
├── flyway.toml                       # Flyway Community configuration
├── migrations/                       # Flyway migration scripts
│   └── V001__Baseline.sql
├── scripts/
│   ├── Install-Prerequisites.ps1     # Install Flyway & dbatools
│   ├── Create-Databases.ps1          # Create Northwind databases
│   ├── Validate-Classifications.ps1  # CI check: all sensitive columns classified
│   ├── Compare-ClassificationToMasking.ps1  # Cross-reference check
│   └── Invoke-DataMasking.ps1        # Run dbatools masking
├── database/
│   ├── Northwind-Schema.sql          # Database schema
│   └── Northwind-Data.sql            # Sample production data
├── masking/
│   └── masking-config.json           # dbatools masking configuration
└── AzureDevOps/
    ├── flyway-cicd-pipeline.yml      # Build → Validate → Deploy
    └── data-refresh-pipeline.yml     # Prod → Mask → Dev/Test
```

## Azure DevOps Setup

When you import this repo into Azure DevOps on your demo VM:

1. Create a new project and import from GitHub
2. Create the pipelines from the YAML files in `/AzureDevOps/`
3. Create variable groups: `NorthwindGlobal`, `NorthwindBuild`, `NorthwindTest`, `NorthwindProd`

See [AzureDevOps/README.md](AzureDevOps/README.md) for detailed setup instructions.

## Key Scripts

### Classification Validation
The CI pipeline runs `Validate-Classifications.ps1` which:
- Queries `sys.sensitivity_classifications` for all classified columns
- Compares against a list of expected sensitive columns
- Fails the build if any expected columns are not classified

### Masking Cross-Reference
`Compare-ClassificationToMasking.ps1` ensures your dbatools masking config covers all classified columns:
- Reads SQL Server classifications
- Reads dbatools masking JSON
- Reports any gaps (classified but not masked)

## License

MIT — See [LICENSE](LICENSE)
