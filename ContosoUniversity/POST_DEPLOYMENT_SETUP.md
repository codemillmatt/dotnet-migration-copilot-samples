# Post-Deployment Configuration for Contoso University

After deploying the Contoso University application to Azure, you need to configure the managed identity permissions for Azure SQL Database.

## Issue
The application uses Managed Identity to connect to Azure SQL Database, but the managed identity needs to be explicitly granted permissions in the database.

## Solution

### Option 1: Using PowerShell (Windows)
```powershell
# Set environment variables (get these from your deployment output)
$env:AZURE_SQL_SERVER = "your-sql-server-name"
$env:AZURE_SQL_DATABASE = "ContosoUniversity"
$env:AZURE_CONTAINER_APP_NAME = "your-container-app-name"

# Run the configuration script
.\scripts\configure-sql-managed-identity.ps1
```

### Option 2: Using Bash (Linux/macOS/WSL)
```bash
# Set environment variables (get these from your deployment output)
export AZURE_SQL_SERVER="your-sql-server-name"
export AZURE_SQL_DATABASE="ContosoUniversity"
export AZURE_CONTAINER_APP_NAME="your-container-app-name"

# Make script executable and run
chmod +x scripts/configure-sql-managed-identity.sh
./scripts/configure-sql-managed-identity.sh
```

### Option 3: Manual SQL Execution
If the scripts don't work, you can manually execute this SQL in Azure SQL Database as an Azure AD administrator:

```sql
-- Replace 'your-container-app-name' with your actual Container App name
DECLARE @IdentityName NVARCHAR(128) = 'your-container-app-name-identity';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @IdentityName)
BEGIN
    PRINT 'Creating user for managed identity: ' + @IdentityName;
    EXEC('CREATE USER [' + @IdentityName + '] FROM EXTERNAL PROVIDER');
    
    PRINT 'Assigning database roles...';
    EXEC('ALTER ROLE db_datareader ADD MEMBER [' + @IdentityName + ']');
    EXEC('ALTER ROLE db_datawriter ADD MEMBER [' + @IdentityName + ']');
    EXEC('ALTER ROLE db_ddladmin ADD MEMBER [' + @IdentityName + ']');
    
    PRINT 'Granting additional permissions...';
    EXEC('GRANT CREATE TABLE TO [' + @IdentityName + ']');
    EXEC('GRANT ALTER ON SCHEMA::dbo TO [' + @IdentityName + ']');
    
    PRINT 'Managed Identity user configured successfully';
END
ELSE
BEGIN
    PRINT 'Managed Identity user already exists: ' + @IdentityName;
END
```

## Getting Your Values

After deployment, get these values from the AZD output or Azure portal:

```bash
# Get deployment outputs
azd env get-values

# Or use Azure CLI
az containerapp list --query "[].{name:name,identity:identity.userAssignedIdentities}" -o table
az sql server list --query "[].{name:name,fullyQualifiedDomainName:fullyQualifiedDomainName}" -o table
```

## Verification

After configuring the managed identity, you should be able to:
1. Access the application without managed identity errors
2. View students and courses pages
3. Perform CRUD operations
4. See database operations in the application logs

## Troubleshooting

If you're still getting managed identity errors:

1. **Check the managed identity exists:**
   ```bash
   az identity list --query "[?contains(name, 'your-container-app-name')]"
   ```

2. **Verify the SQL user was created:**
   ```sql
   SELECT name, type_desc, authentication_type_desc 
   FROM sys.database_principals 
   WHERE name LIKE '%your-container-app-name%';
   ```

3. **Check application logs:**
   ```bash
   azd monitor --logs
   ```

4. **Test database connectivity:**
   Navigate to `https://your-app-url/health` to see the health check status.