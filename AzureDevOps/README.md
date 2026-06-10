# Azure DevOps Pipeline Setup

This folder contains two YAML pipelines for the Effective Test Data Management demo.

## Pipelines

### 1. `flyway-cicd-pipeline.yml` - Migration Deployment Pipeline

Deploys database changes through the environments:

```
Build → Test → Prod (with approval)
```

**Key features:**
- **Build stage**: Creates database from scratch, runs all migrations, validates classifications
- **Classification validation**: Fails build if any expected sensitive columns are not classified
- **Masking coverage check**: Verifies all classified columns have masking rules
- **Manual approval gate**: Before production deployment

### 2. `data-refresh-pipeline.yml` - Data Refresh Pipeline

Refreshes Dev/Test with masked production data:

```
Prod → Staging → Mask → Dev/Test
```

**Key features:**
- Backs up production database
- Restores to staging
- Applies dbatools masking
- Distributes masked data to Dev and Test
- Cleans up staging and old backups

## Setup Instructions

### 1. Import Repository

1. In Azure DevOps, create a new project (or use existing)
2. Go to **Repos** → **Import a repository**
3. Enter the GitHub URL: `https://github.com/alex-yates-redgate/EffectiveTestDataManagement`

### 2. Configure Agent Pool

Both pipelines use `name: Default` for the agent pool. Update this to match your self-hosted agent:

```yaml
pool:
  name: YourAgentPoolName  # Change this
```

### 3. Create Pipelines

1. Go to **Pipelines** → **New Pipeline**
2. Select **Azure Repos Git**
3. Select your repository
4. Choose **Existing Azure Pipelines YAML file**
5. Select `AzureDevOps/flyway-cicd-pipeline.yml`
6. Save (don't run yet)

Repeat for `data-refresh-pipeline.yml`.

### 4. Prerequisites on Agent

The agent machine needs:
- SQL Server instance (localhost or configured)
- Flyway CLI installed (run `Setup-Demo.ps1`)
- dbatools PowerShell module
- Permissions to create/drop databases

### 5. Run Initial Setup

Before running pipelines, execute on the agent:

```powershell
# Clone the repo
git clone https://github.com/alex-yates-redgate/EffectiveTestDataManagement.git
cd EffectiveTestDataManagement

# Run setup
.\Setup-Demo.ps1
```

This creates the initial databases with schema and classifications.

## Variable Reference

### Flyway CI/CD Pipeline

| Variable | Default | Description |
|----------|---------|-------------|
| `FLYWAY_INSTALL_DIRECTORY` | `C:\Flyway` | Path to Flyway CLI |

### Data Refresh Pipeline

| Variable | Default | Description |
|----------|---------|-------------|
| `SQL_INSTANCE` | `localhost` | SQL Server instance |
| `SOURCE_DATABASE` | `Northwind_Prod` | Production database |
| `STAGING_DATABASE` | `Northwind_Staging` | Temp staging database |
| `DEV_DATABASE` | `Northwind_Dev` | Development database |
| `TEST_DATABASE` | `Northwind_Test` | Test database |
| `BACKUP_PATH` | `C:\temp\northwind_backups` | Backup file location |

## Demo Workflow

### Session 1 Demo Flow

1. **Show the classification validation** - Run CI/CD pipeline, show it checking classifications
2. **Add a new column via AI** - Ask Claude to generate a migration that adds a sensitive column
3. **Pipeline fails** - Because the new column isn't classified
4. **Fix by adding classification** - Update `Apply-Classifications.ps1` or use SSMS
5. **Pipeline passes** - All columns now classified
6. **Refresh dev/test data** - Run data refresh pipeline
7. **Show masked data** - Query dev database, PII is masked

### Triggering Pipelines

- **CI/CD Pipeline**: Triggers on changes to `migrations/*` folder, or run manually
- **Data Refresh Pipeline**: Manual trigger only (or weekly schedule)
