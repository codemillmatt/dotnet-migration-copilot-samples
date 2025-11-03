# Post-deployment script to configure Azure SQL Database for managed identity
# This script should be run after the infrastructure is deployed

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = $env:AZURE_RESOURCE_GROUP,
    
    [Parameter(Mandatory=$false)]
    [string]$SqlServerName = $env:AZURE_SQL_SERVER,
    
    [Parameter(Mandatory=$false)]
    [string]$DatabaseName = $env:AZURE_SQL_DATABASE,
    
    [Parameter(Mandatory=$false)]
    [string]$ContainerAppName = $env:AZURE_CONTAINER_APP_NAME
)

if (-not $ResourceGroupName) { $ResourceGroupName = "rg-28augmasoucou" }
if (-not $DatabaseName) { $DatabaseName = "ContosoUniversity" }
if (-not $ContainerAppName) { $ContainerAppName = "ca-c5nyxvpm7xvwu" }

Write-Host "Setting up Azure SQL Database managed identity permissions..." -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "SQL Server: $SqlServerName"
Write-Host "Database: $DatabaseName"
Write-Host "Container App: $ContainerAppName"

if (-not $SqlServerName) {
    Write-Error "SqlServerName is required. Set AZURE_SQL_SERVER environment variable or pass as parameter."
    exit 1
}

# Check if managed identity exists on the Container App
Write-Host "Checking managed identity configuration..." -ForegroundColor Yellow
$identity = az containerapp identity show --name $ContainerAppName --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json

if (-not $identity -or -not $identity.principalId) {
    Write-Host "No managed identity found. Creating system-assigned managed identity..." -ForegroundColor Yellow
    az containerapp identity assign --name $ContainerAppName --resource-group $ResourceGroupName --system-assigned
    Start-Sleep -Seconds 30  # Wait for identity to be fully provisioned
    $identity = az containerapp identity show --name $ContainerAppName --resource-group $ResourceGroupName | ConvertFrom-Json
}

if (-not $identity -or -not $identity.principalId) {
    Write-Error "Failed to create or retrieve managed identity for Container App: $ContainerAppName"
    exit 1
}

Write-Host "Managed Identity Principal ID: $($identity.principalId)" -ForegroundColor Green

# The managed identity name in SQL Database is the Container App name itself
$IdentityName = $ContainerAppName
Write-Host "SQL Database Identity Name: $IdentityName"

# Get current user for Azure AD authentication
$CurrentUser = az account show --query user.name -o tsv
Write-Host "Current user: $CurrentUser"

Write-Host "Executing SQL configuration..." -ForegroundColor Yellow

# Try using sqlcmd first (most reliable method)
try {
    # Test if sqlcmd is available and can authenticate
    $sqlcmdTest = sqlcmd -S "$SqlServerName.database.windows.net" -d $DatabaseName -G -Q "SELECT 1 as Test" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "? sqlcmd authentication successful. Using sqlcmd for script execution..." -ForegroundColor Green
        
        # Execute the SQL script using sqlcmd with Azure AD authentication
        $result = sqlcmd -S "$SqlServerName.database.windows.net" -d $DatabaseName -G -i "Scripts\setup-sql-user.sql"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "? SQL Database managed identity configuration completed successfully using sqlcmd" -ForegroundColor Green
            if ($result) {
                Write-Host "SQL Output:" -ForegroundColor Cyan
                Write-Host $result
            }
            
            # Offer restart option
            Write-Host ""
            Write-Host "=== CONFIGURATION SUCCESSFUL ===" -ForegroundColor Green
            Write-Host "? Managed identity user 'ca-c5nyxvpm7xvwu' has been configured" -ForegroundColor Green
            Write-Host "? All necessary database permissions have been granted" -ForegroundColor Green
            
            Write-Host ""
            Write-Host "=== NEXT STEPS ===" -ForegroundColor Yellow
            Write-Host "1. Restart your Container App to pick up the new managed identity configuration" -ForegroundColor White
            Write-Host "2. Monitor the application logs for any remaining authentication errors" -ForegroundColor White
            Write-Host "3. Test the application to ensure database connectivity works" -ForegroundColor White
            
            $restart = Read-Host "Do you want to restart the Container App now to apply changes? (y/N)"
            if ($restart -eq "y" -or $restart -eq "Y") {
                Write-Host "Restarting Container App..." -ForegroundColor Yellow
                az containerapp revision restart --name $ContainerAppName --resource-group $ResourceGroupName
                Write-Host "? Container App restart initiated" -ForegroundColor Green
                Write-Host "   Monitor logs: az containerapp logs show --name $ContainerAppName --resource-group $ResourceGroupName --follow" -ForegroundColor Cyan
            }
            
            exit 0
        } else {
            Write-Host "? sqlcmd execution failed" -ForegroundColor Red
        }
    } else {
        Write-Host "? sqlcmd authentication failed or not available" -ForegroundColor Red
    }
} catch {
    Write-Host "? sqlcmd not available or failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Since Azure CLI has compatibility issues, provide manual instructions
Write-Host ""
Write-Host "? Automated execution failed. Please run the SQL script manually." -ForegroundColor Red
Write-Host ""
Write-Host "=== MANUAL CONFIGURATION REQUIRED ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "Please connect to your Azure SQL Database as an Azure AD administrator and run the following SQL statements:" -ForegroundColor White
Write-Host ""

# Read and display the SQL script content
$sqlScript = Get-Content "Scripts\setup-sql-user.sql" -Raw
Write-Host "--- SQL SCRIPT START ---" -ForegroundColor Cyan
Write-Host $sqlScript -ForegroundColor White
Write-Host "--- SQL SCRIPT END ---" -ForegroundColor Cyan

Write-Host ""
Write-Host "=== CONNECTION OPTIONS ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1: Use Azure Data Studio" -ForegroundColor Green
Write-Host "1. Download Azure Data Studio: https://docs.microsoft.com/sql/azure-data-studio" -ForegroundColor White
Write-Host "2. Connect to server: $SqlServerName.database.windows.net" -ForegroundColor White
Write-Host "3. Database: $DatabaseName" -ForegroundColor White
Write-Host "4. Authentication: Azure Active Directory - Universal with MFA" -ForegroundColor White
Write-Host "5. Run the SQL script above" -ForegroundColor White
Write-Host ""

Write-Host "Option 2: Use SQL Server Management Studio (SSMS)" -ForegroundColor Green
Write-Host "1. Connect to server: $SqlServerName.database.windows.net" -ForegroundColor White
Write-Host "2. Database: $DatabaseName" -ForegroundColor White
Write-Host "3. Authentication: Azure Active Directory - Universal with MFA" -ForegroundColor White
Write-Host "4. Run the SQL script above" -ForegroundColor White
Write-Host ""

Write-Host "Option 3: Use sqlcmd directly (if available)" -ForegroundColor Green
Write-Host "Run this command:" -ForegroundColor White
Write-Host "sqlcmd -S $SqlServerName.database.windows.net -d $DatabaseName -G -i Scripts\setup-sql-user.sql" -ForegroundColor Cyan
Write-Host ""

Write-Host "Option 4: Use Azure Portal Query Editor" -ForegroundColor Green
Write-Host "1. Go to Azure Portal > SQL databases > $DatabaseName" -ForegroundColor White
Write-Host "2. Click 'Query editor (preview)'" -ForegroundColor White
Write-Host "3. Login with Azure AD" -ForegroundColor White
Write-Host "4. Paste and run the SQL script" -ForegroundColor White
Write-Host ""

Write-Host "=== VERIFICATION ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "After running the SQL script, verify the configuration with this query:" -ForegroundColor White
Write-Host ""
Write-Host "SELECT dp.name AS PrincipalName, dp.type_desc AS PrincipalType, r.name AS RoleName" -ForegroundColor Cyan
Write-Host "FROM sys.database_role_members rm" -ForegroundColor Cyan
Write-Host "JOIN sys.database_principals dp ON rm.member_principal_id = dp.principal_id" -ForegroundColor Cyan
Write-Host "JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id" -ForegroundColor Cyan
Write-Host "WHERE dp.name = 'ca-c5nyxvpm7xvwu'" -ForegroundColor Cyan
Write-Host "ORDER BY r.name;" -ForegroundColor Cyan
Write-Host ""

Write-Host "Expected results should show the user 'ca-c5nyxvpm7xvwu' with roles:" -ForegroundColor White
Write-Host "- db_datareader" -ForegroundColor Gray
Write-Host "- db_datawriter" -ForegroundColor Gray
Write-Host "- db_ddladmin" -ForegroundColor Gray
Write-Host ""

Write-Host "=== AFTER MANUAL CONFIGURATION ===" -ForegroundColor Yellow
Write-Host ""
$restart = Read-Host "Once you've run the SQL script manually, do you want to restart the Container App to apply changes? (y/N)"
if ($restart -eq "y" -or $restart -eq "Y") {
    Write-Host "Restarting Container App..." -ForegroundColor Yellow
    az containerapp revision restart --name $ContainerAppName --resource-group $ResourceGroupName
    Write-Host "? Container App restart initiated" -ForegroundColor Green
    Write-Host ""
    Write-Host "Monitor the application logs:" -ForegroundColor Yellow
    Write-Host "az containerapp logs show --name $ContainerAppName --resource-group $ResourceGroupName --follow" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or view logs in Azure Portal:" -ForegroundColor Yellow
    Write-Host "Azure Portal > Container Apps > $ContainerAppName > Monitoring > Log stream" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "??  Remember to restart your Container App after running the SQL script manually!" -ForegroundColor Yellow
    Write-Host "Command: az containerapp revision restart --name $ContainerAppName --resource-group $ResourceGroupName" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=== TROUBLESHOOTING ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "If you still get managed identity errors after configuration:" -ForegroundColor White
Write-Host "1. Verify the managed identity exists: az containerapp identity show --name $ContainerAppName --resource-group $ResourceGroupName" -ForegroundColor Gray
Write-Host "2. Check if the SQL user was created: SELECT name, type_desc FROM sys.database_principals WHERE name = 'ca-c5nyxvpm7xvwu'" -ForegroundColor Gray
Write-Host "3. Verify your connection string uses: Authentication=Active Directory Default" -ForegroundColor Gray
Write-Host "4. Check Container App logs for the correlation ID from the error message" -ForegroundColor Gray